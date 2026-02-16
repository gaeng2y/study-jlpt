-- Harden import_jlpt_vocab + user_srs reliability for study queue.
-- Goal: prevent empty study cards caused by schema drift, orphan SRS rows, or RLS mismatch.

create extension if not exists pgcrypto;

create table if not exists public.daily_stats (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  cards_done int not null default 0,
  minutes_done int not null default 0,
  reviews_done int not null default 0,
  new_done int not null default 0,
  is_completed boolean not null default false,
  freeze_used boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, day)
);

create or replace function public._apply_profile_streak(
  p_user_id uuid,
  p_day date
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prev_completed boolean := false;
  v_new_streak int := 1;
begin
  select ds.is_completed
    into v_prev_completed
  from public.daily_stats ds
  where ds.user_id = p_user_id
    and ds.day = p_day - interval '1 day';

  if coalesce(v_prev_completed, false) then
    select coalesce(p.current_streak, 0) + 1
      into v_new_streak
    from public.profiles p
    where p.id = p_user_id;
  end if;

  update public.profiles
  set current_streak = v_new_streak,
      longest_streak = greatest(coalesce(longest_streak, 0), v_new_streak)
  where id = p_user_id;
end;
$$;

grant execute on function public._apply_profile_streak(uuid, date) to authenticated;

-- 1) Normalize import table columns used by app.
alter table if exists public.import_jlpt_vocab
  add column if not exists id uuid,
  add column if not exists kind text,
  add column if not exists is_active boolean,
  add column if not exists imported_at timestamptz;

update public.import_jlpt_vocab
set id = gen_random_uuid()
where id is null;

alter table if exists public.import_jlpt_vocab
  alter column id set default gen_random_uuid();

alter table if exists public.import_jlpt_vocab
  alter column id set not null;

update public.import_jlpt_vocab
set kind = 'vocab'
where kind is null or btrim(kind) = '';

alter table if exists public.import_jlpt_vocab
  alter column kind set default 'vocab';

alter table if exists public.import_jlpt_vocab
  alter column kind set not null;

update public.import_jlpt_vocab
set is_active = true
where is_active is null;

alter table if exists public.import_jlpt_vocab
  alter column is_active set default true;

alter table if exists public.import_jlpt_vocab
  alter column is_active set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.import_jlpt_vocab'::regclass
      and contype = 'p'
  ) then
    alter table public.import_jlpt_vocab
      add constraint import_jlpt_vocab_pkey primary key (id);
  end if;
end $$;

create index if not exists idx_import_vocab_active_level
  on public.import_jlpt_vocab(is_active, jlpt_level);

create index if not exists idx_import_vocab_imported_at
  on public.import_jlpt_vocab(imported_at desc nulls last);

create index if not exists idx_import_vocab_jp_reading
  on public.import_jlpt_vocab(jp, reading);

-- 2) Ensure user_srs references import_jlpt_vocab and has strong lookup indexes.
alter table if exists public.user_srs
  drop constraint if exists user_srs_content_id_fkey;

alter table if exists public.user_srs
  add constraint user_srs_content_id_fkey
  foreign key (content_id) references public.import_jlpt_vocab(id) on delete cascade;

create index if not exists idx_user_srs_user_due
  on public.user_srs(user_id, due_at);

create index if not exists idx_user_srs_user_content
  on public.user_srs(user_id, content_id);

-- 3) Remove orphan SRS rows that point to non-existing vocab IDs.
delete from public.user_srs us
where not exists (
  select 1 from public.import_jlpt_vocab iv where iv.id = us.content_id
);

-- 4) RLS policies (content: read-only for app; user_srs: owner-only).
alter table if exists public.import_jlpt_vocab enable row level security;
alter table if exists public.user_srs enable row level security;

drop policy if exists "import_vocab_read_all_public" on public.import_jlpt_vocab;
create policy "import_vocab_read_all_public"
on public.import_jlpt_vocab
for select to public
using (is_active = true);

drop policy if exists "user_srs_owner_select" on public.user_srs;
create policy "user_srs_owner_select"
on public.user_srs
for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "user_srs_owner_insert" on public.user_srs;
create policy "user_srs_owner_insert"
on public.user_srs
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "user_srs_owner_update" on public.user_srs;
create policy "user_srs_owner_update"
on public.user_srs
for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "user_srs_owner_delete" on public.user_srs;
create policy "user_srs_owner_delete"
on public.user_srs
for delete to authenticated
using (auth.uid() = user_id);

-- 5) Harden core RPCs so first login always has profile defaults.
create or replace function public.get_today_summary()
returns table(
  due_count int,
  new_count int,
  est_minutes int,
  streak int,
  freeze_left int,
  cards_done int,
  is_completed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := timezone('Asia/Seoul', now())::date;
  v_due int := 0;
  v_cards_done int := 0;
  v_completed boolean := false;
  v_streak int := 0;
  v_freeze int := 0;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (id)
  values (v_user_id)
  on conflict (id) do nothing;

  insert into public.daily_stats (user_id, day)
  values (v_user_id, v_today)
  on conflict (user_id, day) do nothing;

  select count(*)::int
    into v_due
  from public.user_srs us
  where us.user_id = v_user_id
    and us.due_at <= now();

  select ds.cards_done, ds.is_completed
    into v_cards_done, v_completed
  from public.daily_stats ds
  where ds.user_id = v_user_id
    and ds.day = v_today;

  select coalesce(p.current_streak, 0), coalesce(p.freeze_left, 0)
    into v_streak, v_freeze
  from public.profiles p
  where p.id = v_user_id;

  return query
  select
    v_due,
    5,
    greatest(1, ceil(v_due / 4.0)::int),
    v_streak,
    v_freeze,
    coalesce(v_cards_done, 0),
    coalesce(v_completed, false);
end;
$$;

grant execute on function public.get_today_summary() to authenticated;

create or replace function public.mark_today_complete()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := timezone('Asia/Seoul', now())::date;
  v_daily_min int := 3;
  v_prev_completed boolean := false;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (id)
  values (v_user_id)
  on conflict (id) do nothing;

  select coalesce(p.daily_min_cards, 3)
    into v_daily_min
  from public.profiles p
  where p.id = v_user_id;

  if v_daily_min is null then
    v_daily_min := 3;
  end if;

  select coalesce(ds.is_completed, false)
    into v_prev_completed
  from public.daily_stats ds
  where ds.user_id = v_user_id
    and ds.day = v_today;

  insert into public.daily_stats (user_id, day, cards_done, is_completed)
  values (v_user_id, v_today, v_daily_min, true)
  on conflict (user_id, day)
  do update set
    cards_done = greatest(public.daily_stats.cards_done, v_daily_min),
    is_completed = true;

  if not coalesce(v_prev_completed, false) then
    perform public._apply_profile_streak(v_user_id, v_today);
  end if;
end;
$$;

grant execute on function public.mark_today_complete() to authenticated;

create or replace function public.grade_card(
  p_content_id uuid,
  p_good boolean,
  p_studied_minutes int default 1
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := timezone('Asia/Seoul', now())::date;
  v_interval int := 1;
  v_reps int := 0;
  v_lapses int := 0;
  v_daily_min int := 3;
  v_before_completed boolean := false;
  v_after_cards_done int := 0;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.import_jlpt_vocab iv
    where iv.id = p_content_id
      and iv.is_active = true
  ) then
    raise exception 'Invalid content_id: %', p_content_id;
  end if;

  insert into public.profiles (id)
  values (v_user_id)
  on conflict (id) do nothing;

  select coalesce(p.daily_min_cards, 3)
    into v_daily_min
  from public.profiles p
  where p.id = v_user_id;

  if v_daily_min is null then
    v_daily_min := 3;
  end if;

  select us.interval_days, us.reps, us.lapses
    into v_interval, v_reps, v_lapses
  from public.user_srs us
  where us.user_id = v_user_id
    and us.content_id = p_content_id
  for update;

  if found then
    if p_good then
      v_interval := greatest(2, round(v_interval * 2.0)::int);
      v_reps := v_reps + 1;
    else
      v_interval := 1;
      v_lapses := v_lapses + 1;
    end if;

    update public.user_srs
    set due_at = now() + make_interval(days => v_interval),
        interval_days = v_interval,
        reps = v_reps,
        lapses = v_lapses,
        updated_at = now()
    where user_id = v_user_id
      and content_id = p_content_id;
  else
    v_interval := case when p_good then 2 else 1 end;
    v_reps := case when p_good then 1 else 0 end;
    v_lapses := case when p_good then 0 else 1 end;

    insert into public.user_srs (
      user_id,
      content_id,
      due_at,
      interval_days,
      ease,
      reps,
      lapses,
      last_grade,
      updated_at
    )
    values (
      v_user_id,
      p_content_id,
      now() + make_interval(days => v_interval),
      v_interval,
      2.5,
      v_reps,
      v_lapses,
      case when p_good then 1 else 0 end,
      now()
    )
    on conflict (user_id, content_id)
    do update set
      due_at = excluded.due_at,
      interval_days = excluded.interval_days,
      reps = excluded.reps,
      lapses = excluded.lapses,
      last_grade = excluded.last_grade,
      updated_at = now();
  end if;

  insert into public.daily_stats (user_id, day, cards_done, minutes_done, reviews_done, is_completed)
  values (v_user_id, v_today, 1, greatest(1, coalesce(p_studied_minutes, 1)), 1, false)
  on conflict (user_id, day)
  do update set
    cards_done = public.daily_stats.cards_done + 1,
    minutes_done = public.daily_stats.minutes_done + greatest(1, coalesce(p_studied_minutes, 1)),
    reviews_done = public.daily_stats.reviews_done + 1;

  select ds.is_completed
    into v_before_completed
  from public.daily_stats ds
  where ds.user_id = v_user_id
    and ds.day = v_today;

  update public.daily_stats ds
  set is_completed = (ds.cards_done >= v_daily_min)
  where ds.user_id = v_user_id
    and ds.day = v_today
  returning ds.cards_done into v_after_cards_done;

  if v_after_cards_done >= v_daily_min and not coalesce(v_before_completed, false) then
    perform public._apply_profile_streak(v_user_id, v_today);
  end if;
end;
$$;

grant execute on function public.grade_card(uuid, boolean, int) to authenticated;

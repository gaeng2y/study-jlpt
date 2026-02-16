-- Server-side aggregation/sync hardening for MVP.
-- Adds resilient daily summary RPC and completion sync RPC.

create extension if not exists pgcrypto;

-- 1) Ensure profile/stat columns exist.
alter table if exists public.profiles
  add column if not exists current_streak int not null default 0,
  add column if not exists longest_streak int not null default 0,
  add column if not exists freeze_left int not null default 1,
  add column if not exists weekly_goal_reviews int not null default 60,
  add column if not exists daily_min_cards int not null default 3,
  add column if not exists reminder_time text not null default '21:00';

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

create index if not exists idx_user_srs_due_user on public.user_srs(user_id, due_at);
create index if not exists idx_daily_stats_user_day on public.daily_stats(user_id, day desc);

alter table public.daily_stats enable row level security;

drop policy if exists "daily_stats_owner_select" on public.daily_stats;
create policy "daily_stats_owner_select"
on public.daily_stats
for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "daily_stats_owner_insert" on public.daily_stats;
create policy "daily_stats_owner_insert"
on public.daily_stats
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "daily_stats_owner_update" on public.daily_stats;
create policy "daily_stats_owner_update"
on public.daily_stats
for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

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
  select is_completed
    into v_prev_completed
  from public.daily_stats
  where user_id = p_user_id
    and day = p_day - interval '1 day';

  if coalesce(v_prev_completed, false) then
    select coalesce(current_streak, 0) + 1
      into v_new_streak
    from public.profiles
    where id = p_user_id;
  end if;

  update public.profiles
  set current_streak = v_new_streak,
      longest_streak = greatest(coalesce(longest_streak, 0), v_new_streak)
  where id = p_user_id;
end;
$$;

grant execute on function public._apply_profile_streak(uuid, date) to authenticated;

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

  insert into public.daily_stats (user_id, day)
  values (v_user_id, v_today)
  on conflict (user_id, day) do nothing;

  select count(*)::int
    into v_due
  from public.user_srs
  where user_id = v_user_id
    and due_at <= now();

  select cards_done, is_completed
    into v_cards_done, v_completed
  from public.daily_stats
  where user_id = v_user_id
    and day = v_today;

  select coalesce(current_streak, 0), coalesce(freeze_left, 0)
    into v_streak, v_freeze
  from public.profiles
  where id = v_user_id;

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

  select coalesce(daily_min_cards, 3)
    into v_daily_min
  from public.profiles
  where id = v_user_id;

  select coalesce(is_completed, false)
    into v_prev_completed
  from public.daily_stats
  where user_id = v_user_id
    and day = v_today;

  insert into public.daily_stats (user_id, day, cards_done, is_completed)
  values (v_user_id, v_today, v_daily_min, true)
  on conflict (user_id, day)
  do update set
    cards_done = greatest(public.daily_stats.cards_done, v_daily_min),
    is_completed = true;

  if not v_prev_completed then
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

  select coalesce(daily_min_cards, 3)
    into v_daily_min
  from public.profiles
  where id = v_user_id;

  select interval_days, reps, lapses
    into v_interval, v_reps, v_lapses
  from public.user_srs
  where user_id = v_user_id
    and content_id = p_content_id
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

  select is_completed
    into v_before_completed
  from public.daily_stats
  where user_id = v_user_id
    and day = v_today;

  update public.daily_stats
  set is_completed = (cards_done >= v_daily_min)
  where user_id = v_user_id
    and day = v_today
  returning cards_done into v_after_cards_done;

  if v_after_cards_done >= v_daily_min and not coalesce(v_before_completed, false) then
    perform public._apply_profile_streak(v_user_id, v_today);
  end if;
end;
$$;

grant execute on function public.grade_card(uuid, boolean, int) to authenticated;

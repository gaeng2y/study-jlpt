-- Fix ambiguous cards_done reference in get_today_summary()

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

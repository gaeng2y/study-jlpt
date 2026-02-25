-- Add RPC for manual freeze usage on Today screen.
create or replace function public.use_today_freeze()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := timezone('Asia/Seoul', now())::date;
  v_cards_done int := 0;
  v_completed boolean := false;
  v_consumed boolean := false;
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

  select coalesce(ds.cards_done, 0), coalesce(ds.is_completed, false)
    into v_cards_done, v_completed
  from public.daily_stats ds
  where ds.user_id = v_user_id
    and ds.day = v_today;

  -- Freeze can only be used before starting today's study.
  if v_completed or v_cards_done > 0 then
    return false;
  end if;

  update public.profiles p
  set freeze_left = greatest(coalesce(p.freeze_left, 0) - 1, 0)
  where p.id = v_user_id
    and coalesce(p.freeze_left, 0) > 0
  returning true into v_consumed;

  if not coalesce(v_consumed, false) then
    return false;
  end if;

  update public.daily_stats ds
  set is_completed = true,
      freeze_used = true
  where ds.user_id = v_user_id
    and ds.day = v_today;

  return true;
end;
$$;

grant execute on function public.use_today_freeze() to authenticated;

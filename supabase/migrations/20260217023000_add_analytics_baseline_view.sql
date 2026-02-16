-- Fixed baseline windows for dashboard trend tracking (7d / 30d).

create or replace view public.analytics_kpi_baseline as
with windows as (
  select 7::int as window_days
  union all
  select 30::int as window_days
),
plan_started as (
  select
    w.window_days,
    count(*)::bigint as plan_started_events
  from windows w
  left join public.analytics_events e
    on e.event_name = 'daily_plan_started'
   and e.created_at >= now() - make_interval(days => w.window_days)
  group by w.window_days
),
session_counts as (
  select
    w.window_days,
    count(*) filter (
      where e.event_name = 'study_session_started'
        and coalesce(e.properties->>'session_id', '') <> ''
    )::bigint as started_sessions,
    count(*) filter (
      where e.event_name = 'study_session_finished'
        and coalesce(e.properties->>'session_id', '') <> ''
    )::bigint as finished_sessions
  from windows w
  left join public.analytics_events e
    on e.created_at >= now() - make_interval(days => w.window_days)
   and e.event_name in ('study_session_started', 'study_session_finished')
  group by w.window_days
),
search_users as (
  select distinct
    w.window_days,
    e.user_id
  from windows w
  join public.analytics_events e
    on e.event_name = 'content_search'
   and e.created_at >= now() - make_interval(days => w.window_days)
),
open_users as (
  select distinct
    w.window_days,
    e.user_id
  from windows w
  join public.analytics_events e
    on e.event_name = 'content_opened'
   and e.created_at >= now() - make_interval(days => w.window_days)
),
search_open as (
  select
    w.window_days,
    count(distinct s.user_id)::bigint as searched_users,
    count(distinct o.user_id)::bigint as opened_users_from_search
  from windows w
  left join search_users s
    on s.window_days = w.window_days
  left join open_users o
    on o.window_days = w.window_days
   and o.user_id is not distinct from s.user_id
  group by w.window_days
)
select
  w.window_days,
  p.plan_started_events,
  sc.started_sessions,
  sc.finished_sessions,
  case
    when sc.started_sessions = 0 then 0::numeric
    else round((sc.finished_sessions::numeric / sc.started_sessions::numeric) * 100, 2)
  end as study_completion_rate_pct,
  so.searched_users,
  so.opened_users_from_search,
  case
    when so.searched_users = 0 then 0::numeric
    else round((so.opened_users_from_search::numeric / so.searched_users::numeric) * 100, 2)
  end as search_to_open_rate_pct
from windows w
left join plan_started p on p.window_days = w.window_days
left join session_counts sc on sc.window_days = w.window_days
left join search_open so on so.window_days = w.window_days
order by w.window_days;

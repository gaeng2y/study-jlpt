-- KPI views for product decision-making dashboards (rolling 7 days).

create or replace view public.analytics_plan_selection_7d as
with base as (
  select coalesce(properties->>'mode', 'unknown') as mode
  from public.analytics_events
  where event_name = 'daily_plan_started'
    and created_at >= now() - interval '7 days'
),
agg as (
  select mode, count(*)::bigint as event_count
  from base
  group by mode
),
tot as (
  select count(*)::bigint as total_count
  from base
)
select
  agg.mode,
  agg.event_count,
  case
    when tot.total_count = 0 then 0::numeric
    else round((agg.event_count::numeric / tot.total_count::numeric) * 100, 2)
  end as selection_rate_pct
from agg
cross join tot
order by agg.event_count desc;

create or replace view public.analytics_study_completion_7d as
with started as (
  select
    user_id,
    properties->>'session_id' as session_id
  from public.analytics_events
  where event_name = 'study_session_started'
    and created_at >= now() - interval '7 days'
    and coalesce(properties->>'session_id', '') <> ''
),
finished as (
  select
    user_id,
    properties->>'session_id' as session_id
  from public.analytics_events
  where event_name = 'study_session_finished'
    and created_at >= now() - interval '7 days'
    and coalesce(properties->>'session_id', '') <> ''
),
started_unique as (
  select distinct user_id, session_id
  from started
),
finished_unique as (
  select distinct user_id, session_id
  from finished
),
joined as (
  select
    s.user_id,
    s.session_id,
    case when f.session_id is null then false else true end as is_finished
  from started_unique s
  left join finished_unique f
    on s.user_id is not distinct from f.user_id
   and s.session_id = f.session_id
),
agg as (
  select
    count(*)::bigint as started_sessions,
    count(*) filter (where is_finished)::bigint as finished_sessions
  from joined
)
select
  started_sessions,
  finished_sessions,
  case
    when started_sessions = 0 then 0::numeric
    else round((finished_sessions::numeric / started_sessions::numeric) * 100, 2)
  end as completion_rate_pct
from agg;

create or replace view public.analytics_search_to_open_7d as
with searched as (
  select distinct user_id
  from public.analytics_events
  where event_name = 'content_search'
    and created_at >= now() - interval '7 days'
),
opened as (
  select distinct user_id
  from public.analytics_events
  where event_name = 'content_opened'
    and created_at >= now() - interval '7 days'
),
agg as (
  select
    (select count(*)::bigint from searched) as searched_users,
    (
      select count(*)::bigint
      from opened o
      inner join searched s
        on o.user_id is not distinct from s.user_id
    ) as opened_users_from_search
)
select
  searched_users,
  opened_users_from_search,
  case
    when searched_users = 0 then 0::numeric
    else round((opened_users_from_search::numeric / searched_users::numeric) * 100, 2)
  end as search_to_open_rate_pct
from agg;

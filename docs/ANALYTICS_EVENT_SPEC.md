# Analytics Event Spec (Supabase)

이 문서는 의사결정용 앱 이벤트를 `public.analytics_events`에 저장하기 위한 표준 정의입니다.

## 저장 대상
- Table: `public.analytics_events`
- Columns:
  - `user_id` (uuid, nullable)
  - `event_name` (text)
  - `properties` (jsonb)
  - `created_at` (timestamptz)

## 공통 규칙
- `event_name`: `snake_case`
- `properties`: 값이 없더라도 객체로 저장
- `properties.event_version`: 정수, 현재 `1` (클라이언트에서 자동 주입)
- 개인식별정보(이메일/실명) 미저장
- 검색어 원문은 저장하지 않고 길이(`query_length`)만 저장

## 이벤트 정의

1. `app_initialized`
- Trigger: 앱 초기화 완료
- Properties:
  - `source` (`Supabase` | `Mock`)
  - `items` (int)

2. `login_success`
- Trigger: OAuth 로그인 성공(`AuthChangeEvent.signedIn`)
- Properties:
  - `provider` (string)

3. `logout`
- Trigger: 로그아웃 버튼 실행
- Properties:
  - `source` (`profile`)

4. `onboarding_completed`
- Trigger: 온보딩 저장 완료
- Properties:
  - `target_level` (string)
  - `weekly_goal_reviews` (int)
  - `daily_min_cards` (int)

5. `settings_updated`
- Trigger: 학습 설정 저장 완료
- Properties:
  - `target_level_before`, `target_level_after` (string)
  - `weekly_goal_before`, `weekly_goal_after` (int)
  - `daily_min_before`, `daily_min_after` (int)
  - `reminder_before`, `reminder_after` (string `HH:mm`)
  - `onboarding_completed` (bool)

6. `tab_opened`
- Trigger: 하단 탭 이동
- Properties:
  - `tab` (`today` | `practice` | `study` | `content` | `profile` | `unknown`)
  - `index` (int)

7. `daily_plan_started`
- Trigger: 오늘 플랜 버튼 탭
- Properties:
  - `mode` (`min3` | `min10` | `min20`)

8. `study_session_started`
- Trigger: 학습 큐 로드 완료
- Properties:
  - `mode` (`min3` | `min10` | `min20`)
  - `queue_length` (int)
  - `session_id` (string)

9. `card_answered`
- Trigger: 카드 채점(again/good)
- Properties:
  - `kind` (string)
  - `grade` (`again` | `good`)
  - `duration_ms` (int, 현재 0 고정)

10. `study_session_finished`
- Trigger: 세션 완료 화면에서 완료 버튼 탭
- Properties:
  - `mode` (`min3` | `min10` | `min20`)
  - `queue_length` (int)
  - `good_count` (int)
  - `again_count` (int)
  - `elapsed_seconds` (int)
  - `session_id` (string)

11. `study_session_abandoned`
- Trigger: 세션 도중 화면 이탈(dispose)
- Properties:
  - `mode` (`min3` | `min10` | `min20`)
  - `queue_length` (int)
  - `answered_count` (int)
  - `elapsed_seconds` (int)
  - `session_id` (string)

12. `study_completed`
- Trigger: 세션 완료 처리 완료
- Properties:
  - `cards` (int)
  - `minutes` (int)
  - `due_count` (int)
  - `new_count` (int)
  - `streak` (int)

13. `content_search`
- Trigger: 콘텐츠 검색/레벨 필터 적용
- Properties:
  - `query_length` (int)
  - `jlpt_level` (string, `all` 포함)
  - `result_count` (int)

14. `content_opened`
- Trigger: 콘텐츠 상세 진입
- Properties:
  - `content_id` (string)
  - `kind` (string)
  - `jlpt_level` (string)

15. `widget_opened`
- Trigger: 위젯 딥링크 진입
- Properties:
  - `type` (`review` | `daily_word`)

## SQL 조회 예시
```sql
-- 최근 7일 플랜 선택 비율
select
  properties->>'mode' as mode,
  count(*) as cnt
from public.analytics_events
where event_name = 'daily_plan_started'
  and created_at >= now() - interval '7 days'
group by 1
order by cnt desc;
```

```sql
-- 최근 7일 검색 후 상세 진입률(대략)
with search_users as (
  select distinct user_id
  from public.analytics_events
  where event_name = 'content_search'
    and created_at >= now() - interval '7 days'
),
open_users as (
  select distinct user_id
  from public.analytics_events
  where event_name = 'content_opened'
    and created_at >= now() - interval '7 days'
)
select
  (select count(*) from open_users)::float
  / nullif((select count(*) from search_users), 0) as search_to_open_rate;
```

## 대시보드 기준선
- 기간은 `최근 7일`, `최근 30일`로 고정
- 뷰: `public.analytics_kpi_baseline`
- 권장 KPI:
  - `plan_started_events`
  - `study_completion_rate_pct`
  - `search_to_open_rate_pct`

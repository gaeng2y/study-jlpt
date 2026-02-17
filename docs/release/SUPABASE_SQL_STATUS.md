# Supabase SQL Status

기준일: 2026-02-17

## 1) Migrations (이력 보존, 삭제 금지)
아래 파일은 모두 `supabase/migrations/`에 있고, 적용 대상입니다.

1. `20260215170000_add_onboarding_completed.sql`
2. `20260215234500_use_import_vocab_directly.sql`
3. `20260216162000_server_aggregation_sync.sql`
4. `20260216173000_fix_today_summary_ambiguous_cards_done.sql`
5. `20260216191000_harden_import_vocab_srs.sql`
6. `20260216202000_add_release_telemetry_tables.sql`
7. `20260217022000_add_analytics_kpi_views.sql`
8. `20260217023000_add_analytics_baseline_view.sql`

## 2) Non-migration SQL
- Seed:
  - `supabase/seed/seed.sql`
- Test/verification:
  - `supabase/tests/rls_check.sql`

## 3) 운영 기준
- 신규 스키마 변경은 항상 `supabase/migrations/<timestamp>_<name>.sql`로 추가
- 이미 적용된 migration 파일은 수정/삭제하지 않음
- 배포 전 SQL 적용 기준은 `docs/release/TESTFLIGHT_INTERNAL_RELEASE.md`를 따름

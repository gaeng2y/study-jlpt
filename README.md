# Study JLPT (일어톡톡)

JLPT 학습 앱 `일어톡톡`의 모노레포입니다.

- App: Flutter (`apps/mobile`)
- Backend: Supabase (`supabase`)
- Focus: OAuth 로그인, 학습 세션(SRS), 위젯, 운영 텔레메트리

## Repository Layout

```text
apps/mobile/     Flutter 앱(iOS/Android)
supabase/        migrations / seed / tests
scripts/         데이터 변환 스크립트
data/            원본/중간 데이터 파일
docs/            운영/배포/분석 문서
```

## Quick Start

### 1) App run (local)

```bash
cd apps/mobile
flutter pub get
flutter run
```

### 2) iOS release build

```bash
cd apps/mobile
flutter build ipa --release
```

## Supabase SQL

SQL 마이그레이션/상태는 아래 문서 기준으로 관리합니다.

- `docs/release/SUPABASE_SQL_STATUS.md`
- `docs/release/TESTFLIGHT_INTERNAL_RELEASE.md`

원칙:
- 적용된 migration 파일은 수정/삭제하지 않음
- 신규 변경은 `supabase/migrations/<timestamp>_<name>.sql` 추가

## Analytics / Telemetry

- 이벤트 스펙: `docs/ANALYTICS_EVENT_SPEC.md`
- KPI 기준선(7d/30d): `public.analytics_kpi_baseline`

## Release Docs

- 배포 런북: `docs/release/TESTFLIGHT_INTERNAL_RELEASE.md`
- QA 체크리스트: `docs/release/QA_CHECKLIST.md`

## Notes

- iOS Bundle ID: `co.gaeng2y.studyjlpt`
- OAuth scheme: `studyjlpt://login-callback/`
- Widget App Group: `group.co.gaeng2y.studyjlpt`

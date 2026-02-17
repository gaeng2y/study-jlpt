# Implementation Status

## 완료
- Flutter 앱 기본 구조 생성 (`apps/mobile/lib`)
- 모듈 분리(Theme, Models, Data Repositories, UseCases, Features)
- MVP UI/UX 플로우 구현
  - Today
  - Study Session
  - Content List/Detail
  - Profile
- Mock Repository 기반 상태 흐름 구현
- Supabase 초기화 부트스트랩(`SUPABASE_URL`, `SUPABASE_ANON_KEY`)
- Widget 캐시 서비스 스텁(`home_widget`)
- Supabase 마이그레이션/정책/함수 작성

## 아직 필요
- Flutter SDK가 없는 환경이라 실제 `flutter run` 검증은 미수행
- iOS/Android 플랫폼 폴더는 `flutter create .` 실행 필요
- 실제 Supabase repository 구현(`from()/rpc()` 연결) 필요
- iOS WidgetKit/App Group, Android AppWidget 네이티브 연결 필요

## 참고 파일
- 앱 엔트리: `apps/mobile/lib/main.dart`
- 앱 셸: `apps/mobile/lib/app.dart`
- 앱 상태: `apps/mobile/lib/shared/app_state.dart`
- 마이그레이션: `supabase/migrations/20260215103000_init.sql`

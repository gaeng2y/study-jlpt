# TestFlight / Internal Release Runbook

## Prerequisites
- Apple Developer / App Store Connect 권한
- Xcode 최신 버전
- 번들 ID/서명 설정 완료
- Supabase Production 설정 반영

## 1) Supabase 마이그레이션 적용
순서대로 SQL Editor에서 실행:
1. `supabase/migrations/20260216191000_harden_import_vocab_srs.sql`
2. `supabase/migrations/20260216202000_add_release_telemetry_tables.sql`

## 2) Flutter 준비
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

## 3) iOS Archive 업로드
```bash
cd apps/mobile
flutter build ipa --release
```
- Xcode Organizer에서 Archive 확인
- App Store Connect로 업로드

## 4) TestFlight 배포
- Internal Testing 그룹 선택
- 릴리즈 노트 작성
- 빌드 상태 "Ready to Test" 확인

## 5) Android Internal Testing
```bash
cd apps/mobile
flutter build appbundle --release
```
- Google Play Console > Internal testing 트랙 업로드
- 테스터 그룹 배포

## 6) 출시 후 모니터링
- Supabase `analytics_events` 최근 이벤트 확인
- Supabase `client_error_logs` 오류 이벤트 확인
- 로그인 성공률 / 세션 완료율 / crash-free 체크

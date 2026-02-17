# Next Steps (User Required)

현재 환경에는 Flutter/Xcode/Android SDK가 없어 아래 단계는 사용자 로컬에서 실행이 필요합니다.

## 1) Flutter/SDK 준비
```bash
flutter doctor
```

## 2) 플랫폼 폴더 생성
```bash
cd apps/mobile
flutter create .
```

## 3) 최소 지원 버전 설정

### iOS (18.0+)
- `ios/Podfile`: `platform :ios, '18.0'`
- Xcode project deployment target: 18.0

### Android (15 / API 35+)
- `android/app/build.gradle` 또는 `build.gradle.kts`
  - `minSdk = 35`
  - `targetSdk = 35`
  - `compileSdk = 35`

## 4) 앱 실행
```bash
flutter pub get
flutter run
```

## 5) Supabase 연결
- Supabase 프로젝트 생성
- Auth에서 Anonymous Sign-in 활성화(권장, 개발 편의)
- SQL 실행
  - `supabase/migrations/20260215103000_init.sql`
  - `supabase/migrations/20260215170000_add_onboarding_completed.sql`
  - `supabase/seed/seed.sql`
- 앱 실행 시 define 추가

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 6) 위젯 네이티브 연결
- iOS Widget Extension + App Group 생성
- Android AppWidget Provider 생성
- 위젯 이름을 `widget_cache_service.dart` 값과 일치시켜야 함

## 7) RLS 검증 실행
- 파일: `supabase/tests/rls_check.sql`
- Supabase SQL Editor에서 실행
- 확인 포인트:
  - User A 컨텍스트에서 A 데이터만 조회되는지
  - User B 컨텍스트에서 B 데이터만 조회되는지
  - `content_items`는 공개 읽기 가능한지

주의:
- 스크립트에는 테스트용 `auth.users` 레코드 생성이 포함됨
- 필요 시 파일 하단 cleanup SQL로 정리

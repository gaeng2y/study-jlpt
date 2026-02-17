# Mobile App (Flutter)

`apps/mobile`은 Study JLPT 클라이언트 앱입니다.

## Run

```bash
flutter pub get
flutter run
```

## Quality Checks

```bash
flutter analyze
flutter test
```

## Build

### iOS

```bash
flutter build ipa --release
```

### Android

```bash
flutter build appbundle --release
```

## Main Entry Points

- App entry: `lib/main.dart`
- App shell/router: `lib/app.dart`
- Global state: `lib/shared/app_state.dart`
- Theme: `lib/core/theme/app_theme.dart`

## Feature Modules

- `lib/features/auth`
- `lib/features/onboarding`
- `lib/features/today`
- `lib/features/study`
- `lib/features/content`
- `lib/features/profile`

## Telemetry

이벤트 스펙은 루트 문서 `docs/ANALYTICS_EVENT_SPEC.md`를 따릅니다.

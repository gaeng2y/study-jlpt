# Platform Design Mapping

## iOS (HIG / Liquid Glass 방향)
적용 원칙:
- 계층감 있는 반투명 표면(글래스)
- 콘텐츠 우선, 크롬 최소화
- 명확한 탭/세그먼트 중심 조작

적용 위치:
- 글래스 공통 컴포넌트: `apps/mobile/lib/shared/widgets/glass_surface.dart`
- iOS 분기 테마: `apps/mobile/lib/core/theme/app_theme.dart`
- 하단 네비게이션 글래스 래핑: `apps/mobile/lib/app.dart`
- Today/Study/Content/Profile/Onboarding 패널에서 글래스 적용

## Android (Material 3 방향)
적용 원칙:
- Material 3 컴포넌트 일관성
- 명확한 구조와 상태 전달
- 색/형태/고도 기반 계층 표현

적용 위치:
- Material 3 테마/ColorScheme: `apps/mobile/lib/core/theme/app_theme.dart`
- NavigationBar, FilledButton, Card, SegmentedButton 중심 UI 유지
- 플랫폼 분기 시 Android는 Material 스타일 기본 경로 유지

## 참고 링크
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
- Apple Liquid Glass Overview: https://developer.apple.com/documentation/technologyoverviews/liquid-glass
- Android Design Systems (Compose): https://developer.android.com/develop/ui/compose/designsystems?hl=ko
- Material 3: https://m3.material.io/

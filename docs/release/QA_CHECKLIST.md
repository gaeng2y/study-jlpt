# QA Checklist (MVP Release)

## 1) Auth / Session
- [ ] Google 로그인 성공 후 홈 진입
- [ ] Apple 로그인 성공 후 홈 진입
- [ ] 로그아웃 후 인증 화면 복귀
- [ ] OAuth 실패 시 앱 크래시 없이 오류 메시지 표시

## 2) Data / Sync
- [ ] 학습 카드가 빈 화면 없이 로드됨
- [ ] 카드 평가(Again/Good) 후 dueCount 즉시 반영
- [ ] 앱 재시작 후 학습 진도 복원
- [ ] RLS 정책으로 타 유저 데이터 접근 불가

## 3) Today / Summary
- [ ] 오늘 진행(cardsDone/minCards) 서버 값과 일치
- [ ] streak/freeze 값 서버 값과 일치
- [ ] 최소 완료/10분/20분 진입 정상

## 4) Study UX
- [ ] 네이티브 카드 임베드 렌더링(iOS/Android)
- [ ] 스와이프 Again/Good 동작
- [ ] 세션 완료 화면에 Good/Again/시간 노출
- [ ] 듣기(TTS) 버튼 동작

## 5) Widget / Deep Link
- [ ] 위젯 탭 시 앱 해당 탭으로 이동
- [ ] review/content 딥링크 정상
- [ ] widget_opened 이벤트 기록 확인

## 6) Profile / Onboarding
- [ ] 온보딩 1회만 노출
- [ ] 프로필 설정 수정 후 오늘 화면 즉시 반영
- [ ] 알림 시간 수정 후 로컬 알림 재스케줄

## 7) Stability
- [ ] iOS 상태바 다크 아이콘 유지
- [ ] 다크모드 강제 라이트 동작 확인
- [ ] 치명 오류 발생 시 client_error_logs 적재 확인

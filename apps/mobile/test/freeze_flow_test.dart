import 'package:flutter_test/flutter_test.dart';
import 'package:ileotoktok_mobile/data/mock/mock_repositories.dart';
import 'package:ileotoktok_mobile/shared/app_state.dart';

void main() {
  group('freeze flow', () {
    test('useTodayFreeze succeeds before study start and consumes freeze',
        () async {
      final repo = MockStudyRepository();

      final applied = await repo.useTodayFreeze();
      final summary = await repo.todaySummary();

      expect(applied, isTrue);
      expect(summary.isCompleted, isTrue);
      expect(summary.cardsDone, 0);
      expect(summary.freezeLeft, 0);
      expect(await repo.useTodayFreeze(), isFalse);
    });

    test('useTodayFreeze fails after study has started', () async {
      final repo = MockStudyRepository();
      final queue = await repo.dueQueue(limit: 1);

      await repo.gradeCard(card: queue.first, good: true);

      final applied = await repo.useTodayFreeze();
      final summary = await repo.todaySummary();

      expect(applied, isFalse);
      expect(summary.cardsDone, 1);
      expect(summary.isCompleted, isFalse);
      expect(summary.freezeLeft, 1);
    });

    test('AppState.useTodayFreeze refreshes summary state', () async {
      final state = AppState(
        contentRepository: MockContentRepository(),
        studyRepository: MockStudyRepository(),
        profileRepository: MockProfileRepository(),
      );

      final applied = await state.useTodayFreeze();

      expect(applied, isTrue);
      expect(state.summary.isCompleted, isTrue);
      expect(state.summary.cardsDone, 0);
      expect(state.summary.freezeLeft, 0);
    });
  });
}

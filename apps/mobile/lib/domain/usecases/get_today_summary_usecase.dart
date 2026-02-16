import '../../core/models/today_summary.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/study_repository.dart';

class GetTodaySummaryUseCase {
  GetTodaySummaryUseCase({
    required StudyRepository studyRepository,
    required ProfileRepository profileRepository,
  })  : _studyRepository = studyRepository,
        _profileRepository = profileRepository;

  final StudyRepository _studyRepository;
  final ProfileRepository _profileRepository;

  Future<TodaySummary> call() async {
    final due = await _studyRepository.dueCount();
    final streak = await _profileRepository.currentStreak();
    final freeze = await _profileRepository.freezeLeft();

    return TodaySummary(
      dueCount: due,
      newCount: 5,
      estMinutes: (due / 4).ceil().clamp(1, 60),
      streak: streak,
      freezeLeft: freeze,
    );
  }
}

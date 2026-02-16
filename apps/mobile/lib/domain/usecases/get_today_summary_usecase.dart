import '../../core/models/today_summary.dart';
import '../../data/repositories/study_repository.dart';

class GetTodaySummaryUseCase {
  GetTodaySummaryUseCase({
    required StudyRepository studyRepository,
  }) : _studyRepository = studyRepository;

  final StudyRepository _studyRepository;

  Future<TodaySummary> call() => _studyRepository.todaySummary();
}

import '../../core/models/study_card.dart';
import '../../core/models/today_summary.dart';

abstract class StudyRepository {
  Future<List<StudyCard>> dueQueue({required int limit});
  Future<void> gradeCard({required StudyCard card, required bool good});
  Future<int> dueCount();
  Future<Set<String>> learnedContentIds();
  Future<TodaySummary> todaySummary();
  Future<void> completeTodaySession();
}

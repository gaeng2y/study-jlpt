import '../../core/models/study_card.dart';

abstract class StudyRepository {
  Future<List<StudyCard>> dueQueue({required int limit});
  Future<void> gradeCard({required StudyCard card, required bool good});
  Future<int> dueCount();
}

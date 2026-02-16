import '../../core/models/study_card.dart';
import '../../data/repositories/study_repository.dart';

class GradeCardUseCase {
  GradeCardUseCase(this._studyRepository);

  final StudyRepository _studyRepository;

  Future<void> call({
    required StudyCard card,
    required bool good,
  }) {
    return _studyRepository.gradeCard(card: card, good: good);
  }
}

import '../../core/models/study_card.dart';
import '../../data/repositories/study_repository.dart';

class GetDueQueueUseCase {
  GetDueQueueUseCase(this._studyRepository);

  final StudyRepository _studyRepository;

  Future<List<StudyCard>> call(int limit) {
    return _studyRepository.dueQueue(limit: limit);
  }
}

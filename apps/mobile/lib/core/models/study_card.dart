import 'content_item.dart';

class StudyCard {
  const StudyCard({
    required this.content,
    this.reps = 0,
    this.intervalDays = 1,
    this.lapses = 0,
  });

  final ContentItem content;
  final int reps;
  final int intervalDays;
  final int lapses;

  StudyCard gradeAgain() {
    return StudyCard(
      content: content,
      reps: reps + 1,
      intervalDays: 1,
      lapses: lapses + 1,
    );
  }

  StudyCard gradeGood() {
    final nextInterval = intervalDays < 2 ? 2 : (intervalDays * 2);
    return StudyCard(
      content: content,
      reps: reps + 1,
      intervalDays: nextInterval,
      lapses: lapses,
    );
  }
}

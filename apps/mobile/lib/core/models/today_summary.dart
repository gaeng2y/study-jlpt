class TodaySummary {
  const TodaySummary({
    required this.dueCount,
    required this.newCount,
    required this.estMinutes,
    required this.streak,
    required this.freezeLeft,
    this.cardsDone = 0,
    this.isCompleted = false,
  });

  final int dueCount;
  final int newCount;
  final int estMinutes;
  final int streak;
  final int freezeLeft;
  final int cardsDone;
  final bool isCompleted;
}

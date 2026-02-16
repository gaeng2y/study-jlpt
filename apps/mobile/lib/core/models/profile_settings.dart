class ProfileSettings {
  const ProfileSettings({
    required this.targetLevel,
    required this.weeklyGoalReviews,
    required this.dailyMinCards,
    required this.onboardingCompleted,
    required this.reminderTime,
    this.examDate,
  });

  final String targetLevel;
  final int weeklyGoalReviews;
  final int dailyMinCards;
  final bool onboardingCompleted;
  final String reminderTime;
  final DateTime? examDate;

  ProfileSettings copyWith({
    String? targetLevel,
    int? weeklyGoalReviews,
    int? dailyMinCards,
    bool? onboardingCompleted,
    String? reminderTime,
    DateTime? examDate,
  }) {
    return ProfileSettings(
      targetLevel: targetLevel ?? this.targetLevel,
      weeklyGoalReviews: weeklyGoalReviews ?? this.weeklyGoalReviews,
      dailyMinCards: dailyMinCards ?? this.dailyMinCards,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      reminderTime: reminderTime ?? this.reminderTime,
      examDate: examDate ?? this.examDate,
    );
  }

  static const defaults = ProfileSettings(
    targetLevel: 'N5',
    weeklyGoalReviews: 60,
    dailyMinCards: 3,
    onboardingCompleted: false,
    reminderTime: '21:00',
  );
}

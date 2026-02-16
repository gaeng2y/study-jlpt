import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/content_item.dart';
import '../../core/models/profile_settings.dart';
import '../../core/models/study_card.dart';
import '../../core/models/today_summary.dart';
import '../repositories/content_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/study_repository.dart';

class SupabaseContentRepository implements ContentRepository {
  SupabaseContentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ContentItem>> listAll() async {
    final rows = await _client
        .from('import_jlpt_vocab')
        .select('id, kind, jlpt_level, jp, reading, meaning_ko')
        .eq('is_active', true)
        .order('imported_at');

    return rows
        .map(_toContentOrNull)
        .whereType<ContentItem>()
        .toList(growable: false);
  }

  @override
  Future<List<ContentItem>> search(String query, {String? jlptLevel}) async {
    var builder = _client
        .from('import_jlpt_vocab')
        .select('id, kind, jlpt_level, jp, reading, meaning_ko')
        .eq('is_active', true);

    if (jlptLevel != null) {
      builder = builder.eq('jlpt_level', jlptLevel);
    }

    if (query.isNotEmpty) {
      builder = builder.or(
          'jp.ilike.%$query%,reading.ilike.%$query%,meaning_ko.ilike.%$query%');
    }

    final rows = await builder.order('imported_at');

    return rows
        .map(_toContentOrNull)
        .whereType<ContentItem>()
        .toList(growable: false);
  }

  ContentItem? _toContentOrNull(Map<String, dynamic> row) =>
      _parseContentRow(row);
}

class SupabaseStudyRepository implements StudyRepository {
  SupabaseStudyRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<int> dueCount() async {
    final summary = await todaySummary();
    return summary.dueCount;
  }

  @override
  Future<Set<String>> learnedContentIds() async {
    final userId = _userId;
    if (userId == null) {
      return <String>{};
    }
    final rows = await _client
        .from('user_srs')
        .select('content_id')
        .eq('user_id', userId);
    return rows
        .map((row) => row['content_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  @override
  Future<List<StudyCard>> dueQueue({required int limit}) async {
    final userId = _userId;
    if (userId == null) {
      return const [];
    }
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = await _client
        .from('user_srs')
        .select('content_id, interval_days, reps, lapses')
        .eq('user_id', userId)
        .lte('due_at', now)
        .order('due_at')
        .limit(limit);

    if (rows.isEmpty) {
      return const [];
    }

    final contentIds = rows
        .map((row) => row['content_id'] as String?)
        .whereType<String>()
        .toList();
    if (contentIds.isEmpty) {
      return const [];
    }

    final contentRows = await _client
        .from('import_jlpt_vocab')
        .select('id, kind, jlpt_level, jp, reading, meaning_ko')
        .eq('is_active', true)
        .inFilter('id', contentIds);

    final contentById = <String, Map<String, dynamic>>{
      for (final row in contentRows) row['id'] as String: row,
    };

    final queue = <StudyCard>[];
    for (final row in rows) {
      final contentId = row['content_id'] as String?;
      if (contentId == null) {
        continue;
      }
      final content = contentById[contentId];
      if (content == null) {
        continue;
      }
      final parsed = _parseContentRow(content);
      if (parsed == null) {
        continue;
      }
      queue.add(
        StudyCard(
          content: parsed,
          reps: (row['reps'] ?? 0) as int,
          intervalDays: (row['interval_days'] ?? 1) as int,
          lapses: (row['lapses'] ?? 0) as int,
        ),
      );
    }

    return queue;
  }

  @override
  Future<void> gradeCard({required StudyCard card, required bool good}) async {
    await _client.rpc('grade_card', params: {
      'p_content_id': card.content.id,
      'p_good': good,
      'p_studied_minutes': 1,
    });
  }

  @override
  Future<TodaySummary> todaySummary() async {
    final userId = _userId;
    if (userId == null) {
      return const TodaySummary(
        dueCount: 0,
        newCount: 0,
        estMinutes: 1,
        streak: 0,
        freezeLeft: 0,
      );
    }

    final rows = await _client.rpc('get_today_summary');
    final row =
        (rows as List).isNotEmpty ? rows.first as Map<String, dynamic> : null;
    if (row == null) {
      return const TodaySummary(
        dueCount: 0,
        newCount: 0,
        estMinutes: 1,
        streak: 0,
        freezeLeft: 0,
      );
    }

    return TodaySummary(
      dueCount: (row['due_count'] as num?)?.toInt() ?? 0,
      newCount: (row['new_count'] as num?)?.toInt() ?? 0,
      estMinutes: (row['est_minutes'] as num?)?.toInt() ?? 1,
      streak: (row['streak'] as num?)?.toInt() ?? 0,
      freezeLeft: (row['freeze_left'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> completeTodaySession() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await _client.rpc('mark_today_complete');
  }
}

ContentItem? _parseContentRow(Map<String, dynamic> row) {
  final id = row['id'] as String?;
  final jp = row['jp'] as String?;
  if (id == null || id.isEmpty || jp == null || jp.isEmpty) {
    return null;
  }

  return ContentItem(
    id: id,
    kind: ((row['kind'] as String?)?.trim().isNotEmpty ?? false)
        ? (row['kind'] as String).trim()
        : 'vocab',
    jlptLevel: ((row['jlpt_level'] as String?)?.trim().isNotEmpty ?? false)
        ? (row['jlpt_level'] as String).trim().toUpperCase()
        : 'N5',
    jp: jp,
    reading: (row['reading'] ?? '') as String,
    meaningKo: ((row['meaning_ko'] as String?)?.trim().isNotEmpty ?? false)
        ? (row['meaning_ko'] as String).trim()
        : '의미 없음',
  );
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<int> currentStreak() async {
    final userId = _userId;
    if (userId == null) {
      return 0;
    }
    final row = await _client
        .from('profiles')
        .select('current_streak')
        .eq('id', userId)
        .single();

    return (row['current_streak'] ?? 0) as int;
  }

  @override
  Future<int> freezeLeft() async {
    final userId = _userId;
    if (userId == null) {
      return 0;
    }
    final row = await _client
        .from('profiles')
        .select('freeze_left')
        .eq('id', userId)
        .single();

    return (row['freeze_left'] ?? 0) as int;
  }

  @override
  Future<ProfileSettings> getSettings() async {
    final userId = _userId;
    if (userId == null) {
      return ProfileSettings.defaults;
    }

    late final Map<String, dynamic> row;
    try {
      row = await _client
          .from('profiles')
          .select(
              'target_level, weekly_goal_reviews, daily_min_cards, onboarding_completed, reminder_time, exam_date')
          .eq('id', userId)
          .single();
    } on PostgrestException catch (e) {
      // Backward compatibility for projects that have not applied
      // the onboarding_completed migration yet.
      if (!_isMissingProfileOptionalColumn(e)) {
        rethrow;
      }
      row = await _client
          .from('profiles')
          .select(
              'target_level, weekly_goal_reviews, daily_min_cards, reminder_time, exam_date')
          .eq('id', userId)
          .single();
    }

    return ProfileSettings(
      targetLevel: (row['target_level'] ?? 'N5') as String,
      weeklyGoalReviews: (row['weekly_goal_reviews'] ?? 60) as int,
      dailyMinCards: (row['daily_min_cards'] ?? 3) as int,
      onboardingCompleted: (row['onboarding_completed'] ?? false) as bool,
      reminderTime: (row['reminder_time'] ?? '21:00') as String,
      examDate: row['exam_date'] == null
          ? null
          : DateTime.tryParse(row['exam_date'] as String),
    );
  }

  @override
  Future<void> saveSettings(ProfileSettings settings) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    try {
      await _client.from('profiles').update({
        'target_level': settings.targetLevel,
        'weekly_goal_reviews': settings.weeklyGoalReviews,
        'daily_min_cards': settings.dailyMinCards,
        'onboarding_completed': settings.onboardingCompleted,
        'reminder_time': settings.reminderTime,
        'exam_date': settings.examDate?.toIso8601String().split('T').first,
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      if (!_isMissingProfileOptionalColumn(e)) {
        rethrow;
      }
      await _client.from('profiles').update({
        'target_level': settings.targetLevel,
        'weekly_goal_reviews': settings.weeklyGoalReviews,
        'daily_min_cards': settings.dailyMinCards,
        'reminder_time': settings.reminderTime,
        'exam_date': settings.examDate?.toIso8601String().split('T').first,
      }).eq('id', userId);
    }
  }

  bool _isMissingProfileOptionalColumn(PostgrestException e) {
    final missingColumn = e.message.contains('onboarding_completed') ||
        e.message.contains('reminder_time');
    return missingColumn && (e.code == '42703' || e.code == 'PGRST204');
  }
}

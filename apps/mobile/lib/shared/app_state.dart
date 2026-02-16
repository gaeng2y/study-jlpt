import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_bootstrap.dart';
import '../core/models/content_item.dart';
import '../core/models/profile_settings.dart';
import '../core/models/study_card.dart';
import '../core/models/today_summary.dart';
import '../data/mock/mock_repositories.dart';
import '../data/repositories/content_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/study_repository.dart';
import '../data/supabase/supabase_repositories.dart';
import '../domain/usecases/get_due_queue_usecase.dart';
import '../domain/usecases/get_today_summary_usecase.dart';
import '../domain/usecases/grade_card_usecase.dart';
import '../features/widgets_bridge/widget_cache_service.dart';

enum PlanMode { min3, min10, min20 }

class AppState extends ChangeNotifier {
  AppState({
    ContentRepository? contentRepository,
    StudyRepository? studyRepository,
    ProfileRepository? profileRepository,
  })  : _contentRepository = contentRepository ?? _buildContentRepository(),
        _studyRepository = studyRepository ?? _buildStudyRepository(),
        _profileRepository = profileRepository ?? _buildProfileRepository() {
    _getTodaySummary = GetTodaySummaryUseCase(
      studyRepository: _studyRepository,
      profileRepository: _profileRepository,
    );
    _getDueQueue = GetDueQueueUseCase(_studyRepository);
    _gradeCard = GradeCardUseCase(_studyRepository);
  }

  final ContentRepository _contentRepository;
  final StudyRepository _studyRepository;
  final ProfileRepository _profileRepository;

  late final GetTodaySummaryUseCase _getTodaySummary;
  late final GetDueQueueUseCase _getDueQueue;
  late final GradeCardUseCase _gradeCard;

  List<ContentItem> _contentItems = const [];
  ContentItem? _todayWord;
  TodaySummary _summary = const TodaySummary(
    dueCount: 0,
    newCount: 0,
    estMinutes: 1,
    streak: 0,
    freezeLeft: 0,
  );

  int _todayDone = 0;
  int _sessionDone = 0;
  bool _todayCompleted = false;
  bool _loading = false;
  ProfileSettings _profileSettings = ProfileSettings.defaults;
  final WidgetCacheService _widgetCacheService = WidgetCacheService();
  StreamSubscription<AuthState>? _authSub;

  bool get loading => _loading;
  List<ContentItem> get contentItems => List.unmodifiable(_contentItems);
  ContentItem? get todayWord => _todayWord;
  int get sessionDone => _sessionDone;
  bool get todayCompleted => _todayCompleted;
  TodaySummary get summary => _summary;
  String get dataSource =>
      _contentRepository is SupabaseContentRepository ? 'Supabase' : 'Mock';
  bool get isAuthenticated {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return false;
    }
    return client.auth.currentSession != null;
  }

  bool get needsAuth =>
      _contentRepository is SupabaseContentRepository && !isAuthenticated;
  String get authUserId {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return 'not_ready';
    }
    return client.auth.currentUser?.id ?? 'null';
  }

  ProfileSettings get profileSettings => _profileSettings;
  bool get needsOnboarding => !_profileSettings.onboardingCompleted;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();

    _bindAuthState();
    _contentItems = await _contentRepository.listAll();
    _profileSettings = await _profileRepository.getSettings();
    _summary = await _getTodaySummary();
    if (_contentItems.isNotEmpty) {
      _todayWord = _contentItems[Random().nextInt(_contentItems.length)];
    }
    await _refreshWidgetCache();

    _loading = false;
    notifyListeners();
  }

  Future<List<StudyCard>> getStudyQueue(PlanMode mode) async {
    final target = switch (mode) {
      PlanMode.min3 => 3,
      PlanMode.min10 => 10,
      PlanMode.min20 => 20,
    };

    final dueQueue = await _getDueQueue(target);
    if (dueQueue.isNotEmpty) {
      return dueQueue;
    }

    // If there is no due queue yet, start learning from seeded content.
    final levelItems = _contentItems
        .where((item) => item.jlptLevel == _profileSettings.targetLevel)
        .toList();
    final source = levelItems.isNotEmpty ? levelItems : _contentItems;
    if (source.isEmpty) {
      return const [];
    }

    final count = source.length < target ? source.length : target;
    return source.take(count).map((item) {
      return StudyCard(
        content: item,
        reps: 0,
        intervalDays: 1,
        lapses: 0,
      );
    }).toList();
  }

  Future<void> gradeCard({
    required StudyCard card,
    required bool good,
  }) async {
    await _gradeCard(card: card, good: good);

    _sessionDone += 1;
    _todayDone += 1;
    if (_todayDone >= 3) {
      _todayCompleted = true;
    }

    _summary = await _getTodaySummary();
    await _refreshWidgetCache();
    notifyListeners();
  }

  Future<void> completeSession() async {
    if (!_todayCompleted) {
      _todayCompleted = true;
    }

    _summary = await _getTodaySummary();
    await _refreshWidgetCache();
    notifyListeners();
  }

  Future<void> searchContent(String query) async {
    _contentItems = await _contentRepository.search(query);
    notifyListeners();
  }

  Future<void> searchContentWithLevel({
    required String query,
    String? jlptLevel,
  }) async {
    _contentItems =
        await _contentRepository.search(query, jlptLevel: jlptLevel);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String targetLevel,
    required int weeklyGoalReviews,
    required int dailyMinCards,
  }) async {
    await updateLearningSettings(
      targetLevel: targetLevel,
      weeklyGoalReviews: weeklyGoalReviews,
      dailyMinCards: dailyMinCards,
      markOnboardingCompleted: true,
    );
  }

  Future<void> updateLearningSettings({
    required String targetLevel,
    required int weeklyGoalReviews,
    required int dailyMinCards,
    bool markOnboardingCompleted = false,
  }) async {
    _profileSettings = _profileSettings.copyWith(
      targetLevel: targetLevel,
      weeklyGoalReviews: weeklyGoalReviews,
      dailyMinCards: dailyMinCards,
      onboardingCompleted:
          markOnboardingCompleted || _profileSettings.onboardingCompleted,
    );
    await _profileRepository.saveSettings(_profileSettings);
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return;
    }
    debugPrint('OAuth redirectTo=studyjlpt://login-callback/ (google)');
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'studyjlpt://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signInWithApple() async {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return;
    }
    debugPrint('OAuth redirectTo=studyjlpt://login-callback/ (apple)');
    await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'studyjlpt://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return;
    }
    await client.auth.signOut();
    _profileSettings = ProfileSettings.defaults;
    _summary = const TodaySummary(
      dueCount: 0,
      newCount: 0,
      estMinutes: 1,
      streak: 0,
      freezeLeft: 0,
    );
    notifyListeners();
  }

  static ContentRepository _buildContentRepository() {
    if (!SupabaseBootstrap.isConfigured) {
      return MockContentRepository();
    }
    final client = _supabaseClientOrNull();
    if (client == null) {
      return MockContentRepository();
    }
    return SupabaseContentRepository(client);
  }

  static StudyRepository _buildStudyRepository() {
    if (!SupabaseBootstrap.isConfigured) {
      return MockStudyRepository();
    }
    final client = _supabaseClientOrNull();
    if (client == null) {
      return MockStudyRepository();
    }
    return SupabaseStudyRepository(client);
  }

  static ProfileRepository _buildProfileRepository() {
    if (!SupabaseBootstrap.isConfigured) {
      return MockProfileRepository();
    }
    final client = _supabaseClientOrNull();
    if (client == null) {
      return MockProfileRepository();
    }
    return SupabaseProfileRepository(client);
  }

  static SupabaseClient? _supabaseClientOrNull() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void _bindAuthState() {
    final client = _supabaseClientOrNull();
    if (client == null || _authSub != null) {
      return;
    }

    _authSub = client.auth.onAuthStateChange.listen((_) async {
      _profileSettings = await _profileRepository.getSettings();
      _summary = await _getTodaySummary();
      notifyListeners();
    });
  }

  Future<void> _refreshWidgetCache() async {
    try {
      await _widgetCacheService.saveTodaySummary(_summary);
    } catch (_) {
      // Widget extension can be unavailable during local preview/dev.
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

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
import 'services/notification_service.dart';
import 'services/telemetry_service.dart';

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
    cardsDone: 0,
    isCompleted: false,
  );

  int _sessionDone = 0;
  bool _loading = false;
  ProfileSettings _profileSettings = ProfileSettings.defaults;
  final WidgetCacheService _widgetCacheService = WidgetCacheService();
  final NotificationService _notificationService = NotificationService.instance;
  final TelemetryService _telemetry = TelemetryService.instance;
  StreamSubscription<AuthState>? _authSub;
  Timer? _oauthTimeoutTimer;
  bool _oauthInProgress = false;
  String? _oauthProviderInProgress;
  String? _authErrorMessage;

  bool get loading => _loading;
  List<ContentItem> get contentItems => List.unmodifiable(_contentItems);
  ContentItem? get todayWord => _todayWord;
  int get sessionDone => _sessionDone;
  bool get todayCompleted => _summary.isCompleted;
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
  bool get oauthInProgress => _oauthInProgress;
  String? get authErrorMessage => _authErrorMessage;
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

    try {
      _bindAuthState();
      _telemetry.initialize(_supabaseClientOrNull());
      _contentItems = await _contentRepository.listAll();
      _profileSettings = await _profileRepository.getSettings();
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      await _notificationService
          .scheduleDailyReminder(_profileSettings.reminderTime);
      _summary = await _getTodaySummary();
      if (_contentItems.isNotEmpty) {
        _todayWord = _contentItems[Random().nextInt(_contentItems.length)];
      }
      await _refreshWidgetCache();
      await _telemetry.logEvent('app_initialized', {
        'source': dataSource,
        'items': _contentItems.length,
      });
    } catch (error, stack) {
      await _telemetry.recordError(
        error,
        stack,
        fatal: false,
        context: 'app_state_initialize',
      );
      _authErrorMessage = '초기화 중 오류가 발생했습니다. 다시 시도해 주세요.';
      if (_contentItems.isEmpty) {
        _contentItems = await MockContentRepository().listAll();
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<List<StudyCard>> getStudyQueue(PlanMode mode) async {
    final random = Random();
    final target = switch (mode) {
      PlanMode.min3 => 3,
      PlanMode.min10 => 10,
      PlanMode.min20 => 20,
    };

    final dueQueue = await _getDueQueue(target);
    if (dueQueue.isNotEmpty) {
      final shuffledDue = dueQueue.toList()..shuffle(random);
      return shuffledDue;
    }

    final learnedIds = await _studyRepository.learnedContentIds();

    // If there is no due queue yet, start learning from unlearned content.
    final levelItems = _contentItems
        .where((item) =>
            item.jlptLevel == _profileSettings.targetLevel &&
            !learnedIds.contains(item.id))
        .toList();
    final source = levelItems.isNotEmpty
        ? levelItems
        : _contentItems.where((item) => !learnedIds.contains(item.id)).toList();
    if (source.isEmpty) {
      return const [];
    }

    source.shuffle(random);
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
    await _telemetry.logEvent('card_answered', {
      'kind': card.content.kind,
      'grade': good ? 'good' : 'again',
      'duration_ms': 0,
    });

    _sessionDone += 1;
    _summary = await _getTodaySummary();
    await _refreshWidgetCache();
    notifyListeners();
  }

  Future<void> completeSession() async {
    await _studyRepository.completeTodaySession();
    _summary = await _getTodaySummary();
    await _refreshWidgetCache();
    await _telemetry.logEvent('study_completed', {
      'cards': _sessionDone,
      'minutes': _summary.estMinutes,
      'due_count': _summary.dueCount,
      'new_count': _summary.newCount,
      'streak': _summary.streak,
    });
    notifyListeners();
  }

  Future<void> searchContent(String query) async {
    _contentItems = await _contentRepository.search(query);
    final trimmed = query.trim();
    if (trimmed.length >= 2) {
      await _telemetry.logEvent('content_search', {
        'query_length': trimmed.length,
        'jlpt_level': 'all',
        'result_count': _contentItems.length,
      });
    }
    notifyListeners();
  }

  Future<void> searchContentWithLevel({
    required String query,
    String? jlptLevel,
  }) async {
    _contentItems =
        await _contentRepository.search(query, jlptLevel: jlptLevel);
    final trimmed = query.trim();
    if (trimmed.length >= 2 || jlptLevel != null) {
      await _telemetry.logEvent('content_search', {
        'query_length': trimmed.length,
        'jlpt_level': jlptLevel ?? 'all',
        'result_count': _contentItems.length,
      });
    }
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String targetLevel,
    required int weeklyGoalReviews,
    required int dailyMinCards,
    String? reminderTime,
  }) async {
    await updateLearningSettings(
      targetLevel: targetLevel,
      weeklyGoalReviews: weeklyGoalReviews,
      dailyMinCards: dailyMinCards,
      reminderTime: reminderTime ?? _profileSettings.reminderTime,
      markOnboardingCompleted: true,
    );
    await _telemetry.logEvent('onboarding_completed', {
      'target_level': targetLevel,
      'weekly_goal_reviews': weeklyGoalReviews,
      'daily_min_cards': dailyMinCards,
    });
  }

  Future<void> updateLearningSettings({
    required String targetLevel,
    required int weeklyGoalReviews,
    required int dailyMinCards,
    String? reminderTime,
    bool markOnboardingCompleted = false,
  }) async {
    final before = _profileSettings;
    _profileSettings = _profileSettings.copyWith(
      targetLevel: targetLevel,
      weeklyGoalReviews: weeklyGoalReviews,
      dailyMinCards: dailyMinCards,
      reminderTime: reminderTime ?? _profileSettings.reminderTime,
      onboardingCompleted:
          markOnboardingCompleted || _profileSettings.onboardingCompleted,
    );
    await _profileRepository.saveSettings(_profileSettings);
    await _notificationService
        .scheduleDailyReminder(_profileSettings.reminderTime);
    _summary = await _getTodaySummary();
    await _refreshWidgetCache();
    await _telemetry.logEvent('settings_updated', {
      'target_level_before': before.targetLevel,
      'target_level_after': _profileSettings.targetLevel,
      'weekly_goal_before': before.weeklyGoalReviews,
      'weekly_goal_after': _profileSettings.weeklyGoalReviews,
      'daily_min_before': before.dailyMinCards,
      'daily_min_after': _profileSettings.dailyMinCards,
      'reminder_before': before.reminderTime,
      'reminder_after': _profileSettings.reminderTime,
      'onboarding_completed': _profileSettings.onboardingCompleted,
    });
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return;
    }
    _oauthProviderInProgress = 'google';
    _setOAuthInProgress(true);
    _setAuthError(null);
    await _telemetry.logEvent('login_started', {
      'provider': 'google',
    });
    _startOAuthTimeoutGuard();
    try {
      debugPrint('OAuth redirectTo=studyjlpt://login-callback/ (google)');
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'studyjlpt://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _setOAuthInProgress(false);
      _oauthProviderInProgress = null;
      await _telemetry.logEvent('login_failed', {
        'provider': 'google',
        'error_type': e.runtimeType.toString(),
      });
      _setAuthError('Google 로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return;
    }
    _oauthProviderInProgress = 'apple';
    _setOAuthInProgress(true);
    _setAuthError(null);
    await _telemetry.logEvent('login_started', {
      'provider': 'apple',
    });
    _startOAuthTimeoutGuard();
    try {
      debugPrint('OAuth redirectTo=studyjlpt://login-callback/ (apple)');
      await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'studyjlpt://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _setOAuthInProgress(false);
      _oauthProviderInProgress = null;
      await _telemetry.logEvent('login_failed', {
        'provider': 'apple',
        'error_type': e.runtimeType.toString(),
      });
      _setAuthError('Apple 로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      rethrow;
    }
  }

  Future<void> signOut() async {
    final client = _supabaseClientOrNull();
    if (client == null) {
      return;
    }
    await _telemetry.logEvent('logout', {
      'source': 'profile',
    });
    await client.auth.signOut();
    await _notificationService.cancelDailyReminder();
    _profileSettings = ProfileSettings.defaults;
    _summary = const TodaySummary(
      dueCount: 0,
      newCount: 0,
      estMinutes: 1,
      streak: 0,
      freezeLeft: 0,
      cardsDone: 0,
      isCompleted: false,
    );
    _sessionDone = 0;
    notifyListeners();
  }

  Future<void> trackDailyPlanStarted(PlanMode mode) async {
    await _telemetry.logEvent('daily_plan_started', {
      'mode': mode.name,
    });
  }

  Future<void> trackWidgetOpened(String type) async {
    await _telemetry.logEvent('widget_opened', {
      'type': type,
    });
  }

  Future<void> trackNavigationChanged(int index) async {
    final tab = switch (index) {
      0 => 'today',
      1 => 'practice',
      2 => 'study',
      3 => 'content',
      4 => 'profile',
      _ => 'unknown',
    };
    await _telemetry.logEvent('tab_opened', {
      'tab': tab,
      'index': index,
    });
  }

  Future<void> trackContentOpened(ContentItem item) async {
    await _telemetry.logEvent('content_opened', {
      'content_id': item.id,
      'kind': item.kind,
      'jlpt_level': item.jlptLevel,
    });
  }

  Future<void> trackStudySessionStarted({
    required PlanMode mode,
    required int queueLength,
    required String sessionId,
  }) async {
    await _telemetry.logEvent('study_session_started', {
      'mode': mode.name,
      'queue_length': queueLength,
      'session_id': sessionId,
    });
  }

  Future<void> trackStudySessionFinished({
    required PlanMode mode,
    required int queueLength,
    required int goodCount,
    required int againCount,
    required int elapsedSeconds,
    required String sessionId,
  }) async {
    await _telemetry.logEvent('study_session_finished', {
      'mode': mode.name,
      'queue_length': queueLength,
      'good_count': goodCount,
      'again_count': againCount,
      'elapsed_seconds': elapsedSeconds,
      'session_id': sessionId,
    });
  }

  Future<void> trackStudySessionAbandoned({
    required PlanMode mode,
    required int queueLength,
    required int answeredCount,
    required int elapsedSeconds,
    required String sessionId,
  }) async {
    await _telemetry.logEvent('study_session_abandoned', {
      'mode': mode.name,
      'queue_length': queueLength,
      'answered_count': answeredCount,
      'elapsed_seconds': elapsedSeconds,
      'session_id': sessionId,
    });
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

    _authSub = client.auth.onAuthStateChange.listen((state) async {
      try {
        if (state.event == AuthChangeEvent.signedIn) {
          _oauthTimeoutTimer?.cancel();
          _setOAuthInProgress(false);
          _oauthProviderInProgress = null;
          _setAuthError(null);
          await _telemetry.logEvent('login_success', {
            'provider': state.session?.user.appMetadata['provider'] ?? 'oauth',
          });
        }
        if (state.event == AuthChangeEvent.signedOut) {
          _oauthTimeoutTimer?.cancel();
          _setOAuthInProgress(false);
          _oauthProviderInProgress = null;
        }

        _profileSettings = await _profileRepository.getSettings();
        _summary = await _getTodaySummary();
        notifyListeners();
      } catch (error, stack) {
        await _telemetry.recordError(
          error,
          stack,
          fatal: false,
          context: 'auth_state_listener',
        );
      }
    });
  }

  void _startOAuthTimeoutGuard() {
    _oauthTimeoutTimer?.cancel();
    _oauthTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!isAuthenticated) {
        final provider = _oauthProviderInProgress ?? 'unknown';
        _setOAuthInProgress(false);
        _oauthProviderInProgress = null;
        _setAuthError(
          '로그인 콜백 처리에 실패했습니다. 잠시 후 다시 시도해 주세요.',
        );
        _telemetry.logEvent('login_timeout', {
          'provider': provider,
          'timeout_seconds': 45,
        });
      }
    });
  }

  void _setOAuthInProgress(bool value) {
    if (_oauthInProgress == value) {
      return;
    }
    _oauthInProgress = value;
    notifyListeners();
  }

  void _setAuthError(String? message) {
    if (_authErrorMessage == message) {
      return;
    }
    _authErrorMessage = message;
    notifyListeners();
  }

  Future<void> _refreshWidgetCache() async {
    try {
      await _widgetCacheService.saveTodaySummary(
        _summary,
        dailyWord: _todayWord,
      );
    } catch (_) {
      // Widget extension can be unavailable during local preview/dev.
    }
  }

  @override
  void dispose() {
    _oauthTimeoutTimer?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

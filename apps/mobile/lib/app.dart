import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/content/content_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/study/study_session_screen.dart';
import 'features/today/today_screen.dart';
import 'shared/app_state.dart';
import 'shared/widgets/glass_surface.dart';

class IleoTokTokApp extends StatelessWidget {
  const IleoTokTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forceIosGlass =
        bool.fromEnvironment('FORCE_IOS_GLASS', defaultValue: false);
    final platform = forceIosGlass ? TargetPlatform.iOS : defaultTargetPlatform;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '일어톡톡',
      theme: AppTheme.light(platform),
      home: const _RootPage(),
    );
  }
}

class _RootPage extends StatefulWidget {
  const _RootPage();

  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  final AppState _state = AppState();
  int _index = 0;
  late final Future<void> _bootstrap;
  StreamSubscription<Uri>? _deepLinkSub;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _bootstrap = _state.initialize();
    _bindDeepLinks();
  }

  Future<void> _bindDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleDeepLink(initial);
      }
      _deepLinkSub = _appLinks.uriLinkStream.listen(
        _handleDeepLink,
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'studyjlpt') {
      return;
    }

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (host == 'login-callback') {
      return;
    }

    if (host == 'review' || path == '/review') {
      if (mounted) {
        setState(() => _index = 1);
      }
      return;
    }

    if (host == 'content' || path.startsWith('/content')) {
      if (mounted) {
        setState(() => _index = 2);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(state: _state),
      StudySessionScreen(state: _state),
      ContentScreen(state: _state),
      ProfileScreen(state: _state),
    ];

    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        return AnimatedBuilder(
          animation: _state,
          builder: (context, _) {
            return Scaffold(
              body: _state.needsAuth
                  ? AuthScreen(state: _state)
                  : _state.needsOnboarding
                      ? OnboardingScreen(state: _state)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey(_index),
                            child: pages[_index],
                          ),
                        ),
              bottomNavigationBar: (_state.needsOnboarding || _state.needsAuth)
                  ? null
                  : _BottomNav(
                      index: _index,
                      onChanged: (value) => setState(() => _index = value),
                    ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _state.dispose();
    super.dispose();
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIos) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassSurface(
          radius: 26,
          padding: EdgeInsets.zero,
          child: CupertinoTabBar(
            currentIndex: index,
            onTap: onChanged,
            backgroundColor: Colors.transparent,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: const Color(0xFF6A778B),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.calendar_today),
                label: '오늘',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.square_list),
                label: '학습',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.book),
                label: '콘텐츠',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                label: '프로필',
              ),
            ],
          ),
        ),
      );
    }

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onChanged,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.today_outlined), label: '오늘'),
        NavigationDestination(icon: Icon(Icons.quiz_outlined), label: '학습'),
        NavigationDestination(
            icon: Icon(Icons.menu_book_outlined), label: '콘텐츠'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
      ],
    );
  }
}

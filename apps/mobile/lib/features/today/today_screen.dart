import 'package:flutter/material.dart';

import '../../shared/app_state.dart';
import '../../shared/widgets/glass_surface.dart';
import '../study/study_session_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final summary = state.summary;
        final minCards = state.profileSettings.dailyMinCards;
        final minMode = switch (minCards) {
          <= 3 => PlanMode.min3,
          <= 10 => PlanMode.min10,
          _ => PlanMode.min20,
        };

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFF2FBFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '오늘 플랜',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '복습 ${summary.dueCount}개 · 신규 ${summary.newCount}개 · 약 ${summary.estMinutes}분',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _Panel(
                  isIos: isIos,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Metric(label: 'streak', value: '${summary.streak}일'),
                      _Metric(label: 'freeze', value: '${summary.freezeLeft}개'),
                      _Metric(
                        label: '오늘 진행',
                        value: '${summary.cardsDone}/$minCards',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Panel(
                  isIos: isIos,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('오늘의 단어',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (state.todayWord != null) ...[
                        Text(
                          '${state.todayWord!.jp} (${state.todayWord!.reading})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(state.todayWord!.meaningKo),
                      ] else
                        const Text('로딩 중'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PlanButton(
                  isIos: isIos,
                  label: '최소 완료 $minCards카드',
                  subtitle: '루틴이 끊기지 않게 짧게 끝내기',
                  onTap: () => _start(context, minMode),
                ),
                const SizedBox(height: 10),
                _PlanButton(
                  isIos: isIos,
                  label: '10분 플랜',
                  subtitle: '기본 루틴',
                  onTap: () => _start(context, PlanMode.min10),
                ),
                const SizedBox(height: 10),
                _PlanButton(
                  isIos: isIos,
                  label: '20분 플랜',
                  subtitle: '집중 학습',
                  onTap: () => _start(context, PlanMode.min20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _start(BuildContext context, PlanMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudySessionScreen(state: state, initialMode: mode),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.isIos});

  final Widget child;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    if (isIos) {
      return GlassSurface(child: child);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _PlanButton extends StatelessWidget {
  const _PlanButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isIos,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    if (isIos) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassSurface(
          radius: 18,
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

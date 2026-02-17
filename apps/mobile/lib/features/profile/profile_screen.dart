import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/app_state.dart';
import '../../shared/widgets/glass_surface.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final summary = state.summary;
        final settings = state.profileSettings;

        return Scaffold(
          appBar: AppBar(
            title: const Text('프로필'),
            actions: [
              IconButton(
                onPressed: () => _openSettingsEditor(
                  context: context,
                  state: state,
                  isIos: isIos,
                ),
                icon: const Icon(Icons.tune),
                tooltip: '학습 설정 변경',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE5EDFF),
                  Color(0xFFF1F5FF),
                  Color(0xFFDFFAF4)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Panel(
                    isIos: isIos,
                    child: _InfoBlock(
                      title: '학습 설정',
                      lines: [
                        '목표 레벨: ${settings.targetLevel}',
                        '주간 목표: ${settings.weeklyGoalReviews} cards',
                        '하루 최소 완료: ${settings.dailyMinCards} cards',
                        '알림 시간: ${settings.reminderTime}',
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Panel(
                    isIos: isIos,
                    child: _InfoBlock(
                      title: '학습 지표',
                      lines: [
                        '현재 streak: ${summary.streak}일',
                        '남은 freeze: ${summary.freezeLeft}개',
                        '남은 due: ${summary.dueCount}개',
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (state.isAuthenticated)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('로그아웃'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openSettingsEditor({
  required BuildContext context,
  required AppState state,
  required bool isIos,
}) async {
  final current = state.profileSettings;
  String level = current.targetLevel;
  int weeklyGoal = current.weeklyGoalReviews;
  int dailyMin = current.dailyMinCards;
  String reminderTime = current.reminderTime;
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '학습 설정 변경',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['N5', 'N4', 'N3', 'N2', 'N1']
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: level == item,
                            onSelected: (_) => setModalState(() {
                              level = item;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('주간 목표 카드 수: $weeklyGoal'),
                  Slider(
                    value: weeklyGoal.toDouble(),
                    min: 20,
                    max: 200,
                    divisions: 18,
                    label: '$weeklyGoal',
                    onChanged: (v) => setModalState(() {
                      weeklyGoal = v.round();
                    }),
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('알림 시간'),
                    subtitle: Text(reminderTime),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await _pickReminderTime(
                        context: context,
                        isIos: isIos,
                        initial: reminderTime,
                      );
                      if (picked != null) {
                        setModalState(() {
                          reminderTime = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  if (isIos)
                    CupertinoSlidingSegmentedControl<int>(
                      groupValue: dailyMin,
                      children: const {
                        3: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('3카드'),
                        ),
                        10: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('10카드'),
                        ),
                        20: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('20카드'),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            dailyMin = value;
                          });
                        }
                      },
                    )
                  else
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 3, label: Text('3카드')),
                        ButtonSegment(value: 10, label: Text('10카드')),
                        ButtonSegment(value: 20, label: Text('20카드')),
                      ],
                      selected: {dailyMin},
                      onSelectionChanged: (values) {
                        setModalState(() {
                          dailyMin = values.first;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() {
                                saving = true;
                              });
                              await state.updateLearningSettings(
                                targetLevel: level,
                                weeklyGoalReviews: weeklyGoal,
                                dailyMinCards: dailyMin,
                                reminderTime: reminderTime,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      child: Text(saving ? '저장 중...' : '저장'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<String?> _pickReminderTime({
  required BuildContext context,
  required bool isIos,
  required String initial,
}) async {
  final parts = initial.split(':');
  final hour = parts.length == 2 ? int.tryParse(parts[0]) ?? 21 : 21;
  final minute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;

  if (isIos) {
    DateTime selected = DateTime(2026, 1, 1, hour, minute);
    final result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          height: 280,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    child: const Text('완료'),
                    onPressed: () {
                      final hh = selected.hour.toString().padLeft(2, '0');
                      final mm = selected.minute.toString().padLeft(2, '0');
                      Navigator.of(context).pop('$hh:$mm');
                    },
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selected,
                    use24hFormat: true,
                    onDateTimeChanged: (value) => selected = value,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result;
  }

  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: hour, minute: minute),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
  if (picked == null) {
    return null;
  }
  final hh = picked.hour.toString().padLeft(2, '0');
  final mm = picked.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(line),
          ),
      ],
    );
  }
}

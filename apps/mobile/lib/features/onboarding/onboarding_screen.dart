import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/app_state.dart';
import '../../shared/widgets/glass_surface.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late String _level;
  late int _weeklyGoal;
  late int _dailyMin;
  late String _reminderTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.state.profileSettings;
    _level = settings.targetLevel;
    _weeklyGoal = settings.weeklyGoalReviews;
    _dailyMin = settings.dailyMinCards;
    _reminderTime = settings.reminderTime;
  }

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE5EDFF), Color(0xFFF1F5FF), Color(0xFFDFFAF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  '학습 목표를 설정해요',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('초기 목표를 정하면 오늘 플랜과 프로필에 바로 반영됩니다.'),
                const SizedBox(height: 20),
                _Panel(
                  isIos: isIos,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('목표 JLPT 레벨',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['N5', 'N4', 'N3', 'N2', 'N1']
                            .map(
                              (level) => ChoiceChip(
                                label: Text(level),
                                selected: _level == level,
                                onSelected: (_) =>
                                    setState(() => _level = level),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      Text('주간 목표 카드 수: $_weeklyGoal',
                          style: Theme.of(context).textTheme.titleMedium),
                      Slider(
                        value: _weeklyGoal.toDouble(),
                        min: 20,
                        max: 200,
                        divisions: 18,
                        label: '$_weeklyGoal',
                        onChanged: (v) =>
                            setState(() => _weeklyGoal = v.round()),
                      ),
                      const SizedBox(height: 12),
                      Text('하루 최소 완료',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (isIos)
                        CupertinoSlidingSegmentedControl<int>(
                          groupValue: _dailyMin,
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
                              setState(() => _dailyMin = value);
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
                          selected: {_dailyMin},
                          onSelectionChanged: (values) {
                            setState(() => _dailyMin = values.first);
                          },
                        ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('알림 시간'),
                        subtitle: Text(_reminderTime),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await _pickReminderTime(
                            context: context,
                            isIos: isIos,
                            initial: _reminderTime,
                          );
                          if (picked != null) {
                            setState(() => _reminderTime = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '저장 중...' : '시작하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.state.completeOnboarding(
      targetLevel: _level,
      weeklyGoalReviews: _weeklyGoal,
      dailyMinCards: _dailyMin,
      reminderTime: _reminderTime,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
  }
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

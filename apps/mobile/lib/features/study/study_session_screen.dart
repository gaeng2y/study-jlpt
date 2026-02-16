import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/models/study_card.dart';
import '../../shared/app_state.dart';
import '../../shared/widgets/glass_surface.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({
    super.key,
    required this.state,
    this.initialMode = PlanMode.min10,
  });

  final AppState state;
  final PlanMode initialMode;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  static const MethodChannel _nativeStudyChannel =
      MethodChannel('studyjlpt/native_study');

  List<StudyCard> _queue = const [];
  int _index = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _nativeUnsupported = false;
  bool _speaking = false;
  String? _lastGradeLabel;
  Timer? _gradeLabelTimer;
  final FlutterTts _tts = FlutterTts();
  late final DateTime _sessionStartedAt;
  late final String _sessionId;
  int _goodCount = 0;
  int _againCount = 0;
  bool _sessionTerminalTracked = false;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _sessionId = _sessionStartedAt.microsecondsSinceEpoch.toString();
    _nativeStudyChannel.setMethodCallHandler(_handleNativeStudyEvent);
    _configureTts();
    _loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = !_loading && _index >= _queue.length;

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF5EA), Color(0xFFEAF9FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : isDone
                        ? _doneView(context)
                        : _nativeOnlyView(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nativeOnlyView(BuildContext context) {
    final card = _queue[_index];
    final progress = '${_index + 1} / ${_queue.length}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 500,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildEmbeddedNativeCard(card),
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$progress 남음',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Material(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(999),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: _speaking
                                        ? null
                                        : () => _speakCard(card),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.volume_up_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _speaking ? '재생 중' : '듣기',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              opacity: _lastGradeLabel == null ? 0 : 1,
                              child: Text(
                                _lastGradeLabel ?? '',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_nativeUnsupported) ...[
                const SizedBox(height: 8),
                const Text(
                  '네이티브 카드 연결을 찾지 못했습니다. 앱을 재실행해 주세요.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _doneView(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final elapsed = DateTime.now().difference(_sessionStartedAt);
    final elapsedMinutes = elapsed.inMinutes;
    final elapsedSeconds = elapsed.inSeconds % 60;
    final totalAnswers = _goodCount + _againCount;
    final goodRate =
        totalAnswers == 0 ? 0 : ((_goodCount / totalAnswers) * 100).round();

    final content = Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.state.todayCompleted ? '오늘 완료!' : '세션 완료',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text('처리 카드 ${_queue.length}개'),
          Text('GOOD $_goodCount · AGAIN $_againCount (정답률 $goodRate%)'),
          Text('소요 시간 $elapsedMinutes분 $elapsedSeconds초'),
          Text('현재 streak ${widget.state.summary.streak}일'),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              final elapsedSeconds =
                  DateTime.now().difference(_sessionStartedAt).inSeconds;
              if (!_sessionTerminalTracked) {
                _sessionTerminalTracked = true;
                await widget.state.trackStudySessionFinished(
                  mode: widget.initialMode,
                  queueLength: _queue.length,
                  goodCount: _goodCount,
                  againCount: _againCount,
                  elapsedSeconds: elapsedSeconds,
                  sessionId: _sessionId,
                );
              }
              await widget.state.completeSession();
              if (!mounted) {
                return;
              }
              Navigator.of(context).maybePop();
            },
            child: const Text('오늘 플랜으로 돌아가기'),
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: isIos
            ? GlassSurface(radius: 24, padding: EdgeInsets.zero, child: content)
            : Card(child: content),
      ),
    );
  }

  Future<void> _loadQueue() async {
    final queue = await widget.state.getStudyQueue(widget.initialMode);
    if (!mounted) {
      return;
    }

    setState(() {
      _queue = queue;
      _loading = false;
    });
    await widget.state.trackStudySessionStarted(
      mode: widget.initialMode,
      queueLength: queue.length,
      sessionId: _sessionId,
    );
  }

  Future<void> _applyGrade({required bool good}) async {
    if (_submitting || _index >= _queue.length) {
      return;
    }

    final card = _queue[_index];
    setState(() {
      _submitting = true;
    });

    await widget.state.gradeCard(card: card, good: good);
    await _tts.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _index += 1;
      _submitting = false;
      _lastGradeLabel = good ? 'GOOD' : 'AGAIN';
      if (good) {
        _goodCount += 1;
      } else {
        _againCount += 1;
      }
    });
    _gradeLabelTimer?.cancel();
    _gradeLabelTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastGradeLabel = null;
      });
    });
  }

  Future<void> _configureTts() async {
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.autoStopSharedSession(false);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        <IosTextToSpeechAudioCategoryOptions>[
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }
    await _tts.setLanguage('ja-JP');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.42);
    _tts.setStartHandler(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _speaking = true;
      });
    });
    _tts.setCompletionHandler(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _speaking = false;
      });
    });
    _tts.setCancelHandler(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _speaking = false;
      });
    });
    _tts.setErrorHandler((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speaking = false;
      });
    });
  }

  Future<void> _speakCard(StudyCard card) async {
    final text = card.content.reading.trim().isNotEmpty
        ? card.content.reading.trim()
        : card.content.jp.trim();
    if (text.isEmpty) {
      return;
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  Widget _buildEmbeddedNativeCard(StudyCard card) {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      return const Center(
        child: Text('이 플랫폼은 네이티브 임베드를 지원하지 않습니다.'),
      );
    }

    final params = {
      'contentId': card.content.id,
      'kind': card.content.kind,
      'jlptLevel': card.content.jlptLevel,
      'jp': card.content.jp,
      'reading': card.content.reading,
      'meaningKo': card.content.meaningKo,
    };

    if (Platform.isIOS) {
      return UiKitView(
        key: ValueKey('ios-${card.content.id}'),
        viewType: 'studyjlpt/native_study_view',
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return AndroidView(
      key: ValueKey('android-${card.content.id}'),
      viewType: 'studyjlpt/native_study_view',
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  Future<void> _handleNativeStudyEvent(MethodCall call) async {
    if (!mounted) {
      return;
    }
    if (call.method != 'onGrade' || _index >= _queue.length) {
      return;
    }

    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
    final contentId = args['contentId'] as String?;
    final grade = args['grade'] as String?;
    final currentContentId = _queue[_index].content.id;

    if (contentId != currentContentId) {
      return;
    }

    if (grade == 'good') {
      await _applyGrade(good: true);
      return;
    }
    if (grade == 'again') {
      await _applyGrade(good: false);
      return;
    }
  }

  @override
  void dispose() {
    if (!_sessionTerminalTracked && !_loading && _queue.isNotEmpty) {
      final answeredCount = _index.clamp(0, _queue.length).toInt();
      final elapsedSeconds =
          DateTime.now().difference(_sessionStartedAt).inSeconds;
      unawaited(
        widget.state.trackStudySessionAbandoned(
          mode: widget.initialMode,
          queueLength: _queue.length,
          answeredCount: answeredCount,
          elapsedSeconds: elapsedSeconds,
          sessionId: _sessionId,
        ),
      );
    }
    _gradeLabelTimer?.cancel();
    _nativeStudyChannel.setMethodCallHandler(null);
    _tts.stop();
    super.dispose();
  }
}

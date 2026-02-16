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

  @override
  void initState() {
    super.initState();
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
    final progress = '${_index + 1} / ${_queue.length}';
    final card = _queue[_index];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$progress 남음',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: _lastGradeLabel == null ? 0 : 1,
                child: Text(
                  _lastGradeLabel ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2F5A78),
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: _speaking ? null : () => _speakCard(card),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(_speaking ? '재생 중...' : '듣기'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 460,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _buildEmbeddedNativeCard(card),
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
          Text('현재 streak ${widget.state.summary.streak}일'),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
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
    _gradeLabelTimer?.cancel();
    _nativeStudyChannel.setMethodCallHandler(null);
    _tts.stop();
    super.dispose();
  }
}

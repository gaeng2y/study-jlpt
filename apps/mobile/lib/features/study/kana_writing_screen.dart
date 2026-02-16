import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/content_item.dart';
import '../../shared/app_state.dart';

class KanaWritingScreen extends StatefulWidget {
  const KanaWritingScreen({super.key, required this.state});

  final AppState state;

  @override
  State<KanaWritingScreen> createState() => _KanaWritingScreenState();
}

class _KanaWritingScreenState extends State<KanaWritingScreen> {
  final Random _random = Random();
  late final List<ContentItem> _kanaItems;
  int _index = 0;
  bool _showHint = false;
  final List<Offset?> _points = <Offset?>[];

  @override
  void initState() {
    super.initState();
    final source =
        widget.state.contentItems.where((item) => item.kind == 'kana').toList(
              growable: true,
            );

    if (source.isEmpty) {
      _kanaItems = const [
        ContentItem(
          id: 'h_a',
          kind: 'kana',
          jlptLevel: 'N5',
          jp: 'あ',
          reading: 'a',
          meaningKo: '히라가나 a',
        ),
        ContentItem(
          id: 'h_i',
          kind: 'kana',
          jlptLevel: 'N5',
          jp: 'い',
          reading: 'i',
          meaningKo: '히라가나 i',
        ),
        ContentItem(
          id: 'h_u',
          kind: 'kana',
          jlptLevel: 'N5',
          jp: 'う',
          reading: 'u',
          meaningKo: '히라가나 u',
        ),
        ContentItem(
          id: 'k_a',
          kind: 'kana',
          jlptLevel: 'N5',
          jp: 'ア',
          reading: 'a',
          meaningKo: '가타카나 a',
        ),
        ContentItem(
          id: 'k_i',
          kind: 'kana',
          jlptLevel: 'N5',
          jp: 'イ',
          reading: 'i',
          meaningKo: '가타카나 i',
        ),
        ContentItem(
          id: 'k_u',
          kind: 'kana',
          jlptLevel: 'N5',
          jp: 'ウ',
          reading: 'u',
          meaningKo: '가타카나 u',
        ),
      ];
    } else {
      source.shuffle(_random);
      _kanaItems = source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _kanaItems[_index];
    final guide = _strokeGuideByKana[item.jp];

    return Scaffold(
      appBar: AppBar(
        title: const Text('문자 쓰기 연습'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF6EC), Color(0xFFEFF8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '제시 문자',
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  item.jp,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _showHint
                      ? '읽기: ${item.reading} · ${item.meaningKo}'
                      : '힌트를 눌러 읽기를 확인하세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (guide != null && guide.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '획 순서 가이드: ${guide.length}획',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                const SizedBox(height: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _points.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: _WritingPainter(
                          points: _points,
                          strokeGuide: guide,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clear,
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('지우기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showHint = !_showHint;
                          });
                        },
                        icon: const Icon(Icons.lightbulb_outline),
                        label: Text(_showHint ? '힌트 숨기기' : '힌트'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('다음'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  void _next() {
    if (_kanaItems.length <= 1) {
      _clear();
      return;
    }

    int next = _index;
    while (next == _index) {
      next = _random.nextInt(_kanaItems.length);
    }

    setState(() {
      _index = next;
      _showHint = false;
      _points.clear();
    });
  }
}

class _WritingPainter extends CustomPainter {
  const _WritingPainter({
    required this.points,
    required this.strokeGuide,
  });

  final List<Offset?> points;
  final List<List<Offset>>? strokeGuide;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = const Color(0xFFE8ECF2)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      grid,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      grid,
    );

    final border = Paint()
      ..color = const Color(0xFFD7DEE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(Offset.zero & size, border);

    _paintGuides(canvas, size);

    final stroke = Paint()
      ..color = const Color(0xFF1F2A37)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, stroke);
      }
    }
  }

  void _paintGuides(Canvas canvas, Size size) {
    if (strokeGuide == null || strokeGuide!.isEmpty) {
      return;
    }

    final textStyle = const TextStyle(
      color: Color(0xFF5F6F86),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    for (var i = 0; i < strokeGuide!.length; i++) {
      final points = strokeGuide![i]
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList(growable: false);

      final guide = Paint()
        ..color = const Color(0xFFA9BCD8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (var j = 0; j < points.length - 1; j++) {
        canvas.drawLine(points[j], points[j + 1], guide);
      }

      final dot = Paint()..color = const Color(0xFF7FA3D1);
      canvas.drawCircle(points.first, 4, dot);

      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, points.first + const Offset(6, -12));
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPainter oldDelegate) {
    return true;
  }
}

const Map<String, List<List<Offset>>> _strokeGuideByKana = {
  'あ': [
    [Offset(0.24, 0.23), Offset(0.58, 0.19)],
    [Offset(0.43, 0.14), Offset(0.41, 0.81)],
    [
      Offset(0.55, 0.37),
      Offset(0.7, 0.44),
      Offset(0.62, 0.7),
      Offset(0.36, 0.67),
    ],
  ],
  'い': [
    [Offset(0.36, 0.32), Offset(0.34, 0.74)],
    [Offset(0.58, 0.3), Offset(0.56, 0.78)],
  ],
  'う': [
    [Offset(0.32, 0.24), Offset(0.62, 0.24)],
    [Offset(0.5, 0.31), Offset(0.5, 0.39)],
    [
      Offset(0.3, 0.5),
      Offset(0.68, 0.48),
      Offset(0.6, 0.77),
      Offset(0.4, 0.8),
    ],
  ],
  'ア': [
    [Offset(0.3, 0.26), Offset(0.68, 0.22)],
    [Offset(0.58, 0.24), Offset(0.43, 0.79)],
  ],
  'イ': [
    [Offset(0.4, 0.24), Offset(0.34, 0.5)],
    [Offset(0.58, 0.2), Offset(0.54, 0.79)],
  ],
  'ウ': [
    [Offset(0.32, 0.25), Offset(0.66, 0.25)],
    [Offset(0.5, 0.25), Offset(0.5, 0.37)],
    [Offset(0.36, 0.39), Offset(0.66, 0.39), Offset(0.58, 0.78)],
  ],
};

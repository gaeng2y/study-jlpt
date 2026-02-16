import 'dart:math' as math;

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 72.0 : 96.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: CustomPaint(
            painter: _BrandPainter(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '일어톡톡',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            '매일 10분, JLPT 루틴',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF596E86),
                ),
          ),
        ],
      ],
    );
  }
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5DA1FF), Color(0xFF56D7C5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center, width: size.width * 0.72, height: size.height * 0.82),
      const Radius.circular(22),
    );
    canvas.drawRRect(cardRect, bg);

    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.95);
    final bubbleR = size.width * 0.16;
    canvas.drawCircle(
        Offset(size.width * 0.38, size.height * 0.38), bubbleR, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.62),
        bubbleR * 0.9, bubblePaint);

    final textStyle = TextStyle(
      color: const Color(0xFF2A6EEC),
      fontSize: size.width * 0.18,
      fontWeight: FontWeight.w900,
    );

    final tp1 = TextPainter(
      text: TextSpan(text: 'あ', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(size.width * 0.32, size.height * 0.29));

    final tp2 = TextPainter(
      text: TextSpan(
        text: 'ト',
        style: textStyle.copyWith(color: const Color(0xFF0D8B7C)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(size.width * 0.56, size.height * 0.53));

    final glow = Paint()
      ..color = const Color(0x66FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
        Offset(size.width * 0.24, size.height * 0.2), size.width * 0.08, glow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x80FFFFFF);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.44),
      -math.pi * 0.35,
      math.pi * 0.7,
      false,
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

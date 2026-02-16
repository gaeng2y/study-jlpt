import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate app icon png', () async {
    const size = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    final iconSize = const Size(size, size);

    final center = Offset(size / 2, size / 2);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5DA1FF), Color(0xFF56D7C5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & iconSize);

    final base = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size * 0.72,
        height: size * 0.82,
      ),
      const Radius.circular(220),
    );
    canvas.drawRRect(base, bgPaint);

    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.95);
    final bubbleR = size * 0.16;
    canvas.drawCircle(Offset(size * 0.38, size * 0.38), bubbleR, bubblePaint);
    canvas.drawCircle(
      Offset(size * 0.62, size * 0.62),
      bubbleR * 0.9,
      bubblePaint,
    );

    final textStyle = TextStyle(
      color: const Color(0xFF2A6EEC),
      fontSize: size * 0.18,
      fontWeight: FontWeight.w900,
    );

    final tp1 = TextPainter(
      text: TextSpan(text: 'あ', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(size * 0.32, size * 0.29));

    final tp2 = TextPainter(
      text: TextSpan(
        text: 'ト',
        style: textStyle.copyWith(color: const Color(0xFF0D8B7C)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(size * 0.56, size * 0.53));

    final glow = Paint()
      ..color = const Color(0x66FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(size * 0.24, size * 0.2), size * 0.08, glow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.02
      ..color = const Color(0x80FFFFFF);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size * 0.44),
      -math.pi * 0.35,
      math.pi * 0.7,
      false,
      ring,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();

    final output = File('assets/app_icon_source.png');
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(Uint8List.fromList(bytes), flush: true);
  });
}

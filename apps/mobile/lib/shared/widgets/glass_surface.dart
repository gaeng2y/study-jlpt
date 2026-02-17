import 'dart:ui';

import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: 0.34),
                const Color(0xFFEDF2FF).withValues(alpha: 0.20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D1C4A).withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: IconTheme.merge(
              data: const IconThemeData(color: Color(0xFF1B2A55)),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Color(0xFF13203F)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

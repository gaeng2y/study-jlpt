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
        ClipRRect(
          borderRadius: BorderRadius.circular(iconSize * 0.24),
          child: Image.asset(
            'assets/icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
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

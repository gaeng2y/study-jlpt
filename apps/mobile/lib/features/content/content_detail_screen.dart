import 'package:flutter/material.dart';

import '../../core/models/content_item.dart';
import '../../shared/widgets/glass_surface.dart';

class ContentDetailScreen extends StatelessWidget {
  const ContentDetailScreen({super.key, required this.item});

  final ContentItem item;

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    Text(
                      '콘텐츠 상세',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isIos
                      ? GlassSurface(child: _DetailBody(item: item))
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _DetailBody(item: item),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Chip(label: Text(item.kind)),
            const SizedBox(width: 8),
            Chip(label: Text(item.jlptLevel)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          item.jp,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(item.reading, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(item.meaningKo, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

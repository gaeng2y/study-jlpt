import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/content_item.dart';
import '../../shared/app_state.dart';
import '../../shared/widgets/glass_surface.dart';
import 'content_detail_screen.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String _query = '';
  String? _level;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final items = widget.state.contentItems;

        return Scaffold(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TopHeader(isIos: isIos, title: '콘텐츠'),
                    const SizedBox(height: 10),
                    _SearchField(
                      isIos: isIos,
                      onChanged: (value) {
                        _query = value;
                        widget.state.searchContentWithLevel(
                          query: _query,
                          jlptLevel: _level,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _LevelFilter(
                      selected: _level,
                      onChanged: (level) {
                        setState(() => _level = level);
                        widget.state.searchContentWithLevel(
                          query: _query,
                          jlptLevel: _level,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _ContentTile(
                            item: item,
                            isIos: isIos,
                            onTap: () => _open(item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _open(ContentItem item) {
    unawaited(widget.state.trackContentOpened(item));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(item: item),
      ),
    );
  }
}

class _LevelFilter extends StatelessWidget {
  const _LevelFilter({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final levels = <String?>[null, 'N5', 'N4', 'N3', 'N2', 'N1'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = levels[index];
          final label = level ?? '전체';
          return ChoiceChip(
            label: Text(label),
            selected: selected == level,
            onSelected: (_) => onChanged(level),
          );
        },
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.isIos, required this.title});

  final bool isIos;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (!isIos) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      );
    }

    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged, required this.isIos});

  final ValueChanged<String> onChanged;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      decoration: InputDecoration(
        hintText: '단어/읽기/뜻 검색',
        prefixIcon: const Icon(Icons.search),
      ),
      onChanged: onChanged,
    );

    return isIos ? GlassSurface(radius: 18, child: field) : field;
  }
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({
    required this.item,
    required this.onTap,
    required this.isIos,
  });

  final ContentItem item;
  final VoidCallback onTap;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      tileColor: isIos ? Colors.transparent : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: isIos ? const Color(0x80FFFFFF) : const Color(0xFFE8E1D7)),
      ),
      title: Text('${item.jp} (${item.reading})'),
      subtitle: Text(item.meaningKo),
      trailing: Chip(label: Text(item.kind)),
      onTap: onTap,
    );

    if (!isIos) {
      return tile;
    }

    return GlassSurface(
      radius: 16,
      padding: EdgeInsets.zero,
      child: tile,
    );
  }
}

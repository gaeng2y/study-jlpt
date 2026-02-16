class ContentItem {
  const ContentItem({
    required this.id,
    required this.kind,
    required this.jlptLevel,
    required this.jp,
    required this.reading,
    required this.meaningKo,
  });

  final String id;
  final String kind;
  final String jlptLevel;
  final String jp;
  final String reading;
  final String meaningKo;
}

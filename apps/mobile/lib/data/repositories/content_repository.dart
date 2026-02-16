import '../../core/models/content_item.dart';

abstract class ContentRepository {
  Future<List<ContentItem>> listAll();
  Future<List<ContentItem>> search(String query, {String? jlptLevel});
}

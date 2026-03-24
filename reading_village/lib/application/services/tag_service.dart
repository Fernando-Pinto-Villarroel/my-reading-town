import 'package:reading_village/domain/entities/tag.dart';
import 'package:reading_village/domain/ports/book_repository.dart';

class TagService {
  final BookRepository _repo;
  TagService(this._repo);

  Future<List<Tag>> loadTags() async {
    final maps = await _repo.getTags();
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  Future<Tag> addTag(String title, int colorValue) async {
    final id = await _repo.insertTag({'title': title, 'color_value': colorValue});
    return Tag(id: id, title: title, colorValue: colorValue);
  }

  Future<void> updateTag(int tagId, String title, int colorValue) async {
    await _repo.updateTag(tagId, {'title': title, 'color_value': colorValue});
  }

  Future<void> deleteTag(int tagId) async {
    await _repo.deleteTag(tagId);
  }
}

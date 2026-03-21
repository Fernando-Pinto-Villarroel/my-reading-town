import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/tag.dart';

class TagProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Tag> _tags = [];
  List<Tag> get tags => _tags;

  Future<void> loadTags() async {
    final maps = await _db.getTags();
    _tags = maps.map((m) => Tag.fromMap(m)).toList();
    notifyListeners();
  }

  Future<Tag> addTag(String title, int colorValue) async {
    final id = await _db.insertTag({'title': title, 'color_value': colorValue});
    final tag = Tag(id: id, title: title, colorValue: colorValue);
    _tags.add(tag);
    _tags.sort((a, b) => a.title.compareTo(b.title));
    notifyListeners();
    return tag;
  }

  Future<void> updateTag(int tagId, String title, int colorValue) async {
    await _db.updateTag(tagId, {'title': title, 'color_value': colorValue});
    final idx = _tags.indexWhere((t) => t.id == tagId);
    if (idx != -1) {
      _tags[idx] = _tags[idx].copyWith(title: title, colorValue: colorValue);
      _tags.sort((a, b) => a.title.compareTo(b.title));
    }
    notifyListeners();
  }

  Future<void> deleteTag(int tagId) async {
    await _db.deleteTag(tagId);
    _tags.removeWhere((t) => t.id == tagId);
    notifyListeners();
  }
}

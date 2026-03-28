import 'package:flutter/material.dart';
import 'package:my_reading_town/domain/entities/tag.dart';
import 'package:my_reading_town/application/services/tag_service.dart';

class TagProvider extends ChangeNotifier {
  final TagService _tagSvc;
  TagProvider(this._tagSvc);

  List<Tag> _tags = [];
  List<Tag> get tags => _tags;

  Future<void> loadTags() async {
    _tags = await _tagSvc.loadTags();
    notifyListeners();
  }

  Future<Tag> addTag(String title, int colorValue) async {
    final tag = await _tagSvc.addTag(title, colorValue);
    _tags.add(tag);
    _tags.sort((a, b) => a.title.compareTo(b.title));
    notifyListeners();
    return tag;
  }

  Future<void> updateTag(int tagId, String title, int colorValue) async {
    await _tagSvc.updateTag(tagId, title, colorValue);
    final idx = _tags.indexWhere((t) => t.id == tagId);
    if (idx != -1) {
      _tags[idx] = _tags[idx].copyWith(title: title, colorValue: colorValue);
      _tags.sort((a, b) => a.title.compareTo(b.title));
    }
    notifyListeners();
  }

  Future<void> deleteTag(int tagId) async {
    await _tagSvc.deleteTag(tagId);
    _tags.removeWhere((t) => t.id == tagId);
    notifyListeners();
  }
}

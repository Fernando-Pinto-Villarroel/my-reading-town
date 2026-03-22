import 'dart:convert';
import 'package:flutter/services.dart';

class VillagerFavorites {
  static List<Map<String, String>> _favorites = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/data/villager_favorites.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _favorites = (data['favorites'] as List)
        .map((e) => {
              'author': e['author'] as String,
              'quote': e['quote'] as String,
            })
        .toList();
    _loaded = true;
  }

  static int get length => _favorites.length;

  static String author(int index) {
    if (_favorites.isEmpty) return '';
    return _favorites[index % _favorites.length]['author']!;
  }

  static String quote(int index) {
    if (_favorites.isEmpty) return '';
    return _favorites[index % _favorites.length]['quote']!;
  }
}

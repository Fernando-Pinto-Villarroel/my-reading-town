import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleBookResult {
  final String title;
  final String? author;
  final int? pageCount;
  final String? thumbnailUrl;
  final List<String> categories;

  GoogleBookResult({
    required this.title,
    this.author,
    this.pageCount,
    this.thumbnailUrl,
    this.categories = const [],
  });
}

class GoogleBooksService {
  static const _baseUrl = 'https://openlibrary.org/search.json';

  static Future<List<GoogleBookResult>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl?q=${Uri.encodeQueryComponent(query)}&limit=15&fields=title,author_name,number_of_pages_median,cover_i,subject');
    final http.Response response;
    try {
      response = await http.get(uri).timeout(Duration(seconds: 10));
    } catch (e) {
      throw GoogleBooksException('Network error: $e');
    }

    if (response.statusCode >= 400) {
      throw GoogleBooksException('API error (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = json['docs'] as List<dynamic>? ?? [];

    return docs.map((doc) {
      final map = doc as Map<String, dynamic>;
      final authors = map['author_name'] as List<dynamic>?;
      final coverId = map['cover_i'] as int?;
      final thumbnailUrl = coverId != null
          ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
          : null;
      final subjects = map['subject'] as List<dynamic>?;

      return GoogleBookResult(
        title: map['title'] as String? ?? 'Unknown',
        author: authors?.isNotEmpty == true ? authors!.join(', ') : null,
        pageCount: map['number_of_pages_median'] as int?,
        thumbnailUrl: thumbnailUrl,
        categories: subjects?.take(3).map((s) => s.toString()).toList() ?? [],
      );
    }).toList();
  }
}

class GoogleBooksException implements Exception {
  final String message;
  GoogleBooksException(this.message);
  @override
  String toString() => message;
}

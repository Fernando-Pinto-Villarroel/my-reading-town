class BookSearchResult {
  final String title;
  final String? author;
  final int? pageCount;
  final String? thumbnailUrl;
  final List<String> categories;

  const BookSearchResult({
    required this.title,
    this.author,
    this.pageCount,
    this.thumbnailUrl,
    this.categories = const [],
  });
}

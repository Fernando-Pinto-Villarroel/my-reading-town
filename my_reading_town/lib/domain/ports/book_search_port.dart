import '../entities/book_search_result.dart';

abstract class BookSearchPort {
  Future<List<BookSearchResult>> searchBooks(String query);
}

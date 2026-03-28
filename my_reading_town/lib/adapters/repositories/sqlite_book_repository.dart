import 'package:my_reading_town/infrastructure/persistence/database_helper.dart';
import 'package:my_reading_town/domain/ports/book_repository.dart';

class SqliteBookRepository implements BookRepository {
  final DatabaseHelper _db;
  SqliteBookRepository(this._db);

  @override
  Future<List<Map<String, dynamic>>> getBooks() => _db.getBooks();

  @override
  Future<int> insertBook(Map<String, dynamic> book) => _db.insertBook(book);

  @override
  Future<void> updateBookPages(
          int bookId, int newPagesRead, bool isCompleted) =>
      _db.updateBookPages(bookId, newPagesRead, isCompleted);

  @override
  Future<void> updateMaxRewardedPages(int bookId, int maxRewardedPages) =>
      _db.updateMaxRewardedPages(bookId, maxRewardedPages);

  @override
  Future<void> updateBook(int bookId, Map<String, dynamic> values) =>
      _db.updateBook(bookId, values);

  @override
  Future<void> deleteBook(int bookId) => _db.deleteBook(bookId);

  @override
  Future<int> getCompletedBooksCount() => _db.getCompletedBooksCount();

  @override
  Future<int> insertReadingSession(Map<String, dynamic> session) =>
      _db.insertReadingSession(session);

  @override
  Future<List<Map<String, dynamic>>> getReadingSessions() =>
      _db.getReadingSessions();

  @override
  Future<List<Map<String, dynamic>>> getSessionsForBook(int bookId) =>
      _db.getSessionsForBook(bookId);

  @override
  Future<void> updateReadingSession(
          int sessionId, Map<String, dynamic> values) =>
      _db.updateReadingSession(sessionId, values);

  @override
  Future<void> deleteReadingSession(int sessionId) =>
      _db.deleteReadingSession(sessionId);

  @override
  Future<int> sumSessionPagesForBook(int bookId) =>
      _db.sumSessionPagesForBook(bookId);

  @override
  Future<int> getTotalPagesRead() => _db.getTotalPagesRead();

  @override
  Future<int> getTotalSessionsCount() => _db.getTotalSessionsCount();

  @override
  Future<int> getTotalTimeMinutes() => _db.getTotalTimeMinutes();

  @override
  Future<List<Map<String, dynamic>>> getTags() => _db.getTags();

  @override
  Future<int> insertTag(Map<String, dynamic> tag) => _db.insertTag(tag);

  @override
  Future<void> updateTag(int tagId, Map<String, dynamic> values) =>
      _db.updateTag(tagId, values);

  @override
  Future<void> deleteTag(int tagId) => _db.deleteTag(tagId);

  @override
  Future<List<Map<String, dynamic>>> getBookTags(int bookId) =>
      _db.getBookTags(bookId);

  @override
  Future<void> setBookTags(int bookId, List<int> tagIds) =>
      _db.setBookTags(bookId, tagIds);
}

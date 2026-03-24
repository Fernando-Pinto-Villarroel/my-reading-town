import 'package:reading_village/infrastructure/persistence/database_helper.dart';
import 'package:reading_village/domain/ports/book_repository.dart';

class SqliteBookRepository implements BookRepository {
  final DatabaseHelper _db;
  SqliteBookRepository(this._db);

  @override
  Future<List<Map<String, dynamic>>> getBooks() => _db.getBooks();

  @override
  Future<int> insertBook(Map<String, dynamic> book) => _db.insertBook(book);

  @override
  Future<void> updateBookPages(int bookId, int newPagesRead, bool isCompleted) =>
      _db.updateBookPages(bookId, newPagesRead, isCompleted);

  @override
  Future<void> updateBook(int bookId, Map<String, dynamic> values) => _db.updateBook(bookId, values);

  @override
  Future<void> deleteBook(int bookId) => _db.deleteBook(bookId);

  @override
  Future<int> getCompletedBooksCount() => _db.getCompletedBooksCount();

  @override
  Future<int> insertReadingSession(Map<String, dynamic> session) => _db.insertReadingSession(session);

  @override
  Future<List<Map<String, dynamic>>> getReadingSessions() => _db.getReadingSessions();

  @override
  Future<int> getTotalPagesRead() => _db.getTotalPagesRead();

  @override
  Future<int> getTotalSessionsCount() => _db.getTotalSessionsCount();

  @override
  Future<List<Map<String, dynamic>>> getTags() => _db.getTags();

  @override
  Future<int> insertTag(Map<String, dynamic> tag) => _db.insertTag(tag);

  @override
  Future<void> updateTag(int tagId, Map<String, dynamic> values) => _db.updateTag(tagId, values);

  @override
  Future<void> deleteTag(int tagId) => _db.deleteTag(tagId);

  @override
  Future<List<Map<String, dynamic>>> getBookTags(int bookId) => _db.getBookTags(bookId);

  @override
  Future<void> setBookTags(int bookId, List<int> tagIds) => _db.setBookTags(bookId, tagIds);
}

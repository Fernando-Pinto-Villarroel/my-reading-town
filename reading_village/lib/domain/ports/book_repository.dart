abstract class BookRepository {
  Future<List<Map<String, dynamic>>> getBooks();
  Future<int> insertBook(Map<String, dynamic> book);
  Future<void> updateBookPages(int bookId, int newPagesRead, bool isCompleted);
  Future<void> updateBook(int bookId, Map<String, dynamic> values);
  Future<void> deleteBook(int bookId);
  Future<int> getCompletedBooksCount();
  Future<int> insertReadingSession(Map<String, dynamic> session);
  Future<List<Map<String, dynamic>>> getReadingSessions();
  Future<int> getTotalPagesRead();
  Future<int> getTotalSessionsCount();
  Future<List<Map<String, dynamic>>> getTags();
  Future<int> insertTag(Map<String, dynamic> tag);
  Future<void> updateTag(int tagId, Map<String, dynamic> values);
  Future<void> deleteTag(int tagId);
  Future<List<Map<String, dynamic>>> getBookTags(int bookId);
  Future<void> setBookTags(int bookId, List<int> tagIds);
}

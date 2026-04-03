part of 'database_helper.dart';

extension DatabaseHelperBookOperations on DatabaseHelper {
  Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await database;
    return db.query('books', orderBy: 'created_at DESC');
  }

  Future<int> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    return db.insert('books', book);
  }

  Future<void> updateBookPages(int bookId, int newPagesRead, bool isCompleted) async {
    final db = await database;
    await db.update('books',
        {'pages_read': newPagesRead, 'is_completed': isCompleted ? 1 : 0},
        where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> updateMaxRewardedPages(int bookId, int maxRewardedPages) async {
    final db = await database;
    await db.update('books', {'max_rewarded_pages': maxRewardedPages},
        where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> updateBook(int bookId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('books', values, where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> updateBookRating(int bookId, int? rating) async {
    final db = await database;
    await db.update('books', {'rating': rating}, where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> deleteBook(int bookId) async {
    final db = await database;
    await db.delete('book_tags', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('reading_sessions', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  Future<int> getCompletedBooksCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM books WHERE is_completed = 1');
    return result.first['count'] as int;
  }

  Future<int> insertReadingSession(Map<String, dynamic> session) async {
    final db = await database;
    return db.insert('reading_sessions', session);
  }

  Future<List<Map<String, dynamic>>> getReadingSessions() async {
    final db = await database;
    return db.query('reading_sessions', orderBy: 'date DESC');
  }

  Future<int> getTotalPagesRead() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(pages_read), 0) as total FROM reading_sessions');
    return result.first['total'] as int;
  }

  Future<int> getTotalSessionsCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM reading_sessions');
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getSessionsForBook(int bookId) async {
    final db = await database;
    return db.query('reading_sessions',
        where: 'book_id = ?', whereArgs: [bookId], orderBy: 'date DESC');
  }

  Future<void> updateReadingSession(int sessionId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('reading_sessions', values, where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> deleteReadingSession(int sessionId) async {
    final db = await database;
    await db.delete('reading_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<int> sumSessionPagesForBook(int bookId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(pages_read), 0) as total FROM reading_sessions WHERE book_id = ?',
        [bookId]);
    return result.first['total'] as int;
  }

  Future<int> getTodayPagesRead() async {
    return getPagesReadForDate(DateTime.now());
  }

  Future<int> getPagesReadForDate(DateTime date, {int? excludingSessionId}) async {
    final db = await database;
    final datePrefix =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final result = excludingSessionId != null
        ? await db.rawQuery(
            "SELECT COALESCE(SUM(pages_read), 0) as total FROM reading_sessions WHERE date LIKE ? AND id != ?",
            ['$datePrefix%', excludingSessionId],
          )
        : await db.rawQuery(
            "SELECT COALESCE(SUM(pages_read), 0) as total FROM reading_sessions WHERE date LIKE ?",
            ['$datePrefix%'],
          );
    return result.first['total'] as int;
  }

  Future<int> getTotalTimeMinutes() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(time_taken_minutes), 0) as total FROM reading_sessions WHERE time_taken_minutes IS NOT NULL');
    return result.first['total'] as int;
  }

  Future<List<Map<String, dynamic>>> getTags() async {
    final db = await database;
    return db.query('tags', orderBy: 'title ASC');
  }

  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    return db.insert('tags', tag);
  }

  Future<void> updateTag(int tagId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('tags', values, where: 'id = ?', whereArgs: [tagId]);
  }

  Future<void> deleteTag(int tagId) async {
    final db = await database;
    await db.delete('book_tags', where: 'tag_id = ?', whereArgs: [tagId]);
    await db.delete('tags', where: 'id = ?', whereArgs: [tagId]);
  }

  Future<List<Map<String, dynamic>>> getBookTags(int bookId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN book_tags bt ON bt.tag_id = t.id
      WHERE bt.book_id = ?
      ORDER BY t.title ASC
    ''', [bookId]);
  }

  Future<void> setBookTags(int bookId, List<int> tagIds) async {
    final db = await database;
    await db.delete('book_tags', where: 'book_id = ?', whereArgs: [bookId]);
    for (final tagId in tagIds) {
      await db.insert('book_tags', {'book_id': bookId, 'tag_id': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}

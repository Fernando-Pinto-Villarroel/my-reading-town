import 'dart:math';
import 'package:reading_village/domain/entities/book.dart';
import 'package:reading_village/domain/entities/reading_session.dart';
import 'package:reading_village/domain/entities/tag.dart';
import 'package:reading_village/domain/ports/book_repository.dart';
import 'package:reading_village/domain/rules/village_rules.dart';

class ReadingService {
  final BookRepository _repo;
  ReadingService(this._repo);

  Future<List<Book>> loadBooks() async {
    final bookMaps = await _repo.getBooks();
    final books = bookMaps.map((m) => Book.fromMap(m)).toList();

    for (int i = 0; i < books.length; i++) {
      if (books[i].id != null) {
        final tagMaps = await _repo.getBookTags(books[i].id!);
        books[i].tags = tagMaps.map((m) => Tag.fromMap(m)).toList();
      }
    }
    return books;
  }

  Future<List<ReadingSession>> loadSessions() async {
    final sessionMaps = await _repo.getReadingSessions();
    return sessionMaps.map((m) => ReadingSession.fromMap(m)).toList();
  }

  Future<List<ReadingSession>> getSessionsForBook(int bookId) async {
    final maps = await _repo.getSessionsForBook(bookId);
    return maps.map((m) => ReadingSession.fromMap(m)).toList();
  }

  Future<Book> addBook({
    required String title,
    required int totalPages,
    String? author,
    String? coverImagePath,
    List<int>? tagIds,
  }) async {
    final book = Book(
      title: title,
      author: author,
      totalPages: totalPages,
      coverImagePath: coverImagePath,
    );
    final id = await _repo.insertBook(book.toMap());

    if (tagIds != null && tagIds.isNotEmpty) {
      await _repo.setBookTags(id, tagIds);
    }

    final tagMaps = await _repo.getBookTags(id);
    final tags = tagMaps.map((m) => Tag.fromMap(m)).toList();
    return book.copyWith(id: id, tags: tags);
  }

  Future<Book> updateBookDetails({
    required int bookId,
    required List<Book> books,
    String? title,
    String? author,
    bool clearAuthor = false,
    int? totalPages,
    String? coverImagePath,
    bool removeCover = false,
    List<int>? tagIds,
    Future<void> Function(String)? deleteImage,
  }) async {
    final idx = books.indexWhere((b) => b.id == bookId);
    if (idx == -1) throw Exception('Book not found');

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (author != null) {
      updates['author'] = author;
    } else if (clearAuthor) {
      updates['author'] = null;
    }
    if (totalPages != null) updates['total_pages'] = totalPages;
    if (coverImagePath != null) updates['cover_image_path'] = coverImagePath;
    if (removeCover) {
      final oldPath = books[idx].coverImagePath;
      if (oldPath != null && deleteImage != null) await deleteImage(oldPath);
      updates['cover_image_path'] = null;
    }

    if (updates.isNotEmpty) {
      await _repo.updateBook(bookId, updates);
    }
    if (tagIds != null) {
      await _repo.setBookTags(bookId, tagIds);
    }

    final bookMaps = await _repo.getBooks();
    final bookMap = bookMaps.firstWhere((m) => m['id'] == bookId);
    final updatedBook = Book.fromMap(bookMap);
    final tagMaps = await _repo.getBookTags(bookId);
    updatedBook.tags = tagMaps.map((m) => Tag.fromMap(m)).toList();
    return updatedBook;
  }

  Future<void> deleteBook(int bookId, List<Book> books,
      {Future<void> Function(String)? deleteImage}) async {
    final idx = books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    final book = books[idx];
    if (book.coverImagePath != null && deleteImage != null) {
      await deleteImage(book.coverImagePath!);
    }
    await _repo.deleteBook(bookId);
  }

  Future<void> refreshBookTags(List<Book> books) async {
    for (int i = 0; i < books.length; i++) {
      if (books[i].id != null) {
        final tagMaps = await _repo.getBookTags(books[i].id!);
        books[i].tags = tagMaps.map((m) => Tag.fromMap(m)).toList();
      }
    }
  }

  Future<Map<String, dynamic>> logPages(int bookId, int pages, List<Book> books,
      {int? timeTakenMinutes}) async {
    final bookIndex = books.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) throw Exception('Book not found');

    final book = books[bookIndex];
    final newPagesRead = (book.pagesRead + pages).clamp(0, book.totalPages);
    final actualPagesLogged = newPagesRead - book.pagesRead;

    if (actualPagesLogged <= 0) {
      return {'coins': 0, 'gems': 0, 'wood': 0, 'metal': 0, 'exp': 0, 'bookCompleted': false};
    }

    final rewardablePages = (newPagesRead - book.maxRewardedPages).clamp(0, actualPagesLogged);

    final random = Random();
    int coinsEarned = rewardablePages * VillageRules.coinsPerPage;
    int gemsEarned = 0;
    int woodEarned = 0;
    int metalEarned = 0;

    if (rewardablePages > 0) {
      if (rewardablePages >= 10) {
        woodEarned = rewardablePages * VillageRules.woodPerPage;
        metalEarned = rewardablePages * VillageRules.metalPerPage;
      } else {
        if (random.nextBool()) {
          woodEarned = rewardablePages * VillageRules.woodPerPage;
        } else {
          metalEarned = rewardablePages * VillageRules.metalPerPage;
        }
      }
    }

    bool bookCompleted = newPagesRead >= book.totalPages;
    final completionBonusEarned = bookCompleted && book.maxRewardedPages < book.totalPages;
    if (completionBonusEarned) {
      coinsEarned += VillageRules.bookCompletionCoinBonus;
      gemsEarned += VillageRules.bookCompletionGemBonus;
    }

    final newMaxRewarded = max(book.maxRewardedPages, newPagesRead);

    await _repo.updateBookPages(bookId, newPagesRead, bookCompleted);
    await _repo.updateMaxRewardedPages(bookId, newMaxRewarded);
    await _repo.insertReadingSession(ReadingSession(
      bookId: bookId,
      pagesRead: actualPagesLogged,
      coinsEarned: coinsEarned,
      gemsEarned: gemsEarned,
      woodEarned: woodEarned,
      metalEarned: metalEarned,
      timeTakenMinutes: timeTakenMinutes,
    ).toMap());

    return {
      'coins': coinsEarned,
      'gems': gemsEarned,
      'wood': woodEarned,
      'metal': metalEarned,
      'exp': 0,
      'bookCompleted': completionBonusEarned,
      'newPagesRead': newPagesRead,
      'rewardablePages': rewardablePages,
      'newMaxRewarded': newMaxRewarded,
    };
  }

  Future<Book> editSession(
      int sessionId, int bookId, int newPages, int? newTimeMins, List<Book> books) async {
    final bookIdx = books.indexWhere((b) => b.id == bookId);
    if (bookIdx == -1) throw Exception('Book not found');
    final book = books[bookIdx];

    final allSessions = await _repo.getSessionsForBook(bookId);
    final otherPagesSum =
        allSessions.where((s) => s['id'] != sessionId).fold<int>(0, (sum, s) => sum + (s['pages_read'] as int));

    if (otherPagesSum + newPages > book.totalPages) {
      throw Exception('Total pages would exceed book total (${book.totalPages})');
    }

    await _repo.updateReadingSession(sessionId, {
      'pages_read': newPages,
      'time_taken_minutes': newTimeMins,
    });

    final newPagesRead = otherPagesSum + newPages;
    final isCompleted = newPagesRead >= book.totalPages;
    await _repo.updateBookPages(bookId, newPagesRead, isCompleted);

    return book.copyWith(pagesRead: newPagesRead, isCompleted: isCompleted);
  }

  Future<Book> deleteSession(int sessionId, int bookId, List<Book> books) async {
    final bookIdx = books.indexWhere((b) => b.id == bookId);
    if (bookIdx == -1) throw Exception('Book not found');
    final book = books[bookIdx];

    await _repo.deleteReadingSession(sessionId);

    final newPagesRead = await _repo.sumSessionPagesForBook(bookId);
    final isCompleted = newPagesRead >= book.totalPages;
    await _repo.updateBookPages(bookId, newPagesRead, isCompleted);

    return book.copyWith(pagesRead: newPagesRead, isCompleted: isCompleted);
  }

  Future<int> getTotalPagesRead() => _repo.getTotalPagesRead();
  Future<int> getCompletedBooksCount() => _repo.getCompletedBooksCount();
  Future<int> getTotalSessionsCount() => _repo.getTotalSessionsCount();
  Future<int> getTotalTimeMinutes() => _repo.getTotalTimeMinutes();
}

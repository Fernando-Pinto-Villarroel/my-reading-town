import 'package:flutter/material.dart';
import 'package:my_reading_town/domain/entities/book.dart';
import 'package:my_reading_town/domain/entities/book_filter.dart';
import 'package:my_reading_town/domain/entities/reading_session.dart';
import 'package:my_reading_town/domain/ports/image_port.dart';
import 'package:my_reading_town/application/services/reading_service.dart';

class BookProvider extends ChangeNotifier {
  final ReadingService _readingSvc;
  final ImagePort _imagePort;

  BookProvider(this._readingSvc, this._imagePort);

  List<Book> _books = [];
  List<ReadingSession> _sessions = [];
  BookFilter _filter = const BookFilter();

  List<Book> get books => _books;
  List<Book> get activeBooks => _books.where((b) => !b.isCompleted).toList();
  List<Book> get completedBooks => _books.where((b) => b.isCompleted).toList();
  List<ReadingSession> get sessions => _sessions;
  BookFilter get filter => _filter;

  List<ReadingSession> sessionsForBook(int bookId) {
    final list = _sessions.where((s) => s.bookId == bookId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Book> get filteredBooks {
    var result = List<Book>.from(_books);

    if (_filter.showCompleted == true) {
      result = result.where((b) => b.isCompleted).toList();
    } else if (_filter.showCompleted == false) {
      result = result.where((b) => !b.isCompleted).toList();
    }

    final q = _filter.searchQuery?.toLowerCase().trim();
    if (q != null && q.isNotEmpty) {
      result = result.where((b) {
        return b.title.toLowerCase().contains(q) ||
            (b.author?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_filter.selectedTagIds.isNotEmpty) {
      result = result.where((b) {
        return b.tags.any((t) => _filter.selectedTagIds.contains(t.id));
      }).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (_filter.sortField) {
        case BookSortField.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case BookSortField.pagesLeft:
          cmp = (a.totalPages - a.pagesRead)
              .compareTo(b.totalPages - b.pagesRead);
          break;
        case BookSortField.dateAdded:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case BookSortField.author:
          cmp = (a.author ?? '')
              .toLowerCase()
              .compareTo((b.author ?? '').toLowerCase());
          break;
      }
      return _filter.sortDirection == BookSortDirection.ascending ? cmp : -cmp;
    });

    return result;
  }

  void setFilter(BookFilter f) {
    _filter = f;
    notifyListeners();
  }

  Future<void> loadData() async {
    _books = await _readingSvc.loadBooks();
    _sessions = await _readingSvc.loadSessions();
    notifyListeners();
  }

  Future<Book> addBook({
    required String title,
    required int totalPages,
    String? author,
    String? coverImagePath,
    List<int>? tagIds,
  }) async {
    final savedBook = await _readingSvc.addBook(
      title: title,
      totalPages: totalPages,
      author: author,
      coverImagePath: coverImagePath,
      tagIds: tagIds,
    );
    _books.insert(0, savedBook);
    notifyListeners();
    return savedBook;
  }

  Future<void> updateBookDetails({
    required int bookId,
    String? title,
    String? author,
    bool clearAuthor = false,
    int? totalPages,
    String? coverImagePath,
    bool removeCover = false,
    List<int>? tagIds,
  }) async {
    final updatedBook = await _readingSvc.updateBookDetails(
      bookId: bookId,
      books: _books,
      title: title,
      author: author,
      clearAuthor: clearAuthor,
      totalPages: totalPages,
      coverImagePath: coverImagePath,
      removeCover: removeCover,
      tagIds: tagIds,
      deleteImage: _imagePort.deleteImage,
    );
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx != -1) _books[idx] = updatedBook;
    notifyListeners();
  }

  Future<void> deleteBook(int bookId) async {
    await _readingSvc.deleteBook(bookId, _books,
        deleteImage: _imagePort.deleteImage);
    _books.removeWhere((b) => b.id == bookId);
    _sessions.removeWhere((s) => s.bookId == bookId);
    notifyListeners();
  }

  Future<void> refreshBookTags() async {
    await _readingSvc.refreshBookTags(_books);
    notifyListeners();
  }

  Future<Map<String, dynamic>> logPages(int bookId, int pages,
      {int? timeTakenMinutes}) async {
    final result = await _readingSvc.logPages(bookId, pages, _books,
        timeTakenMinutes: timeTakenMinutes);

    final bookIndex = _books.indexWhere((b) => b.id == bookId);
    if (bookIndex != -1) {
      _books[bookIndex] = _books[bookIndex].copyWith(
        pagesRead: result['newPagesRead'] as int?,
        isCompleted: result['bookCompleted'] as bool?,
        maxRewardedPages: result['newMaxRewarded'] as int?,
      );
    }

    await _reloadSessionsForBook(bookId);

    return result;
  }

  Future<void> editSession(
      int sessionId, int bookId, int newPages, int? newTimeMins) async {
    final updatedBook = await _readingSvc.editSession(
        sessionId, bookId, newPages, newTimeMins, _books);
    final bookIdx = _books.indexWhere((b) => b.id == bookId);
    if (bookIdx != -1) _books[bookIdx] = updatedBook;
    await _reloadSessionsForBook(bookId);
  }

  Future<void> deleteSession(int sessionId, int bookId) async {
    final updatedBook =
        await _readingSvc.deleteSession(sessionId, bookId, _books);
    final bookIdx = _books.indexWhere((b) => b.id == bookId);
    if (bookIdx != -1) _books[bookIdx] = updatedBook;
    _sessions.removeWhere((s) => s.id == sessionId);
    await _reloadSessionsForBook(bookId);
  }

  Future<void> _reloadSessionsForBook(int bookId) async {
    final bookSessions = await _readingSvc.getSessionsForBook(bookId);
    _sessions.removeWhere((s) => s.bookId == bookId);
    _sessions.insertAll(0, bookSessions);
    notifyListeners();
  }

  Future<int> getTotalPagesRead() => _readingSvc.getTotalPagesRead();
  Future<int> getCompletedBooksCount() => _readingSvc.getCompletedBooksCount();
  Future<int> getTotalSessionsCount() => _readingSvc.getTotalSessionsCount();
  Future<int> getTotalTimeMinutes() => _readingSvc.getTotalTimeMinutes();
}

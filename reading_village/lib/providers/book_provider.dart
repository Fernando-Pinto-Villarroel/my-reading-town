import 'dart:math';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/book.dart';
import '../models/book_filter.dart';
import '../models/reading_session.dart';
import '../models/tag.dart';
import '../config/game_constants.dart';
import '../services/image_service.dart';

class BookProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Random _random = Random();

  List<Book> _books = [];
  List<ReadingSession> _sessions = [];
  BookFilter _filter = const BookFilter();

  List<Book> get books => _books;
  List<Book> get activeBooks => _books.where((b) => !b.isCompleted).toList();
  List<Book> get completedBooks => _books.where((b) => b.isCompleted).toList();
  List<ReadingSession> get sessions => _sessions;
  BookFilter get filter => _filter;

  List<Book> get filteredBooks {
    var result = List<Book>.from(_books);

    // Completion filter
    if (_filter.showCompleted == true) {
      result = result.where((b) => b.isCompleted).toList();
    } else if (_filter.showCompleted == false) {
      result = result.where((b) => !b.isCompleted).toList();
    }

    // Search query
    final q = _filter.searchQuery?.toLowerCase().trim();
    if (q != null && q.isNotEmpty) {
      result = result.where((b) {
        return b.title.toLowerCase().contains(q) ||
            (b.author?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Tag filter
    if (_filter.selectedTagIds.isNotEmpty) {
      result = result.where((b) {
        return b.tags.any((t) => _filter.selectedTagIds.contains(t.id));
      }).toList();
    }

    // Sorting
    result.sort((a, b) {
      int cmp;
      switch (_filter.sortField) {
        case BookSortField.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case BookSortField.pagesLeft:
          cmp = (a.totalPages - a.pagesRead).compareTo(b.totalPages - b.pagesRead);
          break;
        case BookSortField.dateAdded:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case BookSortField.author:
          cmp = (a.author ?? '').toLowerCase().compareTo((b.author ?? '').toLowerCase());
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
    final bookMaps = await _db.getBooks();
    _books = bookMaps.map((m) => Book.fromMap(m)).toList();

    // Load tags for each book
    for (int i = 0; i < _books.length; i++) {
      if (_books[i].id != null) {
        final tagMaps = await _db.getBookTags(_books[i].id!);
        _books[i].tags = tagMaps.map((m) => Tag.fromMap(m)).toList();
      }
    }

    final sessionMaps = await _db.getReadingSessions();
    _sessions = sessionMaps.map((m) => ReadingSession.fromMap(m)).toList();

    notifyListeners();
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
    final id = await _db.insertBook(book.toMap());

    if (tagIds != null && tagIds.isNotEmpty) {
      await _db.setBookTags(id, tagIds);
    }

    final tagMaps = await _db.getBookTags(id);
    final tags = tagMaps.map((m) => Tag.fromMap(m)).toList();

    final savedBook = book.copyWith(id: id, tags: tags);
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
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;

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
      final oldPath = _books[idx].coverImagePath;
      if (oldPath != null) await ImageService.deleteImage(oldPath);
      updates['cover_image_path'] = null;
    }

    if (updates.isNotEmpty) {
      await _db.updateBook(bookId, updates);
    }
    if (tagIds != null) {
      await _db.setBookTags(bookId, tagIds);
    }

    // Reload this book
    final bookMaps = await _db.getBooks();
    final bookMap = bookMaps.firstWhere((m) => m['id'] == bookId);
    final updatedBook = Book.fromMap(bookMap);
    final tagMaps = await _db.getBookTags(bookId);
    updatedBook.tags = tagMaps.map((m) => Tag.fromMap(m)).toList();
    _books[idx] = updatedBook;
    notifyListeners();
  }

  Future<void> deleteBook(int bookId) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    final book = _books[idx];
    if (book.coverImagePath != null) {
      await ImageService.deleteImage(book.coverImagePath!);
    }
    await _db.deleteBook(bookId);
    _books.removeAt(idx);
    _sessions.removeWhere((s) => s.bookId == bookId);
    notifyListeners();
  }

  /// Refresh tags on all books (call after tag edit/delete)
  Future<void> refreshBookTags() async {
    for (int i = 0; i < _books.length; i++) {
      if (_books[i].id != null) {
        final tagMaps = await _db.getBookTags(_books[i].id!);
        _books[i].tags = tagMaps.map((m) => Tag.fromMap(m)).toList();
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> logPages(int bookId, int pages) async {
    final bookIndex = _books.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) throw Exception('Book not found');

    final book = _books[bookIndex];
    final newPagesRead = (book.pagesRead + pages).clamp(0, book.totalPages);
    final actualPagesLogged = newPagesRead - book.pagesRead;

    if (actualPagesLogged <= 0) {
      return {'coins': 0, 'gems': 0, 'wood': 0, 'metal': 0, 'exp': 0, 'bookCompleted': false};
    }

    int coinsEarned = actualPagesLogged * GameConstants.coinsPerPage;
    int gemsEarned = 0;
    int woodEarned = 0;
    int metalEarned = 0;
    int expEarned = 0;

    if (actualPagesLogged >= 10) {
      woodEarned = actualPagesLogged * GameConstants.woodPerPage;
      metalEarned = actualPagesLogged * GameConstants.metalPerPage;
    } else {
      if (_random.nextBool()) {
        woodEarned = actualPagesLogged * GameConstants.woodPerPage;
      } else {
        metalEarned = actualPagesLogged * GameConstants.metalPerPage;
      }
    }

    bool bookCompleted = newPagesRead >= book.totalPages;

    if (bookCompleted && !book.isCompleted) {
      coinsEarned += GameConstants.bookCompletionCoinBonus;
      gemsEarned += GameConstants.bookCompletionGemBonus;
    }

    await _db.updateBookPages(bookId, newPagesRead, bookCompleted);
    await _db.addResources(
      coins: coinsEarned,
      gems: gemsEarned,
      wood: woodEarned,
      metal: metalEarned,
    );

    final session = ReadingSession(
      bookId: bookId,
      pagesRead: actualPagesLogged,
      coinsEarned: coinsEarned,
      gemsEarned: gemsEarned,
      woodEarned: woodEarned,
      metalEarned: metalEarned,
    );
    await _db.insertReadingSession(session.toMap());

    _books[bookIndex] = book.copyWith(
      pagesRead: newPagesRead,
      isCompleted: bookCompleted,
    );
    _sessions.insert(0, session);

    notifyListeners();

    return {
      'coins': coinsEarned,
      'gems': gemsEarned,
      'wood': woodEarned,
      'metal': metalEarned,
      'exp': expEarned,
      'bookCompleted': bookCompleted,
    };
  }
}

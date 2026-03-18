import 'dart:math';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../config/game_constants.dart';

class BookProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Random _random = Random();

  List<Book> _books = [];
  List<ReadingSession> _sessions = [];

  List<Book> get books => _books;
  List<Book> get activeBooks => _books.where((b) => !b.isCompleted).toList();
  List<Book> get completedBooks => _books.where((b) => b.isCompleted).toList();
  List<ReadingSession> get sessions => _sessions;

  Future<void> loadData() async {
    final bookMaps = await _db.getBooks();
    _books = bookMaps.map((m) => Book.fromMap(m)).toList();

    final sessionMaps = await _db.getReadingSessions();
    _sessions = sessionMaps.map((m) => ReadingSession.fromMap(m)).toList();

    notifyListeners();
  }

  Future<Book> addBook(String title, int totalPages) async {
    final book = Book(title: title, totalPages: totalPages);
    final id = await _db.insertBook(book.toMap());

    final savedBook = book.copyWith(id: id);
    _books.insert(0, savedBook);
    notifyListeners();
    return savedBook;
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
    int expEarned = actualPagesLogged * GameConstants.expPerPage;

    if (actualPagesLogged >= 15) {
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
      expEarned += GameConstants.expPerBookCompleted;
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

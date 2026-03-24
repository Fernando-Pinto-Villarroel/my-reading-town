class ReadingSession {
  final int? id;
  final int bookId;
  final int pagesRead;
  final int coinsEarned;
  final int gemsEarned;
  final int woodEarned;
  final int metalEarned;
  final String date;
  final int? timeTakenMinutes;

  ReadingSession({
    this.id,
    required this.bookId,
    required this.pagesRead,
    required this.coinsEarned,
    required this.gemsEarned,
    this.woodEarned = 0,
    this.metalEarned = 0,
    String? date,
    this.timeTakenMinutes,
  }) : date = date ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'book_id': bookId,
      'pages_read': pagesRead,
      'coins_earned': coinsEarned,
      'gems_earned': gemsEarned,
      'wood_earned': woodEarned,
      'metal_earned': metalEarned,
      'date': date,
      'time_taken_minutes': timeTakenMinutes,
    };
  }

  factory ReadingSession.fromMap(Map<String, dynamic> map) {
    return ReadingSession(
      id: map['id'] as int?,
      bookId: map['book_id'] as int,
      pagesRead: map['pages_read'] as int,
      coinsEarned: map['coins_earned'] as int,
      gemsEarned: map['gems_earned'] as int,
      woodEarned: map['wood_earned'] as int? ?? 0,
      metalEarned: map['metal_earned'] as int? ?? 0,
      date: map['date'] as String,
      timeTakenMinutes: map['time_taken_minutes'] as int?,
    );
  }

  ReadingSession copyWith({
    int? pagesRead,
    int? Function()? timeTakenMinutes,
  }) {
    return ReadingSession(
      id: id,
      bookId: bookId,
      pagesRead: pagesRead ?? this.pagesRead,
      coinsEarned: coinsEarned,
      gemsEarned: gemsEarned,
      woodEarned: woodEarned,
      metalEarned: metalEarned,
      date: date,
      timeTakenMinutes: timeTakenMinutes != null ? timeTakenMinutes() : this.timeTakenMinutes,
    );
  }
}

class Book {
  final int? id;
  final String title;
  final int totalPages;
  int pagesRead;
  final bool isCompleted;
  final String createdAt;

  Book({
    this.id,
    required this.title,
    required this.totalPages,
    this.pagesRead = 0,
    this.isCompleted = false,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  double get progress =>
      totalPages > 0 ? (pagesRead / totalPages).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'total_pages': totalPages,
      'pages_read': pagesRead,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      totalPages: map['total_pages'] as int,
      pagesRead: map['pages_read'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Book copyWith({
    int? id,
    String? title,
    int? totalPages,
    int? pagesRead,
    bool? isCompleted,
    String? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      totalPages: totalPages ?? this.totalPages,
      pagesRead: pagesRead ?? this.pagesRead,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

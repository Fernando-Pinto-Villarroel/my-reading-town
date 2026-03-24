import 'tag.dart';

class Book {
  final int? id;
  final String title;
  final String? author;
  final int totalPages;
  int pagesRead;
  final bool isCompleted;
  final String? coverImagePath;
  final String createdAt;
  List<Tag> tags;

  Book({
    this.id,
    required this.title,
    this.author,
    required this.totalPages,
    this.pagesRead = 0,
    this.isCompleted = false,
    this.coverImagePath,
    String? createdAt,
    List<Tag>? tags,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        tags = tags ?? [];

  double get progress =>
      totalPages > 0 ? (pagesRead / totalPages).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'pages_read': pagesRead,
      'is_completed': isCompleted ? 1 : 0,
      'cover_image_path': coverImagePath,
      'created_at': createdAt,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String?,
      totalPages: map['total_pages'] as int,
      pagesRead: map['pages_read'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      coverImagePath: map['cover_image_path'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Book copyWith({
    int? id,
    String? title,
    String? Function()? author,
    int? totalPages,
    int? pagesRead,
    bool? isCompleted,
    String? Function()? coverImagePath,
    String? createdAt,
    List<Tag>? tags,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author != null ? author() : this.author,
      totalPages: totalPages ?? this.totalPages,
      pagesRead: pagesRead ?? this.pagesRead,
      isCompleted: isCompleted ?? this.isCompleted,
      coverImagePath: coverImagePath != null ? coverImagePath() : this.coverImagePath,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}

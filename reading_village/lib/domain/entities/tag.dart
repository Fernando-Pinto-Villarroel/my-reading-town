class Tag {
  final int? id;
  final String title;
  final int colorValue;

  Tag({
    this.id,
    required this.title,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'color_value': colorValue,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      title: map['title'] as String,
      colorValue: map['color_value'] as int,
    );
  }

  Tag copyWith({int? id, String? title, int? colorValue}) {
    return Tag(
      id: id ?? this.id,
      title: title ?? this.title,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class Note {
  const Note({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.dirty = true,
    this.deletedAt,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool dirty;
  final DateTime? deletedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'dirty': dirty ? 1 : 0,
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  factory Note.fromMap(Map<String, Object?> map) => Note(
    id: (map['id'] as num?)?.toInt(),
    title: map['title'] as String,
    body: map['body'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    dirty: (map['dirty'] as num).toInt() == 1,
    deletedAt: map['deleted_at'] == null
        ? null
        : DateTime.parse(map['deleted_at'] as String),
  );
}

class ReadingItem {
  const ReadingItem({
    required this.id,
    required this.title,
    required this.body,
  });

  final int id;
  final String title;
  final String body;

  Map<String, Object?> toMap() => {'id': id, 'title': title, 'body': body};

  factory ReadingItem.fromMap(Map<String, Object?> map) => ReadingItem(
    id: (map['id'] as num).toInt(),
    title: map['title'] as String,
    body: map['body'] as String,
  );
}

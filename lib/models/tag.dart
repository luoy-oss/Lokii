class Tag {
  final String id;
  final String name;
  final int useCount;
  final DateTime lastUsedAt;

  Tag({
    required this.id,
    required this.name,
    this.useCount = 0,
    DateTime? lastUsedAt,
  }) : lastUsedAt = lastUsedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'useCount': useCount,
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      useCount: map['useCount'] as int,
      lastUsedAt: DateTime.parse(map['lastUsedAt'] as String),
    );
  }

  Tag copyWith({String? name, int? useCount, DateTime? lastUsedAt}) {
    return Tag(
      id: id,
      name: name ?? this.name,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

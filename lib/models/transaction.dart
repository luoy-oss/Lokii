class Transaction {
  final String id;
  final double amount;
  final bool isExpense;
  final String category;
  final String? note;
  final List<String> tags;
  final DateTime date;
  final DateTime createdAt;
  final bool isAutoRecorded;

  Transaction({
    required this.id,
    required this.amount,
    required this.isExpense,
    required this.category,
    this.note,
    this.tags = const [],
    required this.date,
    DateTime? createdAt,
    this.isAutoRecorded = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── SQLite 映射 ─────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'isExpense': isExpense ? 1 : 0,
      'category': category,
      'note': note,
      'tags': tags.join(','),
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isAutoRecorded': isAutoRecorded ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      isExpense: map['isExpense'] == 1,
      category: map['category'] as String,
      note: map['note'] as String?,
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isAutoRecorded: map['isAutoRecorded'] == 1,
    );
  }

  // ── JSON 序列化（导入导出用） ──────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'isExpense': isExpense,
      'category': category,
      'note': note,
      'tags': tags,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isAutoRecorded': isAutoRecorded,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      isExpense: json['isExpense'] as bool,
      category: json['category'] as String,
      note: json['note'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAutoRecorded: json['isAutoRecorded'] as bool? ?? false,
    );
  }

  // ── 工具方法 ───────────────────────────────────────────────────

  Transaction copyWith({
    String? id,
    double? amount,
    bool? isExpense,
    String? category,
    String? note,
    List<String>? tags,
    DateTime? date,
    bool? isAutoRecorded,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      category: category ?? this.category,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      createdAt: createdAt,
      isAutoRecorded: isAutoRecorded ?? this.isAutoRecorded,
    );
  }
}

import 'package:flutter/foundation.dart';

/// مدل سطرهای کالکشن `todos`
///
/// ستون‌ها:
/// - title (String, required)
/// - is_done (bool, default: false)
/// - description (String?, optional)
/// - due_date (Datetime?, optional)
/// - priority (String? یا هر نوعی که در Appwrite تعریف کرده‌ای)
/// - completed_at (Datetime?, optional)
/// + متادیتای سیستمی: $id, $createdAt, $updatedAt
class Todo {
  final String id;
  final String title;
  final bool isDone;
  final String? description;
  final DateTime? dueDate;
  final String? priority;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Todo({
    required this.id,
    required this.title,
    required this.isDone,
    this.description,
    this.dueDate,
    this.priority,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  Todo copyWith({
    String? id,
    String? title,
    bool? isDone,
    String? description,
    DateTime? dueDate,
    String? priority,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v);
      }
      return null;
    }

    return Todo(
      id: json[r'$id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isDone: json['is_done'] as bool? ?? false,
      description: json['description'] as String?,
      dueDate: _parseDate(json['due_date']),
      priority: json['priority'] as String?,
      completedAt: _parseDate(json['completed_at']),
      createdAt: _parseDate(json[r'$createdAt']),
      updatedAt: _parseDate(json[r'$updatedAt']),
    );
  }

  /// داده‌ای که برای create/update به Appwrite فرستاده می‌شود
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'is_done': isDone,
      'description': description,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'priority': priority,
      'completed_at': completedAt?.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, isDone: $isDone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

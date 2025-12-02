// lib/data/models/test_string.dart

class TestString {
  final String id;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TestString({
    required this.id,
    required this.text,
    this.createdAt,
    this.updatedAt,
  });

  TestString copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestString(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TestString.fromJson(Map<String, dynamic> json) {
    return TestString(
      // از payload ریل‌تایم / داکیومنت، این فیلدها را می‌گیریم
      id: (json['\$id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      createdAt: json['\$createdAt'] is String
          ? DateTime.tryParse(json['\$createdAt'] as String)
          : null,
      updatedAt: json['\$updatedAt'] is String
          ? DateTime.tryParse(json['\$updatedAt'] as String)
          : null,
    );
  }

  /// داده‌ای که برای create/update به Appwrite می‌فرستیم
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'text': text,
    };
  }
}

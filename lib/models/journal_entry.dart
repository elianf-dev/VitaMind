class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  factory JournalEntry.create(String text) {
    final now = DateTime.now();
    return JournalEntry(
      id: now.microsecondsSinceEpoch.toString(),
      text: text,
      createdAt: now,
    );
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'createdAt': createdAt.toIso8601String()};
  }
}

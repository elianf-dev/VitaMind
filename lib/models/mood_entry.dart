class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.emoji,
    required this.label,
    required this.notes,
    required this.createdAt,
  });

  factory MoodEntry.create({
    required String emoji,
    required String label,
    required String notes,
  }) {
    final now = DateTime.now();
    return MoodEntry(
      id: now.microsecondsSinceEpoch.toString(),
      emoji: emoji,
      label: label,
      notes: notes,
      createdAt: now,
    );
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      label: json['label'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String emoji;
  final String label;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'label': label,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

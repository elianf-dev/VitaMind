class SymptomEntry {
  const SymptomEntry({
    required this.id,
    required this.symptom,
    required this.severity,
    required this.duration,
    required this.notes,
    required this.createdAt,
  });

  factory SymptomEntry.create({
    required String symptom,
    required int severity,
    String duration = '',
    String notes = '',
  }) {
    final now = DateTime.now();
    return SymptomEntry(
      id: now.microsecondsSinceEpoch.toString(),
      symptom: symptom,
      severity: severity,
      duration: duration.trim(),
      notes: notes.trim(),
      createdAt: now,
    );
  }

  factory SymptomEntry.fromJson(Map<String, dynamic> json) {
    return SymptomEntry(
      id: json['id'] as String? ?? '',
      symptom: json['symptom'] as String? ?? '',
      severity: json['severity'] as int? ?? 1,
      duration: json['duration'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String symptom;
  final int severity;
  final String duration;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symptom': symptom,
      'severity': severity,
      'duration': duration,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

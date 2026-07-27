class DiagnosedCondition {
  const DiagnosedCondition({
    required this.id,
    required this.name,
    required this.dateAdded,
    this.notes = '',
  });

  factory DiagnosedCondition.create({required String name, String notes = ''}) {
    final now = DateTime.now();
    return DiagnosedCondition(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      dateAdded: now,
      notes: notes.trim(),
    );
  }

  factory DiagnosedCondition.fromJson(Map<String, dynamic> json) {
    return DiagnosedCondition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dateAdded:
          DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final DateTime dateAdded;
  final String notes;

  DiagnosedCondition copyWith({
    String? id,
    String? name,
    DateTime? dateAdded,
    String? notes,
  }) {
    return DiagnosedCondition(
      id: id ?? this.id,
      name: name ?? this.name,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateAdded': dateAdded.toIso8601String(),
      'notes': notes,
    };
  }
}

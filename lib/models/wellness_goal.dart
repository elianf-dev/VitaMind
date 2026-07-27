class WellnessGoal {
  const WellnessGoal({
    required this.id,
    required this.title,
    required this.category,
    required this.targetFrequency,
    required this.progress,
    required this.active,
    required this.createdAt,
  });

  factory WellnessGoal.create({
    required String title,
    required String category,
    required String targetFrequency,
  }) {
    final now = DateTime.now();
    return WellnessGoal(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      category: category.trim(),
      targetFrequency: targetFrequency.trim(),
      progress: 0,
      active: true,
      createdAt: now,
    );
  }

  factory WellnessGoal.fromJson(Map<String, dynamic> json) {
    final progressValue = (json['progress'] as num?)?.toDouble() ?? 0;
    return WellnessGoal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Wellness',
      targetFrequency: json['targetFrequency'] as String? ?? 'Daily',
      progress: progressValue.clamp(0, 1).toDouble(),
      active: json['active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String category;
  final String targetFrequency;
  final double progress;
  final bool active;
  final DateTime createdAt;

  WellnessGoal copyWith({
    String? id,
    String? title,
    String? category,
    String? targetFrequency,
    double? progress,
    bool? active,
    DateTime? createdAt,
  }) {
    return WellnessGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      progress: progress ?? this.progress,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'targetFrequency': targetFrequency,
      'progress': progress,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

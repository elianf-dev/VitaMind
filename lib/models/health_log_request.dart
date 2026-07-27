import 'diagnosed_condition.dart';
import 'wellness_goal.dart';

class HealthLogRequest {
  const HealthLogRequest({
    required this.symptoms,
    required this.severity,
    required this.duration,
    required this.medications,
    required this.doctorNotes,
    this.diagnosedConditions = const [],
    this.wellnessGoals = const [],
  });

  final String symptoms;
  final int severity;
  final String duration;
  final String medications;
  final String doctorNotes;
  final List<DiagnosedCondition> diagnosedConditions;
  final List<WellnessGoal> wellnessGoals;

  bool get hasMedications => medications.trim().isNotEmpty;
  bool get hasDoctorNotes => doctorNotes.trim().isNotEmpty;

  factory HealthLogRequest.fromJson(Map<String, dynamic> json) {
    return HealthLogRequest(
      symptoms: json['symptoms'] as String? ?? '',
      severity: _decodeSeverity(json['severity']),
      duration: json['duration'] as String? ?? '',
      medications: json['medications'] as String? ?? '',
      doctorNotes: json['doctorNotes'] as String? ?? '',
      diagnosedConditions: _decodeConditions(json['diagnosedConditions']),
      wellnessGoals: _decodeGoals(json['wellnessGoals']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptoms': symptoms,
      'severity': severity,
      'duration': duration,
      'medications': medications,
      'doctorNotes': doctorNotes,
      'diagnosedConditions': diagnosedConditions
          .map((condition) => condition.toJson())
          .toList(),
      'wellnessGoals': wellnessGoals.map((goal) => goal.toJson()).toList(),
    };
  }

  static List<DiagnosedCondition> _decodeConditions(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) =>
              DiagnosedCondition.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static int _decodeSeverity(Object? value) {
    final rounded = value is num ? value.round() : 5;
    if (rounded < 1) {
      return 1;
    }
    if (rounded > 10) {
      return 10;
    }
    return rounded;
  }

  static List<WellnessGoal> _decodeGoals(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => WellnessGoal.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

import 'package:flutter/material.dart';

enum CheckInFrequency {
  daily('Daily'),
  everyOtherDay('Every Other Day'),
  weekly('Weekly');

  const CheckInFrequency(this.label);

  final String label;

  static CheckInFrequency fromName(String? name) {
    return CheckInFrequency.values.firstWhere(
      (frequency) => frequency.name == name,
      orElse: () => CheckInFrequency.daily,
    );
  }
}

class CheckInSettings {
  const CheckInSettings({
    required this.enabled,
    required this.time,
    required this.frequency,
  });

  factory CheckInSettings.defaults() {
    return const CheckInSettings(
      enabled: true,
      time: TimeOfDay(hour: 19, minute: 0),
      frequency: CheckInFrequency.daily,
    );
  }

  final bool enabled;
  final TimeOfDay time;
  final CheckInFrequency frequency;

  factory CheckInSettings.fromJson(Map<String, dynamic> json) {
    return CheckInSettings(
      enabled: json['enabled'] as bool? ?? true,
      time: TimeOfDay(
        hour: json['hour'] as int? ?? 19,
        minute: json['minute'] as int? ?? 0,
      ),
      frequency: CheckInFrequency.fromName(json['frequency'] as String?),
    );
  }

  CheckInSettings copyWith({
    bool? enabled,
    TimeOfDay? time,
    CheckInFrequency? frequency,
  }) {
    return CheckInSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'hour': time.hour,
      'minute': time.minute,
      'frequency': frequency.name,
    };
  }
}

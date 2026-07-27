import 'health_log_request.dart';
import 'health_log_response.dart';

class HealthLogEntry {
  const HealthLogEntry({
    required this.id,
    required this.request,
    required this.response,
    required this.createdAt,
  });

  factory HealthLogEntry.create({
    required HealthLogRequest request,
    required HealthLogResponse response,
  }) {
    final now = DateTime.now();
    return HealthLogEntry(
      id: now.microsecondsSinceEpoch.toString(),
      request: request,
      response: response,
      createdAt: now,
    );
  }

  factory HealthLogEntry.fromJson(Map<String, dynamic> json) {
    return HealthLogEntry(
      id: json['id'] as String? ?? '',
      request: HealthLogRequest.fromJson(
        Map<String, dynamic>.from(json['request'] as Map? ?? const {}),
      ),
      response: HealthLogResponse.fromJson(
        Map<String, dynamic>.from(json['response'] as Map? ?? const {}),
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final HealthLogRequest request;
  final HealthLogResponse response;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request': request.toJson(),
      'response': response.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

import 'trusted_health_source.dart';

class HealthLogResponse {
  const HealthLogResponse({
    required this.summary,
    required this.relatedTrackedConditions,
    required this.wellnessTips,
    required this.copingStrategies,
    required this.medicationExplanation,
    required this.warningSigns,
    required this.doctorQuestions,
    required this.disclaimer,
    this.trustedSources = const [],
    this.source = HealthLogResponseSource.sourceSupported,
  });

  final String summary;
  final List<String> relatedTrackedConditions;
  final List<String> wellnessTips;
  final List<String> copingStrategies;
  final String medicationExplanation;
  final List<String> warningSigns;
  final List<String> doctorQuestions;
  final String disclaimer;
  final List<TrustedHealthSource> trustedSources;
  final HealthLogResponseSource source;

  factory HealthLogResponse.fromJson(Map<String, dynamic> json) {
    return HealthLogResponse(
      summary: _stringValue(json['summary']),
      relatedTrackedConditions: _stringList(json['relatedTrackedConditions']),
      wellnessTips: _stringList(json['wellnessTips']),
      copingStrategies: _stringList(json['copingStrategies']),
      medicationExplanation: _stringValue(json['medicationExplanation']),
      warningSigns: _stringList(json['warningSigns']),
      doctorQuestions: _stringList(json['doctorQuestions']),
      disclaimer: _stringValue(json['disclaimer']).isEmpty
          ? 'This is not medical advice or a diagnosis.'
          : _stringValue(json['disclaimer']),
      trustedSources: _sourceList(json['trustedSources']),
      source: _sourceFromJson(json['source']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'relatedTrackedConditions': relatedTrackedConditions,
      'wellnessTips': wellnessTips,
      'copingStrategies': copingStrategies,
      'medicationExplanation': medicationExplanation,
      'warningSigns': warningSigns,
      'doctorQuestions': doctorQuestions,
      'disclaimer': disclaimer,
      'trustedSources': trustedSources
          .map((source) => source.toJson())
          .toList(),
      'source': source.name,
    };
  }

  static String _stringValue(Object? value) {
    return value is String ? value : '';
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  static List<TrustedHealthSource> _sourceList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) {
          if (item is String && item.trim().isNotEmpty) {
            return TrustedHealthSource.fromLegacyString(item);
          }
          if (item is Map<dynamic, dynamic>) {
            return TrustedHealthSource.fromJson(
              Map<String, dynamic>.from(item),
            );
          }
          return null;
        })
        .whereType<TrustedHealthSource>()
        .where((source) => source.title.trim().isNotEmpty)
        .toList();
  }

  static HealthLogResponseSource _sourceFromJson(Object? value) {
    if (value == HealthLogResponseSource.legacyBackend.name ||
        value == 'backend') {
      return HealthLogResponseSource.legacyBackend;
    }
    if (value == HealthLogResponseSource.legacyLocalMock.name ||
        value == 'localMock') {
      return HealthLogResponseSource.legacyLocalMock;
    }

    return HealthLogResponseSource.sourceSupported;
  }
}

enum HealthLogResponseSource { sourceSupported, legacyBackend, legacyLocalMock }

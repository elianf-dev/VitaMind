import 'package:flutter_test/flutter_test.dart';
import 'package:vitamind/models/health_log_response.dart';

void main() {
  Map<String, dynamic> legacyJson() => {
    'summary': 'You logged Headache with severity 5/10 for 2 days.',
    'relatedTrackedConditions': ['None'],
    'wellnessTips': ['Track sleep.'],
    'copingStrategies': ['Rest.'],
    'medicationExplanation': 'No current medications were entered.',
    'warningSigns': ['Seek urgent care for severe chest pain.'],
    'doctorQuestions': ['What should I track?'],
    'disclaimer': 'This is not medical advice or a diagnosis.',
    'trustedSources': <Object>[],
    'source': 'sourceSupported',
  };

  test('fromJson without crisisDetected defaults to false', () {
    final response = HealthLogResponse.fromJson(legacyJson());

    expect(response.crisisDetected, isFalse);
    expect(response.summary, contains('Headache'));
    expect(response.warningSigns, hasLength(1));
  });

  test('fromJson treats a non-bool crisisDetected as false', () {
    final response = HealthLogResponse.fromJson({
      ...legacyJson(),
      'crisisDetected': 'yes',
    });

    expect(response.crisisDetected, isFalse);
  });

  test('crisisDetected round-trips through toJson and fromJson', () {
    final original = HealthLogResponse.fromJson({
      ...legacyJson(),
      'crisisDetected': true,
    });
    expect(original.crisisDetected, isTrue);

    final json = original.toJson();
    expect(json['crisisDetected'], isTrue);

    final restored = HealthLogResponse.fromJson(json);
    expect(restored.crisisDetected, isTrue);
    expect(restored.toJson(), json);

    final notCrisis = HealthLogResponse.fromJson(legacyJson());
    expect(notCrisis.toJson()['crisisDetected'], isFalse);
    expect(
      HealthLogResponse.fromJson(notCrisis.toJson()).crisisDetected,
      isFalse,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vitamind/models/diagnosed_condition.dart';
import 'package:vitamind/models/health_log_request.dart';
import 'package:vitamind/services/health_log_explainer_service.dart';

void main() {
  const service = HealthLogExplainerService();

  HealthLogRequest request({
    String symptoms = 'Headache',
    int severity = 5,
    String duration = '2 days',
    String medications = '',
    String doctorNotes = '',
    List<DiagnosedCondition> conditions = const [],
  }) {
    return HealthLogRequest(
      symptoms: symptoms,
      severity: severity,
      duration: duration,
      medications: medications,
      doctorNotes: doctorNotes,
      diagnosedConditions: conditions,
    );
  }

  test(
    'always returns the required disclaimer and a source-backed summary',
    () async {
      final response = await service.explainHealthLog(request());

      expect(response.disclaimer, 'This is not medical advice or a diagnosis.');
      expect(response.summary, contains('Headache'));
      expect(response.summary, contains('5/10'));
      expect(
        response.trustedSources.any(
          (source) => source.url == 'https://medlineplus.gov/headache.html',
        ),
        isTrue,
      );
    },
  );

  test(
    'high severity advises professional contact without diagnosing',
    () async {
      final response = await service.explainHealthLog(
        request(severity: 8, medications: 'Prescription medication'),
      );
      final allText = [
        ...response.wellnessTips,
        ...response.warningSigns,
        response.medicationExplanation,
      ].join(' ').toLowerCase();

      expect(allText, contains('healthcare professional'));
      expect(response.medicationExplanation, contains('pharmacist'));
      expect(allText, isNot(contains('you have')));
      expect(allText, isNot(contains('you should take')));
    },
  );

  test('testicular pain adds a specific urgent-care reminder', () async {
    final response = await service.explainHealthLog(
      request(symptoms: 'Sudden testicular pain', severity: 7),
    );

    expect(response.warningSigns.first, contains('testicle pain'));
    expect(
      response.trustedSources.any(
        (source) =>
            source.url == 'https://medlineplus.gov/ency/article/003160.htm',
      ),
      isTrue,
    );
  });

  test(
    'stress logs include non-diagnostic grounding and trigger tracking',
    () async {
      final response = await service.explainHealthLog(
        request(
          symptoms: 'Stress',
          conditions: [
            DiagnosedCondition(
              id: 'anxiety',
              name: 'Anxiety',
              dateAdded: DateTime(2026),
            ),
          ],
        ),
      );

      final tips = response.copingStrategies.join(' ').toLowerCase();
      expect(tips, contains('grounding'));
      expect(tips, contains('triggers'));
    },
  );

  test(
    'immediate mental-health risk language points to emergency care',
    () async {
      final response = await service.explainHealthLog(
        request(symptoms: 'I might hurt myself'),
      );

      expect(response.warningSigns.first, contains('emergency'));
    },
  );
}

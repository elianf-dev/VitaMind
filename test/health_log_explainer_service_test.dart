import 'dart:convert';

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

  test(
    'common crisis phrasings show the 988 line first and cite the Lifeline',
    () async {
      for (final symptoms in const [
        'I want to kill myself',
        'honestly I just want to die',
        'thinking about ending my life',
        'I don’t want to live anymore',
        'feel like everyone would be better off dead without me',
      ]) {
        final response = await service.explainHealthLog(
          request(symptoms: symptoms),
        );

        expect(response.warningSigns.first, contains('988'), reason: symptoms);
        expect(
          response.trustedSources.first.url,
          'https://988lifeline.org/',
          reason: symptoms,
        );
      }
    },
  );

  test('crisis phrasing in clinician notes is also caught', () async {
    final response = await service.explainHealthLog(
      request(symptoms: 'Low mood', doctorNotes: 'Said they want to die'),
    );

    expect(response.warningSigns.first, contains('988'));
  });

  test('ordinary symptoms do not show the crisis line', () async {
    final response = await service.explainHealthLog(
      request(symptoms: 'I cut myself cooking and have a headache'),
    );

    expect(response.warningSigns.any((sign) => sign.contains('988')), isFalse);
    expect(
      response.trustedSources.any(
        (source) => source.url == 'https://988lifeline.org/',
      ),
      isFalse,
    );
  });

  group('crisisDetected (A1)', () {
    test('a crisis phrase sets crisisDetected', () async {
      final response = await service.explainHealthLog(
        request(symptoms: 'Honestly I just want to die'),
      );

      expect(response.crisisDetected, isTrue);
    });

    test('an ordinary log leaves crisisDetected false', () async {
      final response = await service.explainHealthLog(
        request(symptoms: 'Headache and nausea'),
      );

      expect(response.crisisDetected, isFalse);
    });

    test('988 stays first in warningSigns when the sudden headache and '
        'testicle rules also match', () async {
      final response = await service.explainHealthLog(
        request(
          symptoms:
              'Sudden worst headache of my life, testicle pain, and I want to '
              'kill myself',
        ),
      );

      expect(response.crisisDetected, isTrue);
      expect(response.warningSigns.first, contains('988'));
      // The other urgent-care reminders are still there, after 988.
      expect(
        response.warningSigns.any((sign) => sign.contains('sudden, extremely')),
        isTrue,
      );
      expect(
        response.warningSigns.any((sign) => sign.contains('testicle pain')),
        isTrue,
      );
      expect(
        response.warningSigns.where((sign) => sign.contains('988')),
        hasLength(1),
      );
    });

    test('988 stays first with only the sudden headache rule', () async {
      final response = await service.explainHealthLog(
        request(symptoms: 'sudden worst headache, I want to die'),
      );

      expect(response.warningSigns.first, contains('988'));
    });
  });

  group('A2 misfire fixes', () {
    group('day words (criterion 6)', () {
      const severalDaysTip = 'lasted more than a short moment';

      Future<bool> showsSeveralDaysTip(String duration) async {
        final response = await service.explainHealthLog(
          request(symptoms: 'Tired', duration: duration),
        );
        return response.wellnessTips.any((tip) => tip.contains(severalDaysTip));
      }

      for (final duration in [
        'today',
        'this morning',
        'since Monday',
        'Tuesday',
        '2 hours',
        '',
      ]) {
        test('"$duration" is not treated as several days', () async {
          expect(await showsSeveralDaysTip(duration), isFalse);
        });
      }

      for (final duration in [
        '3 days',
        'a day',
        'since yesterday',
        'a week',
        'two weeks',
        'a month',
        'months',
        'ongoing',
        'persistent',
      ]) {
        test('"$duration" is treated as several days', () async {
          expect(await showsSeveralDaysTip(duration), isTrue);
        });
      }
    });

    test('crisis + sudden worst headache + testicle pain keeps 988 first, '
        'crisisDetected true and the Lifeline first in sources '
        '(criterion 8)', () async {
      final response = await service.explainHealthLog(
        request(
          symptoms:
              'Sudden worst headache, testicle pain. Honestly I don’t want to '
              'live anymore',
        ),
      );

      expect(response.crisisDetected, isTrue);
      expect(response.warningSigns.first, contains('988'));
      expect(
        response.warningSigns.where((sign) => sign.contains('988')),
        hasLength(1),
      );
      expect(response.trustedSources.first.url, 'https://988lifeline.org/');
    });

    test('crisis phrases are still caught inside longer words and sentences '
        '(criterion 8, substring matching unchanged)', () async {
      for (final text in [
        'honestly I just want to die',
        'I don’t want to live anymore',
        'thinking about self-harm',
        'feeling suicidal lately',
      ]) {
        final response = await service.explainHealthLog(
          request(symptoms: text),
        );
        expect(response.crisisDetected, isTrue, reason: text);
        expect(response.warningSigns.first, contains('988'), reason: text);
      }
    });

    group('mental-health terms give the same output as before A2 '
        '(criterion 9)', () {
      // Captured from the pre-A2 code (fe55aa0) with severity 5, duration
      // "2 days" and no other fields.
      const before = <String, String>{
        'Stress':
            r'''{"wellnessTips":["Track symptoms, mood, sleep, hydration, meals, stress, and notes together so patterns are easier to review.","Since this has lasted more than a short moment, write down when it started, what changed, and what helps or worsens it."],"copingStrategies":["Use a short journal note to capture what was happening before the symptoms changed.","If symptoms are mild and familiar, a calm pause, hydration, rest, or a lower-stimulation environment can help you observe patterns.","For stress or anxiety, note triggers, grounding exercises, breathing practice, movement, and whether journaling helped.","Consider tracking what support felt useful, such as routine, a quieter environment, or talking with someone trusted."],"warningSigns":["Seek urgent care for severe chest pain, trouble breathing, fainting, sudden weakness, confusion, or symptoms that feel dangerous or unusual.","Contact a healthcare professional if symptoms are severe, worsening, persistent, new after starting a medication, or interfering with daily life.","A pharmacist or prescriber can answer questions about medication timing, side effects, or changes."],"doctorQuestions":["Could these symptoms be related to my current medications, diagnoses, routines, or recent changes?","What symptoms should prompt urgent care versus a routine appointment?","What patterns should I track before my next visit?"],"urls":["https://medlineplus.gov/healthtopics.html","https://medlineplus.gov/medlineplus-connect/","https://www.cdc.gov/health-topics.html","https://medlineplus.gov/anxiety.html","https://www.nimh.nih.gov/health/topics/anxiety-disorders","https://medlineplus.gov/stress.html"]}''',
        'anxiety':
            r'''{"wellnessTips":["Track symptoms, mood, sleep, hydration, meals, stress, and notes together so patterns are easier to review.","Since this has lasted more than a short moment, write down when it started, what changed, and what helps or worsens it."],"copingStrategies":["Use a short journal note to capture what was happening before the symptoms changed.","If symptoms are mild and familiar, a calm pause, hydration, rest, or a lower-stimulation environment can help you observe patterns.","For stress or anxiety, note triggers, grounding exercises, breathing practice, movement, and whether journaling helped.","Consider tracking what support felt useful, such as routine, a quieter environment, or talking with someone trusted."],"warningSigns":["Seek urgent care for severe chest pain, trouble breathing, fainting, sudden weakness, confusion, or symptoms that feel dangerous or unusual.","Contact a healthcare professional if symptoms are severe, worsening, persistent, new after starting a medication, or interfering with daily life.","A pharmacist or prescriber can answer questions about medication timing, side effects, or changes."],"doctorQuestions":["Could these symptoms be related to my current medications, diagnoses, routines, or recent changes?","What symptoms should prompt urgent care versus a routine appointment?","What patterns should I track before my next visit?"],"urls":["https://medlineplus.gov/healthtopics.html","https://medlineplus.gov/medlineplus-connect/","https://www.cdc.gov/health-topics.html","https://medlineplus.gov/anxiety.html","https://www.nimh.nih.gov/health/topics/anxiety-disorders"]}''',
        'depression':
            r'''{"wellnessTips":["Track symptoms, mood, sleep, hydration, meals, stress, and notes together so patterns are easier to review.","Since this has lasted more than a short moment, write down when it started, what changed, and what helps or worsens it."],"copingStrategies":["Use a short journal note to capture what was happening before the symptoms changed.","If symptoms are mild and familiar, a calm pause, hydration, rest, or a lower-stimulation environment can help you observe patterns."],"warningSigns":["Seek urgent care for severe chest pain, trouble breathing, fainting, sudden weakness, confusion, or symptoms that feel dangerous or unusual.","Contact a healthcare professional if symptoms are severe, worsening, persistent, new after starting a medication, or interfering with daily life.","A pharmacist or prescriber can answer questions about medication timing, side effects, or changes."],"doctorQuestions":["Could these symptoms be related to my current medications, diagnoses, routines, or recent changes?","What symptoms should prompt urgent care versus a routine appointment?","What patterns should I track before my next visit?"],"urls":["https://medlineplus.gov/healthtopics.html","https://medlineplus.gov/medlineplus-connect/","https://www.cdc.gov/health-topics.html","https://medlineplus.gov/depression.html","https://www.nimh.nih.gov/health/topics/depression"]}''',
      };

      for (final entry in before.entries) {
        test(entry.key, () async {
          final response = await service.explainHealthLog(
            request(symptoms: entry.key),
          );
          final json = response.toJson();
          final actual = {
            'wellnessTips': json['wellnessTips'],
            'copingStrategies': json['copingStrategies'],
            'warningSigns': json['warningSigns'],
            'doctorQuestions': json['doctorQuestions'],
            'urls': response.trustedSources
                .map((source) => source.url)
                .toList(),
          };
          expect(actual, jsonDecode(entry.value));
        });
      }
    });
  });

  group('A2 fix round 1', () {
    group('SEC-A2-2: crisis phrases split by unusual separators', () {
      for (final text in [
        'thinking about self  harm',
        'thinking about self–harm',
        'thinking about self—harm',
        'thinking about self_harm',
        'thinking about self\nharm',
        'I want to\ndie',
        'I want  to die',
        'I want\tto die',
        'I want to\r\ndie',
        'I want to die', // non-breaking spaces
        'I don‘t want to live',
        'I want to kill−myself',
        'better__off  dead',
      ]) {
        test(
          'caught: ${text.replaceAll('\n', r'\n').replaceAll('\r', r'\r').replaceAll('\t', r'\t')}',
          () async {
            final response = await service.explainHealthLog(
              request(symptoms: text),
            );
            expect(response.crisisDetected, isTrue);
            expect(response.warningSigns.first, contains('988'));
            expect(
              response.trustedSources.first.url,
              'https://988lifeline.org/',
            );
          },
        );
      }

      test('separator variants in clinician notes are caught too', () async {
        final response = await service.explainHealthLog(
          request(symptoms: 'Headache', doctorNotes: 'mentions self–harm'),
        );
        expect(response.crisisDetected, isTrue);
      });

      test('the normalized check only adds matches: ordinary logs stay '
          'false', () async {
        for (final text in [
          'Headache and nausea',
          'self care day',
          'harm reduction',
          'I want to dye my hair',
        ]) {
          final response = await service.explainHealthLog(
            request(symptoms: text),
          );
          expect(response.crisisDetected, isFalse, reason: text);
        }
      });
    });

    group('QA-A2-3: a number joined to the unit', () {
      Future<bool> showsSeveralDaysTip(String duration) async {
        final response = await service.explainHealthLog(
          request(symptoms: 'Tired', duration: duration),
        );
        return response.wellnessTips.any(
          (tip) => tip.contains('lasted more than a short moment'),
        );
      }

      for (final duration in ['3days', '2weeks', '1day', '6months', '2Weeks']) {
        test('"$duration" counts like "3 days"', () async {
          expect(await showsSeveralDaysTip(duration), isTrue);
        });
      }

      for (final duration in ['10hrs', '2hours', '45min', 'today']) {
        test('"$duration" still does not count as several days', () async {
          expect(await showsSeveralDaysTip(duration), isFalse);
        });
      }
    });
  });
}

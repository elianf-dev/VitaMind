import 'package:flutter_test/flutter_test.dart';
import 'package:vitamind/data/trusted_health_sources.dart';
import 'package:vitamind/models/trusted_health_source.dart';

List<TrustedHealthSource> _sourcesFor(
  String symptoms, {
  List<String> conditions = const [],
}) {
  return TrustedHealthSources.forHealthLog(
    symptoms: symptoms,
    diagnosedConditions: conditions,
    medications: '',
  );
}

bool _has(List<TrustedHealthSource> sources, TrustedHealthSource source) =>
    sources.any((item) => item.url == source.url);

void main() {
  const diabetesSources = [
    TrustedHealthSources.diabetes,
    TrustedHealthSources.niddkDiabetes,
    TrustedHealthSources.cdcDiabetes,
    TrustedHealthSources.americanDiabetesAssociation,
  ];
  const asthmaSources = [
    TrustedHealthSources.asthma,
    TrustedHealthSources.nhlbiAsthma,
    TrustedHealthSources.cdcAsthma,
    TrustedHealthSources.aafaAsthma,
  ];

  group('A2 whole-word matching for sources', () {
    test('"ibs" inside "ribs" adds no digestive sources (criterion 1)', () {
      final sources = _sourcesFor('sore ribs');
      expect(_has(sources, TrustedHealthSources.digestiveDiseases), isFalse);
      expect(_has(sources, TrustedHealthSources.nausea), isFalse);
    });

    test('IBS as a word still adds digestive sources (criterion 1)', () {
      for (final text in ['I have IBS', 'ibs flare']) {
        final sources = _sourcesFor(text);
        expect(
          _has(sources, TrustedHealthSources.digestiveDiseases),
          isTrue,
          reason: text,
        );
        expect(_has(sources, TrustedHealthSources.nausea), isTrue, reason: text);
      }
    });

    test('"Spain" and "painting" add no pain source (criterion 2)', () {
      for (final text in ['back from Spain', 'painting all day']) {
        expect(
          _has(_sourcesFor(text), TrustedHealthSources.pain),
          isFalse,
          reason: text,
        );
      }
    });

    test('real pain words still add the pain source (criterion 2)', () {
      for (final text in ['knee pain', 'pains in my legs', 'painful wrist']) {
        expect(
          _has(_sourcesFor(text), TrustedHealthSources.pain),
          isTrue,
          reason: text,
        );
      }
    });

    test('headache adds headache sources but not the generic pain source '
        '(criterion 3)', () {
      final sources = _sourcesFor('headache');
      expect(_has(sources, TrustedHealthSources.headache), isTrue);
      expect(
        _has(sources, TrustedHealthSources.americanMigraineFoundation),
        isTrue,
      );
      expect(_has(sources, TrustedHealthSources.pain), isFalse);
    });

    test('"aches all over" still adds the pain source (criterion 3)', () {
      expect(
        _has(_sourcesFor('aches all over'), TrustedHealthSources.pain),
        isTrue,
      );
    });

    test('"breathtaking" adds no asthma sources (criterion 4)', () {
      final sources = _sourcesFor('breathtaking view, mild headache');
      for (final source in asthmaSources) {
        expect(_has(sources, source), isFalse, reason: source.title);
      }
    });

    test('breathing words still add asthma sources (criterion 4)', () {
      for (final text in [
        'short of breath',
        'shortness of breath',
        'trouble breathing',
      ]) {
        final sources = _sourcesFor(text);
        for (final source in asthmaSources) {
          expect(_has(sources, source), isTrue, reason: '$text: ${source.title}');
        }
      }
    });
  });

  group('A2 forms that matched before still match (criterion 5)', () {
    final table = <String, TrustedHealthSource>{
      'headaches': TrustedHealthSources.headache,
      'migraines': TrustedHealthSources.migraine,
      'pains': TrustedHealthSources.pain,
      'painful': TrustedHealthSources.pain,
      'aches': TrustedHealthSources.pain,
      'stomachache': TrustedHealthSources.pain,
      'backache': TrustedHealthSources.pain,
      'toothache': TrustedHealthSources.pain,
      'earache': TrustedHealthSources.pain,
      'breathing': TrustedHealthSources.asthma,
      'breathless': TrustedHealthSources.asthma,
      'vomiting': TrustedHealthSources.nausea,
      'vomited': TrustedHealthSources.nausea,
      'stressed': TrustedHealthSources.stress,
      'stressful': TrustedHealthSources.stress,
      'sleeping': TrustedHealthSources.sleepDisorders,
      'sleepless': TrustedHealthSources.sleepDisorders,
      'asleep': TrustedHealthSources.sleepDisorders,
      'testicles': TrustedHealthSources.testiclePain,
      'scrotal': TrustedHealthSources.testiclePain,
      'groin pain': TrustedHealthSources.testiclePain,
    };

    for (final entry in table.entries) {
      test('"${entry.key}" adds ${entry.value.title}', () {
        expect(_has(_sourcesFor(entry.key), entry.value), isTrue);
      });
    }

    test('stomachache also still adds digestive sources', () {
      expect(
        _has(_sourcesFor('stomachache'), TrustedHealthSources.nausea),
        isTrue,
      );
    });
  });

  group('A2 fatigue no longer pulls diabetes sources (criterion 7)', () {
    test('fatigue alone adds no diabetes source and falls back to the general '
        'sources', () {
      final sources = _sourcesFor('fatigue');
      for (final source in diabetesSources) {
        expect(_has(sources, source), isFalse, reason: source.title);
      }
      expect(sources.map((source) => source.url), [
        TrustedHealthSources.medlinePlusHealthTopics.url,
        TrustedHealthSources.medlinePlusConnect.url,
        TrustedHealthSources.cdcHealthTopics.url,
        TrustedHealthSources.mayoClinicSymptoms.url,
        TrustedHealthSources.clevelandClinicHealthLibrary.url,
      ]);
    });

    test('diabetes as a symptom or a saved condition adds all four', () {
      final asSymptom = _sourcesFor('diabetes');
      final asCondition = _sourcesFor('tired', conditions: ['Type 2 Diabetes']);
      for (final source in diabetesSources) {
        expect(_has(asSymptom, source), isTrue, reason: source.title);
        expect(_has(asCondition, source), isTrue, reason: source.title);
      }
    });
  });
}

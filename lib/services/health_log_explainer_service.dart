import '../data/trusted_health_sources.dart';
import '../models/health_log_request.dart';
import '../models/health_log_response.dart';

class HealthLogExplainerService {
  const HealthLogExplainerService();

  Future<HealthLogResponse> explainHealthLog(HealthLogRequest request) async {
    // TODO: Add an optional VitaMind Plus AI backend here later. Keep the free
    // explainer deterministic and source-supported so it works without API keys.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _buildRuleBasedResponse(request);
  }

  HealthLogResponse _buildRuleBasedResponse(HealthLogRequest request) {
    final symptoms = request.symptoms.trim().isEmpty
        ? 'the symptoms you entered'
        : request.symptoms.trim();
    final duration = request.duration.trim().isEmpty
        ? 'an unspecified duration'
        : request.duration.trim();
    final doctorNotes = request.doctorNotes.trim().isEmpty
        ? ''
        : ' You also added notes from a clinician: ${request.doctorNotes.trim()}';
    final conditionNames = request.diagnosedConditions
        .map((condition) => condition.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final activeGoals = request.wellnessGoals
        .where((goal) => goal.active)
        .map((goal) => goal.title.trim())
        .where((title) => title.isNotEmpty)
        .toList();
    final combinedText =
        '${request.symptoms} ${request.doctorNotes} ${conditionNames.join(' ')}'
            .toLowerCase();

    final relatedConditions = conditionNames.isEmpty
        ? <String>[
            'No diagnosed conditions are saved yet. You can add known conditions in Profile if you want VitaMind to organize future logs.',
          ]
        : conditionNames
              .map(
                (name) =>
                    '$name is saved in Diagnosed Conditions. VitaMind can use it for tracking context, but it cannot decide what caused this symptom.',
              )
              .toList();

    final wellnessTips = <String>[
      'Track symptoms, mood, sleep, hydration, meals, stress, and notes together so patterns are easier to review.',
      if (request.severity >= 7)
        'Because this was rated ${request.severity}/10, consider contacting a healthcare professional if it feels severe, unusual, worsening, or hard to manage.',
      if (_soundsLikeSeveralDays(request.duration))
        'Since this has lasted more than a short moment, write down when it started, what changed, and what helps or worsens it.',
      if (activeGoals.isNotEmpty)
        'Your active goals may be useful context: ${activeGoals.take(3).join(', ')}.',
    ];

    final copingStrategies = <String>[
      'Use a short journal note to capture what was happening before the symptoms changed.',
      'If symptoms are mild and familiar, a calm pause, hydration, rest, or a lower-stimulation environment can help you observe patterns.',
    ];

    if (combinedText.contains('headache') ||
        combinedText.contains('migraine')) {
      copingStrategies.addAll(const [
        'For headache or migraine tracking, note sleep, hydration, stress, meals, screen time, light sensitivity, and possible triggers.',
        'Track whether the symptom improves, worsens, or changes after rest or lower light.',
      ]);
    }

    if (combinedText.contains('anxiety') || combinedText.contains('stress')) {
      copingStrategies.addAll(const [
        'For stress or anxiety, note triggers, grounding exercises, breathing practice, movement, and whether journaling helped.',
        'Consider tracking what support felt useful, such as routine, a quieter environment, or talking with someone trusted.',
      ]);
    }

    if (combinedText.contains('diabetes') || combinedText.contains('fatigue')) {
      wellnessTips.add(
        'For diabetes or fatigue context, tracking meals, hydration, sleep, activity, and your usual care-plan routine may help a clinician conversation.',
      );
    }

    if (combinedText.contains('sleep')) {
      wellnessTips.add(
        'For sleep-related logs, track bedtime, wake time, screens, caffeine, stress, naps, and how rested you felt.',
      );
    }

    final medicationExplanation = _medicationNote(request.medications);
    final warningSigns = <String>[
      'Seek urgent care for severe chest pain, trouble breathing, fainting, sudden weakness, confusion, or symptoms that feel dangerous or unusual.',
      'Contact a healthcare professional if symptoms are severe, worsening, persistent, new after starting a medication, or interfering with daily life.',
      'A pharmacist or prescriber can answer questions about medication timing, side effects, or changes.',
    ];

    if (_mentionsImmediateMentalHealthRisk(combinedText)) {
      warningSigns.insert(
        0,
        'If you may hurt yourself or someone else, call local emergency services or go to the nearest emergency department now.',
      );
    }

    if (combinedText.contains('headache') &&
        (combinedText.contains('sudden') ||
            combinedText.contains('worst headache'))) {
      warningSigns.insert(
        0,
        'Seek urgent care for a sudden, extremely severe headache or a headache with confusion, fainting, weakness, trouble speaking, or vision loss.',
      );
    }

    if (combinedText.contains('testicle') ||
        combinedText.contains('testicular') ||
        combinedText.contains('groin pain')) {
      warningSigns.insert(
        0,
        'Seek urgent care right away for sudden, severe, or worsening testicle pain, swelling, fever, nausea, vomiting, or pain after an injury.',
      );
    }

    final doctorQuestions = <String>[
      'Could these symptoms be related to my current medications, diagnoses, routines, or recent changes?',
      'What symptoms should prompt urgent care versus a routine appointment?',
      'What patterns should I track before my next visit?',
      if (request.medications.trim().isNotEmpty)
        'Could a pharmacist or prescriber explain possible side effects or timing instructions for the medications I listed?',
    ];

    if (combinedText.contains('headache') ||
        combinedText.contains('migraine')) {
      doctorQuestions.add(
        'Should I track headache triggers such as sleep, hydration, food, stress, screen time, or light sensitivity?',
      );
    }

    return HealthLogResponse(
      summary:
          'You logged $symptoms with severity ${request.severity}/10 for $duration.$doctorNotes',
      relatedTrackedConditions: relatedConditions,
      wellnessTips: wellnessTips,
      copingStrategies: copingStrategies,
      medicationExplanation: medicationExplanation,
      warningSigns: warningSigns,
      doctorQuestions: doctorQuestions,
      disclaimer: 'This is not medical advice or a diagnosis.',
      trustedSources: TrustedHealthSources.forHealthLog(
        symptoms: request.symptoms,
        diagnosedConditions: conditionNames,
        medications: request.medications,
      ),
      source: HealthLogResponseSource.sourceSupported,
    );
  }

  String _medicationNote(String medications) {
    final cleanMedications = medications.trim();
    final lower = cleanMedications.toLowerCase();
    final noMedications =
        cleanMedications.isEmpty ||
        const {'none', 'n/a', 'na', 'no', 'no medications'}.contains(lower);

    if (noMedications) {
      return 'No current medications or prescriptions were entered.';
    }

    return 'You listed: $cleanMedications. VitaMind does not give medication instructions. Ask a pharmacist or prescriber about purpose, side effects, timing, and what to do if symptoms change.';
  }

  bool _soundsLikeSeveralDays(String duration) {
    final lower = duration.toLowerCase();
    return lower.contains('day') ||
        lower.contains('week') ||
        lower.contains('month') ||
        lower.contains('ongoing') ||
        lower.contains('persistent');
  }

  bool _mentionsImmediateMentalHealthRisk(String text) {
    return text.contains('suicide') ||
        text.contains('suicidal') ||
        text.contains('self harm') ||
        text.contains('self-harm') ||
        text.contains('hurt myself') ||
        text.contains('hurt someone');
  }
}

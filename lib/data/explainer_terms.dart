/// Whole-word keyword lists for the rule-based explainer (slice A2).
///
/// Every list keeps only words that the old substring checks already caught
/// (plural, -ing and compound forms of the original keywords), so A2 fixes
/// misfires without adding coverage. New symptoms, synonyms and the
/// `SymptomRule` catalog are slice E1 (architecture.md §11.14).
///
/// Terms are lowercase and already normalized (see `normalizeForMatch`).
/// Crisis phrases are NOT here; the crisis check keeps its own list and
/// substring matching.
class ExplainerTerms {
  const ExplainerTerms._();

  static const headache = ['headache', 'headaches'];

  static const migraine = ['migraine', 'migraines'];

  static const headacheOrMigraine = [...headache, ...migraine];

  static const anxiety = ['anxiety'];

  static const stress = [
    'stress',
    'stresses',
    'stressed',
    'stressful',
    'stressing',
    'stressor',
    'stressors',
    'distress',
    'distressed',
    'distressing',
  ];

  static const anxietyOrStress = [...anxiety, ...stress];

  static const depression = ['depression'];

  static const diabetes = ['diabetes', 'prediabetes'];

  /// Used only by the service's existing "diabetes or fatigue" tracking tip.
  /// Fatigue no longer pulls diabetes sources (A2 criterion 7).
  static const fatigue = ['fatigue', 'fatigued'];

  static const sleep = [
    'sleep',
    'sleeps',
    'sleeping',
    'sleepless',
    'sleeplessness',
    'sleepy',
    'sleepiness',
    'asleep',
  ];

  static const asthma = [
    'asthma',
    'asthmatic',
    'wheezing',
    'breath',
    'breaths',
    'breathe',
    'breathes',
    'breathing',
    'breathless',
    'breathlessness',
  ];

  static const arthritis = ['arthritis', 'osteoarthritis'];

  /// Generic pain words. "headache" is deliberately not here: the generic
  /// `ache` no longer matches inside it (A2 criterion 3).
  static const pain = [
    'pain',
    'pains',
    'painful',
    'painfully',
    'painkiller',
    'painkillers',
    'ache',
    'aches',
    'stomachache',
    'stomachaches',
    'backache',
    'backaches',
    'toothache',
    'toothaches',
    'earache',
    'earaches',
    'bellyache',
    'bellyaches',
    ...arthritis,
  ];

  static const digestive = [
    'nausea',
    'nauseated',
    'vomit',
    'vomits',
    'vomited',
    'vomiting',
    'diarrhea',
    'stomach',
    'stomachs',
    'stomachache',
    'stomachaches',
    'digestive',
    'ibs',
  ];

  static const groinPain = ['groin pain', 'groin pains'];

  /// Testicle words the service's urgent-care reminder has always used.
  static const testicle = [
    'testicle',
    'testicles',
    'testicular',
    ...groinPain,
  ];

  /// The sources list also matched "scrotal"; kept as it was.
  static const testicularSources = [...testicle, 'scrotal'];

  static const sudden = ['sudden', 'suddenly'];

  static const worstHeadache = ['worst headache', 'worst headaches'];

  /// Duration words that mean "more than a short moment" (A2 criterion 6).
  static const severalDays = [
    'day',
    'days',
    'yesterday',
    'week',
    'weeks',
    'month',
    'months',
    'ongoing',
    'persistent',
  ];
}

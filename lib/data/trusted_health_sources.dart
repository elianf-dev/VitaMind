import '../models/trusted_health_source.dart';

class TrustedHealthSources {
  const TrustedHealthSources._();

  static const medlinePlusHealthTopics = TrustedHealthSource(
    title: 'MedlinePlus Health Topics',
    organization: 'NIH / National Library of Medicine',
    description: 'Patient-friendly condition and wellness information.',
    url: 'https://medlineplus.gov/healthtopics.html',
  );

  static const medlinePlusConnect = TrustedHealthSource(
    title: 'MedlinePlus Connect',
    organization: 'NIH / National Library of Medicine',
    description: 'A future API option for matching health terms to education.',
    url: 'https://medlineplus.gov/medlineplus-connect/',
  );

  static const cdcHealthTopics = TrustedHealthSource(
    title: 'CDC Health Topics',
    organization: 'Centers for Disease Control and Prevention',
    description: 'Public-health information and prevention resources.',
    url: 'https://www.cdc.gov/health-topics.html',
  );

  static const openFdaDrugLabels = TrustedHealthSource(
    title: 'openFDA Drug Label API',
    organization: 'U.S. Food and Drug Administration',
    description:
        'Official drug-label data to reference later for medication labels.',
    url: 'https://open.fda.gov/apis/drug/label/',
  );

  static const dailyMed = TrustedHealthSource(
    title: 'DailyMed Drug Labels',
    organization: 'NIH / National Library of Medicine',
    description: 'Official medication label information published by NLM.',
    url: 'https://dailymed.nlm.nih.gov/dailymed/',
  );

  static const fdaMedicationGuides = TrustedHealthSource(
    title: 'FDA Medication Guides',
    organization: 'U.S. Food and Drug Administration',
    description: 'FDA medication safety guides and patient information.',
    url:
        'https://www.fda.gov/drugs/drug-safety-and-availability/medication-guides',
  );

  static const headache = TrustedHealthSource(
    title: 'Headache',
    organization: 'MedlinePlus / NIH',
    description: 'General headache information and when to seek care.',
    url: 'https://medlineplus.gov/headache.html',
  );

  static const migraine = TrustedHealthSource(
    title: 'Migraine',
    organization: 'MedlinePlus / NIH',
    description: 'Migraine information and common tracking context.',
    url: 'https://medlineplus.gov/migraine.html',
  );

  static const americanMigraineFoundation = TrustedHealthSource(
    title: 'Migraine Resource Library',
    organization: 'American Migraine Foundation',
    description: 'Specialty education about migraine symptoms and patterns.',
    url: 'https://americanmigrainefoundation.org/resource-library/',
  );

  static const anxiety = TrustedHealthSource(
    title: 'Anxiety',
    organization: 'MedlinePlus / NIH',
    description: 'General anxiety information and care resources.',
    url: 'https://medlineplus.gov/anxiety.html',
  );

  static const nimhAnxiety = TrustedHealthSource(
    title: 'Anxiety Disorders',
    organization: 'National Institute of Mental Health',
    description: 'Federal mental health education about anxiety disorders.',
    url: 'https://www.nimh.nih.gov/health/topics/anxiety-disorders',
  );

  static const stress = TrustedHealthSource(
    title: 'Stress',
    organization: 'MedlinePlus / NIH',
    description: 'Stress information and wellness education.',
    url: 'https://medlineplus.gov/stress.html',
  );

  static const diabetes = TrustedHealthSource(
    title: 'Diabetes',
    organization: 'MedlinePlus / NIH',
    description: 'Diabetes education and care-plan context.',
    url: 'https://medlineplus.gov/diabetes.html',
  );

  static const niddkDiabetes = TrustedHealthSource(
    title: 'Diabetes Overview',
    organization:
        'National Institute of Diabetes and Digestive and Kidney Diseases',
    description: 'Federal diabetes education and care-plan context.',
    url: 'https://www.niddk.nih.gov/health-information/diabetes/overview',
  );

  static const cdcDiabetes = TrustedHealthSource(
    title: 'Diabetes',
    organization: 'Centers for Disease Control and Prevention',
    description: 'Public-health diabetes information and prevention resources.',
    url: 'https://www.cdc.gov/diabetes/',
  );

  static const americanDiabetesAssociation = TrustedHealthSource(
    title: 'Diabetes Basics',
    organization: 'American Diabetes Association',
    description: 'Trusted nonprofit education about diabetes basics.',
    url: 'https://diabetes.org/about-diabetes',
  );

  static const asthma = TrustedHealthSource(
    title: 'Asthma',
    organization: 'MedlinePlus / NIH',
    description: 'Asthma information and symptom tracking context.',
    url: 'https://medlineplus.gov/asthma.html',
  );

  static const nhlbiAsthma = TrustedHealthSource(
    title: 'Asthma',
    organization: 'National Heart, Lung, and Blood Institute',
    description: 'Federal asthma education and care-plan context.',
    url: 'https://www.nhlbi.nih.gov/health/asthma',
  );

  static const cdcAsthma = TrustedHealthSource(
    title: 'Asthma',
    organization: 'Centers for Disease Control and Prevention',
    description: 'Public-health asthma information and resources.',
    url: 'https://www.cdc.gov/asthma/',
  );

  static const aafaAsthma = TrustedHealthSource(
    title: 'Asthma',
    organization: 'Asthma and Allergy Foundation of America',
    description: 'Trusted nonprofit education about asthma and allergies.',
    url: 'https://aafa.org/asthma/',
  );

  static const depression = TrustedHealthSource(
    title: 'Depression',
    organization: 'MedlinePlus / NIH',
    description: 'Depression information and support resources.',
    url: 'https://medlineplus.gov/depression.html',
  );

  static const nimhDepression = TrustedHealthSource(
    title: 'Depression',
    organization: 'National Institute of Mental Health',
    description: 'Federal mental health education about depression.',
    url: 'https://www.nimh.nih.gov/health/topics/depression',
  );

  static const nausea = TrustedHealthSource(
    title: 'Nausea and Vomiting',
    organization: 'MedlinePlus / NIH',
    description: 'General nausea and vomiting information.',
    url: 'https://medlineplus.gov/nauseaandvomiting.html',
  );

  static const sleepDisorders = TrustedHealthSource(
    title: 'Sleep Disorders',
    organization: 'MedlinePlus / NIH',
    description: 'General sleep disorder information and care resources.',
    url: 'https://medlineplus.gov/sleepdisorders.html',
  );

  static const pain = TrustedHealthSource(
    title: 'Pain',
    organization: 'National Center for Complementary and Integrative Health',
    description: 'Federal education about pain and complementary approaches.',
    url: 'https://www.nccih.nih.gov/health/pain',
  );

  static const arthritis = TrustedHealthSource(
    title: 'Arthritis',
    organization: 'MedlinePlus / NIH',
    description: 'Arthritis information and tracking context.',
    url: 'https://medlineplus.gov/arthritis.html',
  );

  static const digestiveDiseases = TrustedHealthSource(
    title: 'Digestive Diseases',
    organization:
        'National Institute of Diabetes and Digestive and Kidney Diseases',
    description: 'Federal education about digestive symptoms and conditions.',
    url: 'https://www.niddk.nih.gov/health-information/digestive-diseases',
  );

  static const testiclePain = TrustedHealthSource(
    title: 'Testicle Pain',
    organization: 'MedlinePlus / NIH',
    description: 'Medical encyclopedia information about testicle pain.',
    url: 'https://medlineplus.gov/ency/article/003160.htm',
  );

  static const mayoClinicTesticlePain = TrustedHealthSource(
    title: 'Testicle Pain',
    organization: 'Mayo Clinic',
    description: 'Trusted clinic information about testicle pain symptoms.',
    url:
        'https://www.mayoclinic.org/symptoms/testicle-pain/basics/definition/sym-20050942',
  );

  static const clevelandClinicTesticularPain = TrustedHealthSource(
    title: 'Testicular Pain',
    organization: 'Cleveland Clinic',
    description: 'Trusted clinic education about testicular pain.',
    url: 'https://my.clevelandclinic.org/health/symptoms/16292-testicular-pain',
  );

  static const mayoClinicSymptoms = TrustedHealthSource(
    title: 'Symptom Checker',
    organization: 'Mayo Clinic',
    description: 'Trusted clinic education for learning about symptoms.',
    url:
        'https://www.mayoclinic.org/symptom-checker/select-symptom/itt-20009075',
  );

  static const clevelandClinicHealthLibrary = TrustedHealthSource(
    title: 'Health Library',
    organization: 'Cleveland Clinic',
    description: 'Trusted clinic articles about symptoms and conditions.',
    url: 'https://my.clevelandclinic.org/health',
  );

  static List<TrustedHealthSource> forHealthLog({
    required String symptoms,
    required Iterable<String> diagnosedConditions,
    required String medications,
  }) {
    // TODO: Replace this static map with MedlinePlus Connect, CDC, openFDA,
    // and other official APIs after the MVP source-mapping flow is validated.
    final combined = [symptoms, ...diagnosedConditions].join(' ').toLowerCase();
    final sources = <TrustedHealthSource>[
      medlinePlusHealthTopics,
      medlinePlusConnect,
      cdcHealthTopics,
    ];

    void addIf(bool condition, TrustedHealthSource source) {
      if (condition && !sources.any((item) => item.url == source.url)) {
        sources.add(source);
      }
    }

    final mentionsHeadache =
        combined.contains('headache') || combined.contains('migraine');
    final mentionsStress =
        combined.contains('anxiety') || combined.contains('stress');
    final mentionsDiabetes =
        combined.contains('diabetes') || combined.contains('fatigue');
    final mentionsAsthma =
        combined.contains('asthma') ||
        combined.contains('wheezing') ||
        combined.contains('breath');
    final mentionsPain =
        combined.contains('pain') ||
        combined.contains('ache') ||
        combined.contains('arthritis');
    final mentionsDigestive =
        combined.contains('nausea') ||
        combined.contains('vomit') ||
        combined.contains('diarrhea') ||
        combined.contains('stomach') ||
        combined.contains('digestive') ||
        combined.contains('ibs');
    final mentionsTesticular =
        combined.contains('testicle') ||
        combined.contains('testicular') ||
        combined.contains('scrotal') ||
        combined.contains('groin pain');

    addIf(mentionsHeadache, headache);
    addIf(combined.contains('migraine'), migraine);
    addIf(mentionsHeadache, americanMigraineFoundation);
    addIf(mentionsStress, anxiety);
    addIf(mentionsStress, nimhAnxiety);
    addIf(combined.contains('stress'), stress);
    addIf(mentionsDiabetes, diabetes);
    addIf(mentionsDiabetes, niddkDiabetes);
    addIf(mentionsDiabetes, cdcDiabetes);
    addIf(mentionsDiabetes, americanDiabetesAssociation);
    addIf(mentionsAsthma, asthma);
    addIf(mentionsAsthma, nhlbiAsthma);
    addIf(mentionsAsthma, cdcAsthma);
    addIf(mentionsAsthma, aafaAsthma);
    addIf(combined.contains('depression'), depression);
    addIf(combined.contains('depression'), nimhDepression);
    addIf(mentionsDigestive, nausea);
    addIf(mentionsDigestive, digestiveDiseases);
    addIf(combined.contains('sleep'), sleepDisorders);
    addIf(mentionsPain, pain);
    addIf(combined.contains('arthritis'), arthritis);
    addIf(mentionsTesticular, testiclePain);
    addIf(mentionsTesticular, mayoClinicTesticlePain);
    addIf(mentionsTesticular, clevelandClinicTesticularPain);

    final medicationText = medications.trim().toLowerCase();
    final hasMedication =
        medicationText.isNotEmpty &&
        !const {
          'none',
          'n/a',
          'na',
          'no',
          'no medications',
        }.contains(medicationText);
    addIf(hasMedication, openFdaDrugLabels);
    addIf(hasMedication, dailyMed);
    addIf(hasMedication, fdaMedicationGuides);
    addIf(sources.length <= 3, mayoClinicSymptoms);
    addIf(sources.length <= 4, clevelandClinicHealthLibrary);

    return sources;
  }
}

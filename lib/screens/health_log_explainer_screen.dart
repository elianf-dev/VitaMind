import 'package:flutter/material.dart';

import '../models/health_log_entry.dart';
import '../models/health_log_request.dart';
import '../models/health_log_response.dart';
import '../models/diagnosed_condition.dart';
import '../models/wellness_goal.dart';
import '../services/health_log_explainer_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_section_header.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';
import '../widgets/trusted_source_list.dart';

class HealthLogExplainerScreen extends StatefulWidget {
  const HealthLogExplainerScreen({
    super.key,
    required this.localStorageService,
    this.explainerService = const HealthLogExplainerService(),
  });

  final LocalStorageService localStorageService;
  final HealthLogExplainerService explainerService;

  @override
  State<HealthLogExplainerScreen> createState() =>
      _HealthLogExplainerScreenState();
}

class _HealthLogExplainerScreenState extends State<HealthLogExplainerScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _doctorNotesController = TextEditingController();

  HealthLogResponse? _response;
  List<DiagnosedCondition> _conditions = [];
  List<WellnessGoal> _goals = [];
  double _severity = 5;
  bool _loadingProfile = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _durationController.dispose();
    _medicationsController.dispose();
    _doctorNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalization() async {
    final results = await Future.wait([
      widget.localStorageService.loadDiagnosedConditions(),
      widget.localStorageService.loadWellnessGoals(),
      widget.localStorageService.loadMedications(),
    ]);

    if (!mounted) {
      return;
    }

    final medications = results[2] as List<String>;
    setState(() {
      _conditions = results[0] as List<DiagnosedCondition>;
      _goals = results[1] as List<WellnessGoal>;
      if (_medicationsController.text.trim().isEmpty &&
          medications.isNotEmpty) {
        _medicationsController.text = medications.join(', ');
      }
      _loadingProfile = false;
    });
  }

  Future<void> _explainHealthLog() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _response = null;
    });

    final request = HealthLogRequest(
      symptoms: _symptomsController.text,
      severity: _severity.round(),
      duration: _durationController.text,
      medications: _medicationsController.text,
      doctorNotes: _doctorNotesController.text,
      diagnosedConditions: _conditions,
      wellnessGoals: _goals,
    );

    final response = await widget.explainerService.explainHealthLog(request);
    final log = HealthLogEntry.create(request: request, response: response);
    await _saveHealthLog(log);

    if (!mounted) {
      return;
    }

    setState(() {
      _response = response;
      _loading = false;
    });
  }

  Future<void> _saveHealthLog(HealthLogEntry log) async {
    // TODO: Sync health log explanations to Firestore later if the user opts in.
    await widget.localStorageService.addHealthLogEntry(log);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Log Explainer'),
        actions: [
          IconButton(
            tooltip: 'Explanation history',
            onPressed: () =>
                Navigator.of(context).pushNamed('/health-log-history'),
            icon: const Icon(Icons.history_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppSpacing.page,
                children: [
                  const VitaMindPageHeader(
                    title: 'Understand your health log',
                    subtitle:
                        'Enter symptoms, context, and notes. VitaMind will use safe rules and trusted source links to help you track patterns.',
                  ),
                  const DisclaimerCard(
                    text:
                        'This feature does not diagnose, prescribe treatment, or replace your doctor. This is not medical advice or a diagnosis.',
                  ),
                  const AppSectionHeader(title: 'Symptoms'),
                  TextField(
                    controller: _symptomsController,
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms',
                      hintText: 'Example: headache, fatigue, nausea',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const AppSectionHeader(title: 'Duration and severity'),
                  VitaMindCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Severity ${_severity.round()}/10',
                          style: AppTextStyles.cardTitle(context),
                        ),
                        Slider(
                          value: _severity,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _severity.round().toString(),
                          onChanged: (value) =>
                              setState(() => _severity = value),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      hintText: 'Example: 2 days, since this morning',
                    ),
                  ),
                  const AppSectionHeader(title: 'Medications / prescriptions'),
                  TextField(
                    controller: _medicationsController,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Current medications / prescriptions',
                      hintText: 'List anything prescribed or taken regularly',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const AppSectionHeader(title: 'Doctor notes'),
                  TextField(
                    controller: _doctorNotesController,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Notes from doctor',
                      hintText:
                          'Add visit notes, instructions, or lab follow-ups',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  VitaMindPrimaryButton(
                    onPressed: _loading ? null : _explainHealthLog,
                    loading: _loading,
                    icon: Icons.fact_check_outlined,
                    label: 'Explain Health Log',
                  ),
                  if (_response != null) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const _ResponseSourceBanner(),
                    const SizedBox(height: AppSpacing.sm),
                    _HealthResultCards(response: _response!),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ResponseSourceBanner extends StatelessWidget {
  const _ResponseSourceBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return VitaMindCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: const Color(0xFFE7F4EF),
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free version: rule-based explanation with trusted source links.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthResultCards extends StatelessWidget {
  const _HealthResultCards({required this.response});

  final HealthLogResponse response;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResultCard(
          icon: Icons.summarize_outlined,
          title: 'Plain-language summary',
          color: AppColors.primary,
          child: Text(response.summary),
        ),
        _ResultCard(
          icon: Icons.lightbulb_outline,
          title: 'Related tracked conditions',
          color: AppColors.blue,
          child: _BulletList(items: response.relatedTrackedConditions),
        ),
        _ResultCard(
          icon: Icons.spa_outlined,
          title: 'Possible wellness factors',
          color: AppColors.primary,
          child: _BulletList(items: response.wellnessTips),
        ),
        _ResultCard(
          icon: Icons.self_improvement_outlined,
          title: 'Symptom coping strategies',
          color: AppColors.warning,
          child: _BulletList(items: response.copingStrategies),
        ),
        _ResultCard(
          icon: Icons.medication_outlined,
          title: 'Medication note',
          color: AppColors.purple,
          child: Text(response.medicationExplanation),
        ),
        _ResultCard(
          icon: Icons.warning_amber_outlined,
          title: 'Warning signs',
          color: AppColors.warning,
          child: _BulletList(items: response.warningSigns),
        ),
        _ResultCard(
          icon: Icons.quiz_outlined,
          title: 'Questions to ask your doctor',
          color: AppColors.primary,
          child: _BulletList(items: response.doctorQuestions),
        ),
        if (response.trustedSources.isNotEmpty)
          _ResultCard(
            icon: Icons.verified_outlined,
            title: 'Trusted sources',
            color: AppColors.blue,
            child: TrustedSourceList(sources: response.trustedSources),
          ),
        _ResultCard(
          icon: Icons.info_outline,
          title: 'Disclaimer',
          color: AppColors.mutedText,
          child: Text(
            response.disclaimer,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return VitaMindCard(
      padding: AppSpacing.cardLarge,
      borderColor: color.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTextStyles.cardTitle(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.bodyText,
              height: 1.4,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('- '),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

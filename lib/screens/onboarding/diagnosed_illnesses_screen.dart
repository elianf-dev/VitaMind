import 'package:flutter/material.dart';

import '../../models/diagnosed_condition.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/vita_mind_buttons.dart';
import '../../widgets/vita_mind_card.dart';
import '../../widgets/vita_mind_page_header.dart';

class DiagnosedIllnessesScreen extends StatefulWidget {
  const DiagnosedIllnessesScreen({
    super.key,
    required this.localStorageService,
    this.isOnboarding = false,
  });

  final LocalStorageService localStorageService;
  final bool isOnboarding;

  @override
  State<DiagnosedIllnessesScreen> createState() =>
      _DiagnosedIllnessesScreenState();
}

class _DiagnosedIllnessesScreenState extends State<DiagnosedIllnessesScreen> {
  static const List<String> _commonConditions = [
    'Anxiety',
    'Depression',
    'Diabetes',
    'Asthma',
    'Chronic pain',
    'Migraine',
    'Arthritis',
    'ADHD',
    'IBS',
    'Other',
  ];

  static const List<String> _commonSymptoms = [
    'Fatigue',
    'Pain',
    'Headache',
    'Stress',
    'Brain Fog',
    'Sleep changes',
    'Digestive discomfort',
  ];

  final TextEditingController _customConditionController =
      TextEditingController();
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _customSymptomController =
      TextEditingController();

  final List<DiagnosedCondition> _conditions = [];
  final List<String> _medications = [];
  final List<String> _symptoms = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _customConditionController.dispose();
    _medicationController.dispose();
    _customSymptomController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      widget.localStorageService.loadDiagnosedConditions(),
      widget.localStorageService.loadMedications(),
      widget.localStorageService.loadCommonSymptoms(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _conditions
        ..clear()
        ..addAll(results[0] as List<DiagnosedCondition>);
      _medications
        ..clear()
        ..addAll(results[1] as List<String>);
      _symptoms
        ..clear()
        ..addAll(results[2] as List<String>);
      _loading = false;
    });
  }

  bool _hasCondition(String name) {
    return _conditions.any(
      (condition) => condition.name.toLowerCase() == name.toLowerCase(),
    );
  }

  void _toggleCondition(String name) {
    setState(() {
      if (_hasCondition(name)) {
        _conditions.removeWhere(
          (condition) => condition.name.toLowerCase() == name.toLowerCase(),
        );
      } else {
        _conditions.add(DiagnosedCondition.create(name: name));
      }
    });
  }

  void _addCustomCondition() {
    final name = _customConditionController.text.trim();
    if (name.isEmpty || _hasCondition(name)) {
      return;
    }

    setState(() {
      _conditions.add(DiagnosedCondition.create(name: name));
      _customConditionController.clear();
    });
  }

  void _addMedication() {
    final medication = _medicationController.text.trim();
    if (medication.isEmpty || _medications.contains(medication)) {
      return;
    }

    setState(() {
      _medications.add(medication);
      _medicationController.clear();
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_symptoms.contains(symptom)) {
        _symptoms.remove(symptom);
      } else {
        _symptoms.add(symptom);
      }
    });
  }

  void _addCustomSymptom() {
    final symptom = _customSymptomController.text.trim();
    if (symptom.isEmpty || _symptoms.contains(symptom)) {
      return;
    }

    setState(() {
      _symptoms.add(symptom);
      _customSymptomController.clear();
    });
  }

  Future<void> _saveAndContinue() async {
    setState(() => _saving = true);

    await widget.localStorageService.saveDiagnosedConditions(_conditions);
    await widget.localStorageService.saveMedications(_medications);
    await widget.localStorageService.saveCommonSymptoms(_symptoms);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacementNamed('/onboarding/goals');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOnboarding ? 'Health Profile' : 'Diagnosed Conditions',
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppSpacing.page,
                children: [
                  const VitaMindPageHeader(
                    title: 'Diagnosed Conditions',
                    subtitle:
                        'Only add conditions you have already been diagnosed with or personally want to track.',
                  ),
                  VitaMindCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Common conditions',
                          style: AppTextStyles.cardTitle(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final condition in _commonConditions)
                              FilterChip(
                                label: Text(condition),
                                selected: _hasCondition(condition),
                                onSelected: (_) => _toggleCondition(condition),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AddField(
                          controller: _customConditionController,
                          label: 'Custom condition',
                          hint: 'Example: POTS, endometriosis',
                          onAdd: _addCustomCondition,
                        ),
                      ],
                    ),
                  ),
                  if (_conditions.isNotEmpty) ...[
                    _ChipSection(
                      title: 'Tracking',
                      items: _conditions
                          .map((condition) => condition.name)
                          .toList(),
                      onDeleted: (name) => _toggleCondition(name),
                    ),
                  ] else ...[
                    const EmptyStateCard(
                      icon: Icons.health_and_safety_outlined,
                      title: 'No conditions added',
                      body:
                          'You can skip this or add known conditions whenever you want.',
                    ),
                  ],
                  const AppSectionHeader(
                    title: 'Current medications / prescriptions',
                    subtitle:
                        'Optional. Keep names general if you prefer less detail.',
                  ),
                  _AddField(
                    controller: _medicationController,
                    label: 'Medication or prescription',
                    hint: 'Example: inhaler, migraine medication',
                    onAdd: _addMedication,
                  ),
                  if (_medications.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ChipSection(
                      title: 'Medications added',
                      items: _medications,
                      onDeleted: (item) =>
                          setState(() => _medications.remove(item)),
                    ),
                  ],
                  const AppSectionHeader(
                    title: 'Common symptoms to track',
                    subtitle:
                        'Pick symptoms you often want quick access to in VitaMind.',
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final symptom in _commonSymptoms)
                        FilterChip(
                          label: Text(symptom),
                          selected: _symptoms.contains(symptom),
                          onSelected: (_) => _toggleSymptom(symptom),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _AddField(
                    controller: _customSymptomController,
                    label: 'Custom symptom',
                    hint: 'Example: dizziness',
                    onAdd: _addCustomSymptom,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  VitaMindPrimaryButton(
                    onPressed: _saveAndContinue,
                    loading: _saving,
                    icon: widget.isOnboarding
                        ? Icons.arrow_forward
                        : Icons.save_outlined,
                    label: widget.isOnboarding ? 'Continue' : 'Save Changes',
                  ),
                ],
              ),
      ),
    );
  }
}

class _AddField extends StatelessWidget {
  const _AddField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label, hintText: hint),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          tooltip: 'Add',
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.items,
    required this.onDeleted,
  });

  final String title;
  final List<String> items;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    return VitaMindCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                InputChip(label: Text(item), onDeleted: () => onDeleted(item)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/symptom_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/entry_merge.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.localStorageService,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final LocalStorageService localStorageService;

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<SymptomEntry> _entries = [];
  final List<String> _symptoms = [
    'Fatigue',
    'Pain',
    'Headache',
    'Stress',
    'Brain Fog',
    'Nausea',
    'Sleep Issues',
  ];

  String _selectedSymptom = 'Fatigue';
  double _severity = 5;
  bool _loadingEntries = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final userId = widget.authService.userId;
    final localEntries = await widget.localStorageService.loadSymptomEntries();
    var entries = localEntries;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        final cloudEntries = await widget.firestoreService.loadSymptomEntries(
          userId,
        );
        entries = mergeEntriesById(
          localEntries: localEntries,
          cloudEntries: cloudEntries,
          idOf: (entry) => entry.id,
          createdAtOf: (entry) => entry.createdAt,
        );
        await widget.localStorageService.saveSymptomEntries(entries);

        final cloudIds = cloudEntries.map((entry) => entry.id).toSet();
        await Future.wait(
          localEntries
              .where((entry) => !cloudIds.contains(entry.id))
              .map(
                (entry) =>
                    widget.firestoreService.saveSymptomEntry(userId, entry),
              ),
        );
      } on Object catch (error) {
        debugPrint('VitaMind: failed to sync symptom entries: $error');
        // Keep the tracker usable if Firestore is offline or rules need work.
      }
    }
    final commonSymptoms = await widget.localStorageService
        .loadCommonSymptoms();

    if (!mounted) {
      return;
    }

    setState(() {
      _entries
        ..clear()
        ..addAll(entries);
      for (final symptom in commonSymptoms) {
        if (!_symptoms.contains(symptom)) {
          _symptoms.add(symptom);
        }
      }
      _loadingEntries = false;
    });
  }

  Future<void> _saveSymptom() async {
    final entry = SymptomEntry.create(
      symptom: _selectedSymptom,
      severity: _severity.round(),
      duration: _durationController.text,
      notes: _notesController.text,
    );

    setState(() {
      _entries.insert(0, entry);
      _durationController.clear();
      _notesController.clear();
    });

    await widget.localStorageService.addSymptomEntry(entry);

    final userId = widget.authService.userId;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        await widget.firestoreService.saveSymptomEntry(userId, entry);
      } on Object catch (error) {
        debugPrint('VitaMind: failed to save symptom entry to cloud: $error');
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptom saved locally. Cloud sync is unavailable.'),
          ),
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.symptom} saved at ${entry.severity}/10')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final recentEntries = _entries.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Tracker')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            const VitaMindPageHeader(
              title: 'How strong is this symptom today?',
              subtitle:
                  'Choose a symptom, rate severity, and add any context you want to remember.',
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final symptom in _symptoms)
                  ChoiceChip(
                    label: Text(symptom),
                    selected: _selectedSymptom == symptom,
                    onSelected: (_) {
                      setState(() => _selectedSymptom = symptom);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            VitaMindCard(
              padding: AppSpacing.cardLarge,
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
                    onChanged: (value) => setState(() => _severity = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                hintText: 'Example: 2 days, since this morning',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Triggers, timing, or anything that changed',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            VitaMindPrimaryButton(
              onPressed: _loadingEntries ? null : _saveSymptom,
              icon: Icons.check,
              label: 'Save Symptom',
            ),
            if (_loadingEntries) ...[
              const SizedBox(height: AppSpacing.lg),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (recentEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Recent symptom logs',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in recentEntries)
                VitaMindCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.symptom} at ${entry.severity}/10',
                        style: AppTextStyles.cardTitle(context),
                      ),
                      if (entry.duration.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text('Duration: ${entry.duration}'),
                      ],
                      if (entry.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(entry.notes),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/mood_choices.dart';
import '../models/mood_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/mood_log_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/entry_merge.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';
import '../widgets/mood_option.dart';
import '../widgets/support_nudge_card.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.localStorageService,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final LocalStorageService localStorageService;

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final TextEditingController _notesController = TextEditingController();
  final List<MoodEntry> _entries = [];

  // Nothing is preselected so the default never nudges the answer.
  int? _selectedMoodIndex;
  bool _loadingEntries = true;
  bool _showSupportNudge = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final userId = widget.authService.userId;
    final localEntries = await widget.localStorageService.loadMoodEntries();
    var entries = localEntries;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        final cloudEntries = await widget.firestoreService.loadMoodEntries(
          userId,
        );
        entries = mergeEntriesById(
          localEntries: localEntries,
          cloudEntries: cloudEntries,
          idOf: (entry) => entry.id,
          createdAtOf: (entry) => entry.createdAt,
        );
        await widget.localStorageService.saveMoodEntries(entries);

        final cloudIds = cloudEntries.map((entry) => entry.id).toSet();
        await Future.wait(
          localEntries
              .where((entry) => !cloudIds.contains(entry.id))
              .map(
                (entry) => widget.firestoreService.saveMoodEntry(userId, entry),
              ),
        );
      } on Object catch (error) {
        debugPrint('VitaMind: failed to sync mood entries: $error');
        // Keep the tracker usable if Firestore is offline or rules need work.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _entries
        ..clear()
        ..addAll(entries);
      _loadingEntries = false;
    });
  }

  Future<void> _saveMood() async {
    final selectedIndex = _selectedMoodIndex;
    if (selectedIndex == null) {
      return;
    }
    final mood = moodChoices[selectedIndex];
    final entry = MoodEntry.create(
      emoji: mood.emoji,
      label: mood.label,
      notes: _notesController.text.trim(),
    );

    setState(() {
      _entries.insert(0, entry);
      _notesController.clear();
      _selectedMoodIndex = null;
      _showSupportNudge = mood.offerSupport;
    });

    final synced = await recordMoodEntry(
      entry: entry,
      authService: widget.authService,
      firestoreService: widget.firestoreService,
      localStorageService: widget.localStorageService,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? '${mood.label} mood saved'
              : 'Mood saved locally. Cloud sync is unavailable.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentEntries = _entries.take(3).toList();

    return SafeArea(
      child: ListView(
        padding: AppSpacing.tabPage,
        children: [
          const VitaMindPageHeader(
            title: 'Mood Tracker',
            subtitle:
                'Choose the mood that feels closest, then add any notes you want to remember.',
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (var index = 0; index < moodChoices.length; index++)
                MoodOption(
                  emoji: moodChoices[index].emoji,
                  label: moodChoices[index].label,
                  selected: _selectedMoodIndex == index,
                  onTap: () => setState(() => _selectedMoodIndex = index),
                ),
            ],
          ),
          if (_showSupportNudge)
            SupportNudgeCard(
              onDismiss: () => setState(() => _showSupportNudge = false),
            ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 7,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'What influenced your mood today?',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VitaMindPrimaryButton(
            onPressed: _loadingEntries || _selectedMoodIndex == null
                ? null
                : _saveMood,
            icon: Icons.check,
            label: 'Save Mood',
          ),
          if (_loadingEntries) ...[
            const SizedBox(height: AppSpacing.lg),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (recentEntries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Recent mood entries',
              style: AppTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in recentEntries)
              VitaMindCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text(entry.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.notes.trim().isEmpty
                            ? entry.label
                            : '${entry.label} - ${entry.notes}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardBody(
                          context,
                        )?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

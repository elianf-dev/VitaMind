import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/entry_merge.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';
import '../widgets/mood_option.dart';

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

class _MoodChoice {
  const _MoodChoice(this.emoji, this.label);

  final String emoji;
  final String label;
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final TextEditingController _notesController = TextEditingController();
  final List<MoodEntry> _entries = [];
  final List<_MoodChoice> _moods = const [
    _MoodChoice('😄', 'Happy'),
    _MoodChoice('🙂', 'Calm'),
    _MoodChoice('😐', 'Okay'),
    _MoodChoice('😟', 'Low'),
    _MoodChoice('😣', 'Anxious'),
  ];

  int _selectedMoodIndex = 1;
  bool _loadingEntries = true;

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
      } on Object {
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
    final mood = _moods[_selectedMoodIndex];
    final entry = MoodEntry.create(
      emoji: mood.emoji,
      label: mood.label,
      notes: _notesController.text.trim(),
    );

    setState(() {
      _entries.insert(0, entry);
      _notesController.clear();
    });

    await widget.localStorageService.addMoodEntry(entry);

    final userId = widget.authService.userId;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        await widget.firestoreService.saveMoodEntry(userId, entry);
      } on Object {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood saved locally. Cloud sync is unavailable.'),
          ),
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${mood.label} mood saved')));
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
              for (var index = 0; index < _moods.length; index++)
                MoodOption(
                  emoji: _moods[index].emoji,
                  label: _moods[index].label,
                  selected: _selectedMoodIndex == index,
                  onTap: () => setState(() => _selectedMoodIndex = index),
                ),
            ],
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
            onPressed: _loadingEntries ? null : _saveMood,
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

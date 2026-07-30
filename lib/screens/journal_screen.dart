import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/entry_merge.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.localStorageService,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final LocalStorageService localStorageService;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final List<JournalEntry> _journalEntries = [];
  bool _loadingEntries = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final userId = widget.authService.userId;
    final localEntries = await widget.localStorageService.loadJournalEntries();
    var entries = localEntries;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        final cloudEntries = await widget.firestoreService.loadJournalEntries(
          userId,
        );
        entries = mergeEntriesById(
          localEntries: localEntries,
          cloudEntries: cloudEntries,
          idOf: (entry) => entry.id,
          createdAtOf: (entry) => entry.createdAt,
        );
        await widget.localStorageService.saveJournalEntries(entries);

        final cloudIds = cloudEntries.map((entry) => entry.id).toSet();
        await Future.wait(
          localEntries
              .where((entry) => !cloudIds.contains(entry.id))
              .map(
                (entry) =>
                    widget.firestoreService.saveJournalEntry(userId, entry),
              ),
        );
      } on Object catch (error) {
        debugPrint('VitaMind: failed to sync journal entries: $error');
        // Keep the journal usable if Firestore is offline or rules need work.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _journalEntries
        ..clear()
        ..addAll(entries);
      _loadingEntries = false;
    });
  }

  Future<void> _saveJournal() async {
    final text = _journalController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a quick note before saving')),
      );
      return;
    }

    final entry = JournalEntry.create(text);

    setState(() {
      _journalEntries.insert(0, entry);
      _journalController.clear();
    });

    await widget.localStorageService.addJournalEntry(entry);

    final userId = widget.authService.userId;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        await widget.firestoreService.saveJournalEntry(userId, entry);
      } on Object catch (error) {
        debugPrint('VitaMind: failed to save journal entry to cloud: $error');
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal saved locally. Cloud sync is unavailable.'),
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
    ).showSnackBar(const SnackBar(content: Text('Journal entry saved')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: AppSpacing.tabPage,
        children: [
          const VitaMindPageHeader(
            title: 'Journal',
            subtitle: 'Capture a thought, pattern, or small win from today.',
          ),
          TextField(
            controller: _journalController,
            minLines: 9,
            maxLines: 14,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Today’s reflection',
              hintText: 'Start writing here...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VitaMindPrimaryButton(
            onPressed: _loadingEntries ? null : _saveJournal,
            icon: Icons.save_outlined,
            label: 'Save Journal',
          ),
          if (_loadingEntries) ...[
            const SizedBox(height: AppSpacing.lg),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: AppSpacing.xxl),
          if (_journalEntries.isEmpty && !_loadingEntries)
            const EmptyStateCard(
              icon: Icons.article_outlined,
              title: 'No journal entries yet',
              body: 'Saved reflections will appear here.',
            )
          else if (_journalEntries.isNotEmpty) ...[
            Text('Saved entries', style: AppTextStyles.sectionTitle(context)),
            const SizedBox(height: AppSpacing.md),
            for (final entry in _journalEntries)
              _JournalEntryCard(
                entry: entry,
                onTap: () => _openJournalEntry(entry),
              ),
          ],
        ],
      ),
    );
  }

  void _openJournalEntry(JournalEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _JournalEntryDetail(entry: entry),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return VitaMindCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(
            Icons.article_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          entry.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _formatDate(entry.createdAt),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _JournalEntryDetail extends StatelessWidget {
  const _JournalEntryDetail({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            32,
          ),
          children: [
            Text(
              _formatDate(entry.createdAt),
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            VitaMindCard(
              padding: AppSpacing.cardLarge,
              child: Text(
                entry.text,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.bodyText,
                  height: 1.45,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${months[local.month - 1]} ${local.day}, ${local.year} at $hour:$minute $period';
}

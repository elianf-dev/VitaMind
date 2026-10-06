import 'package:flutter/material.dart';

import '../models/health_log_entry.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/trusted_source_list.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

class HealthLogHistoryScreen extends StatefulWidget {
  const HealthLogHistoryScreen({super.key, required this.localStorageService});

  final LocalStorageService localStorageService;

  @override
  State<HealthLogHistoryScreen> createState() => _HealthLogHistoryScreenState();
}

class _HealthLogHistoryScreenState extends State<HealthLogHistoryScreen> {
  List<HealthLogEntry> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await widget.localStorageService.loadHealthLogEntries();

    if (!mounted) {
      return;
    }

    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  void _openLog(HealthLogEntry log) {
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AppMotion.overlay(context),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _HealthLogEntryDetail(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Log History')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLogs,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              const VitaMindPageHeader(
                title: 'Saved health explanations',
                subtitle:
                    'Review previous Health Log Explainer results and the symptoms you entered.',
              ),
              if (_loading)
                const LinearProgressIndicator(minHeight: 3)
              else if (_logs.isEmpty)
                const EmptyStateCard(
                  icon: Icons.history_outlined,
                  title: 'No explanations saved yet',
                  body:
                      'Use Health Log Explainer and VitaMind will save each response here.',
                )
              else
                for (final log in _logs)
                  _HealthLogEntryCard(log: log, onTap: () => _openLog(log)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthLogEntryCard extends StatelessWidget {
  const _HealthLogEntryCard({required this.log, required this.onTap});

  final HealthLogEntry log;
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
            Icons.fact_check_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          log.request.symptoms.trim().isEmpty
              ? 'Health explanation'
              : log.request.symptoms.trim(),
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
            '${_formatDate(log.createdAt)}\nSeverity ${log.request.severity}/10',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.35,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _HealthLogEntryDetail extends StatelessWidget {
  const _HealthLogEntryDetail({required this.log});

  final HealthLogEntry log;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
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
              'Explanation from ${_formatDate(log.createdAt)}',
              style: textTheme.titleLarge?.copyWith(
                color: const Color(0xFF173B35),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              icon: Icons.edit_note_outlined,
              title: 'What you entered',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailLine(label: 'Symptoms', value: log.request.symptoms),
                  _DetailLine(
                    label: 'Severity',
                    value: '${log.request.severity}/10',
                  ),
                  _DetailLine(label: 'Duration', value: log.request.duration),
                  _DetailLine(
                    label: 'Medications',
                    value: log.request.medications,
                  ),
                  _DetailLine(
                    label: 'Doctor notes',
                    value: log.request.doctorNotes,
                  ),
                ],
              ),
            ),
            _DetailSection(
              icon: Icons.summarize_outlined,
              title: 'Summary',
              child: Text(log.response.summary),
            ),
            _DetailSection(
              icon: Icons.spa_outlined,
              title: 'Wellness tips',
              child: _BulletList(items: log.response.wellnessTips),
            ),
            _DetailSection(
              icon: Icons.self_improvement_outlined,
              title: 'Coping strategies',
              child: _BulletList(items: log.response.copingStrategies),
            ),
            _DetailSection(
              icon: Icons.medication_outlined,
              title: 'Medication note',
              child: Text(log.response.medicationExplanation),
            ),
            _DetailSection(
              icon: Icons.warning_amber_outlined,
              title: 'Warning signs',
              child: _BulletList(items: log.response.warningSigns),
            ),
            _DetailSection(
              icon: Icons.quiz_outlined,
              title: 'Questions for a doctor',
              child: _BulletList(items: log.response.doctorQuestions),
            ),
            if (log.response.trustedSources.isNotEmpty)
              _DetailSection(
                icon: Icons.verified_outlined,
                title: 'Trusted sources',
                child: TrustedSourceList(sources: log.response.trustedSources),
              ),
            _DetailSection(
              icon: Icons.info_outline,
              title: 'Disclaimer',
              child: Text(
                log.response.disclaimer,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return VitaMindCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTextStyles.cardTitle(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF34534B),
              height: 1.4,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'Not entered' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(
            context,
          ).style.copyWith(color: const Color(0xFF34534B), height: 1.35),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: cleanValue),
          ],
        ),
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

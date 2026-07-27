import 'package:flutter/material.dart';

import '../models/diagnosed_condition.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/symptom_entry.dart';
import '../models/wellness_goal.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/vita_mind_action_card.dart';
import '../widgets/vita_mind_page_header.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.localStorageService});

  final LocalStorageService localStorageService;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<DiagnosedCondition> _conditions = [];
  List<WellnessGoal> _goals = [];
  List<MoodEntry> _moods = [];
  List<SymptomEntry> _symptoms = [];
  List<JournalEntry> _journals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInsightsContext();
  }

  Future<void> _loadInsightsContext() async {
    final results = await Future.wait([
      widget.localStorageService.loadDiagnosedConditions(),
      widget.localStorageService.loadWellnessGoals(),
      widget.localStorageService.loadMoodEntries(),
      widget.localStorageService.loadSymptomEntries(),
      widget.localStorageService.loadJournalEntries(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _conditions = results[0] as List<DiagnosedCondition>;
      _goals = results[1] as List<WellnessGoal>;
      _moods = results[2] as List<MoodEntry>;
      _symptoms = results[3] as List<SymptomEntry>;
      _journals = results[4] as List<JournalEntry>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: AppSpacing.tabPage,
        children: [
          const VitaMindPageHeader(
            title: 'Insights',
            subtitle:
                'Gentle patterns will appear here as you keep checking in.',
          ),
          if (_loading) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: AppSpacing.md),
          ],
          ..._buildRuleBasedInsights(),
          if (_conditions.isNotEmpty)
            _InsightCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Condition-aware tracking',
              description:
                  'You are tracking ${_conditions.map((condition) => condition.name).take(2).join(', ')}. Keep pairing symptoms with notes so your patterns are easier to discuss.',
              color: AppColors.secondary,
            ),
          if (_goals.any((goal) => goal.active))
            const _InsightCard(
              icon: Icons.flag_outlined,
              title: 'Goal support',
              description:
                  'Active goals can make check-ins more useful by connecting habits with mood, symptoms, and energy.',
              color: AppColors.purple,
            ),
          if (!_loading &&
              _conditions.isEmpty &&
              _goals.isEmpty &&
              _moods.isEmpty &&
              _symptoms.isEmpty &&
              _journals.isEmpty)
            const _InsightCard(
              icon: Icons.auto_graph,
              title: 'Start with a few check-ins',
              description:
                  'Mood, symptom, journal, and goal logs will create simple pattern notes here.',
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRuleBasedInsights() {
    if (_loading) {
      return const [];
    }

    final insights = <Widget>[];
    final journalsThisWeek = _journals
        .where((entry) => _isWithinLastDays(entry.createdAt, 7))
        .map((entry) => _dayKey(entry.createdAt))
        .toSet()
        .length;
    final headacheLogs = _symptoms
        .where((entry) => entry.symptom.toLowerCase().contains('headache'))
        .length;
    final stressDays = _symptoms
        .where((entry) => entry.symptom.toLowerCase().contains('stress'))
        .map((entry) => _dayKey(entry.createdAt))
        .toSet();
    final headacheStressOverlap = _symptoms.where((entry) {
      return entry.symptom.toLowerCase().contains('headache') &&
          stressDays.contains(_dayKey(entry.createdAt));
    }).length;
    final positiveMoodCount = _moods.where((entry) {
      final label = entry.label.toLowerCase();
      return label.contains('happy') || label.contains('calm');
    }).length;
    final activeGoalProgress = _goals
        .where((goal) => goal.active && goal.progress > 0)
        .length;

    insights.add(
      _InsightCard(
        icon: Icons.edit_note_outlined,
        title: 'Journal rhythm',
        description: journalsThisWeek == 0
            ? 'No journal days logged this week yet.'
            : 'You journaled $journalsThisWeek day${journalsThisWeek == 1 ? '' : 's'} this week.',
        color: AppColors.purple,
      ),
    );

    if (headacheLogs > 0) {
      insights.add(
        _InsightCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Headache tracking',
          description:
              'You logged headache $headacheLogs time${headacheLogs == 1 ? '' : 's'}. Try pairing future logs with sleep, hydration, stress, screen time, and notes.',
          color: AppColors.blue,
        ),
      );
    }

    if (headacheStressOverlap > 0) {
      insights.add(
        _InsightCard(
          icon: Icons.spa_outlined,
          title: 'Stress and headache same-day logs',
          description:
              'Stress and headache appeared on the same day $headacheStressOverlap time${headacheStressOverlap == 1 ? '' : 's'}. This is only a tracking pattern, not a diagnosis.',
          color: AppColors.warning,
        ),
      );
    }

    if (_moods.isNotEmpty) {
      insights.add(
        _InsightCard(
          icon: Icons.mood_outlined,
          title: 'Mood check-ins',
          description:
              '$positiveMoodCount of your ${_moods.length} mood entries were positive or calm.',
          color: AppColors.primary,
        ),
      );
    }

    if (activeGoalProgress > 0) {
      insights.add(
        _InsightCard(
          icon: Icons.flag_outlined,
          title: 'Goal progress',
          description:
              'You have progress on $activeGoalProgress active goal${activeGoalProgress == 1 ? '' : 's'}. Keep goals small enough to complete.',
          color: AppColors.secondary,
        ),
      );
    }

    return insights;
  }

  bool _isWithinLastDays(DateTime date, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return date.isAfter(cutoff);
  }

  String _dayKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month}-${local.day}';
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return VitaMindActionCard(
      icon: icon,
      title: title,
      subtitle: description,
      accentColor: color,
    );
  }
}

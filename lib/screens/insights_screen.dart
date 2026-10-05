import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../models/diagnosed_condition.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/symptom_entry.dart';
import '../models/wellness_goal.dart';
import '../services/local_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/insight_math.dart';
import '../widgets/app_section_header.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/insights/daily_line_chart.dart';
import '../widgets/insights/mood_calendar.dart';
import '../widgets/vita_mind_action_card.dart';
import '../widgets/vita_mind_card.dart';

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
  int _trendDays = 7;
  String? _selectedSymptom;

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
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your patterns',
                  style: AppTextStyles.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Patterns worth noticing',
                  style: AppTextStyles.display(size: 26),
                ),
              ],
            ),
          ),
          if (_loading) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: AppSpacing.md),
          ],
          ..._buildVisualInsights(),
          if (!_loading) const AppSectionHeader(title: 'Notes'),
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
          if (!_loading) ...[
            const SizedBox(height: AppSpacing.sm),
            const DisclaimerCard(
              text: 'Patterns, not diagnoses. Talk to your care team.',
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildVisualInsights() {
    if (_loading) {
      return const [];
    }

    final today = dayOf(DateTime.now());
    final byDay = moodsByDay(_moods);
    return [
      const AppSectionHeader(
        title: 'Mood calendar',
        subtitle: 'Each day is colored by its average mood. Tap a day.',
      ),
      VitaMindCard(
        child: MoodCalendar(byDay: byDay, today: today),
      ),
      ..._buildMoodTrend(byDay, today),
      ..._buildSymptomTrend(today),
      ..._buildJournalComparison(byDay, today),
    ];
  }

  List<Widget> _buildMoodTrend(Map<DateTime, DayMood> byDay, DateTime today) {
    final days = _trendDays;
    final start = DateTime(today.year, today.month, today.day - (days - 1));
    final current = summarizeMoods(
      byDay,
      start: start,
      endExclusive: DateTime(today.year, today.month, today.day + 1),
    );
    final previous = summarizeMoods(
      byDay,
      start: DateTime(start.year, start.month, start.day - days),
      endExclusive: start,
    );

    var summary = 'No mood check-ins in the last $days days.';
    if (current != null) {
      summary =
          'Average: ${current.band.label} · ${current.checkIns} check-in${current.checkIns == 1 ? '' : 's'} on ${current.days} day${current.days == 1 ? '' : 's'}';
      // Only compare periods with enough days to mean something.
      if (previous != null && current.days >= 3 && previous.days >= 3) {
        final difference = current.average - previous.average;
        summary += difference.abs() < 0.25
            ? ' · about the same as the $days days before'
            : difference > 0
            ? ' · more pleasant than the $days days before'
            : ' · less pleasant than the $days days before';
      }
    }

    return [
      const AppSectionHeader(title: 'Mood trend'),
      VitaMindCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
              ],
              selected: {days},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _trendDays = selection.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(summary, style: AppTextStyles.cardBody(context)),
            const SizedBox(height: AppSpacing.md),
            if (byDay.isEmpty)
              Text(
                'Log a mood from Home to start your chart.',
                style: AppTextStyles.meta(context),
              )
            else
              DailyLineChart(
                values: dailyMoodSeries(byDay, end: today, days: days),
                end: today,
                minY: -2,
                maxY: 2,
                color: AppColors.primary,
                guides: const [
                  ChartGuide(2, '😄'),
                  ChartGuide(0, '😐'),
                  ChartGuide(-2, '😟'),
                ],
                describePoint: (day, value) =>
                    '${formatShortDate(day)}: ${MoodBand.forScore(value).label}',
                semanticSummary:
                    'Mood trend for the last $days days. $summary.',
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSymptomTrend(DateTime today) {
    const days = 30;
    final since = DateTime(today.year, today.month, today.day - (days - 1));
    final names = topSymptoms(_symptoms, since: since);
    if (names.isEmpty) {
      return const [];
    }

    final symptom = names.contains(_selectedSymptom)
        ? _selectedSymptom!
        : names.first;
    final values = dailySymptomSeries(
      _symptoms,
      symptom: symptom,
      end: today,
      days: days,
    );
    final logged = values.whereType<double>().toList();
    final highest = logged.reduce((a, b) => a > b ? a : b).round();
    final summary =
        '$symptom: logged on ${logged.length} of the last $days days · highest $highest/10';

    return [
      const AppSectionHeader(
        title: 'Symptom severity',
        subtitle: 'Highest severity logged each day, last 30 days.',
      ),
      VitaMindCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (names.length > 1) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final name in names)
                    ChoiceChip(
                      label: Text(name),
                      selected: name == symptom,
                      onSelected: (_) =>
                          setState(() => _selectedSymptom = name),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(summary, style: AppTextStyles.cardBody(context)),
            const SizedBox(height: AppSpacing.md),
            DailyLineChart(
              values: values,
              end: today,
              minY: 0,
              maxY: 10,
              color: AppColors.blue,
              guides: const [
                ChartGuide(10, '10'),
                ChartGuide(5, '5'),
                ChartGuide(0, '0'),
              ],
              describePoint: (day, value) =>
                  '${formatShortDate(day)}: $symptom ${value.round()}/10',
              semanticSummary: 'Symptom severity chart. $summary.',
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildJournalComparison(
    Map<DateTime, DayMood> byDay,
    DateTime today,
  ) {
    if (byDay.isEmpty || _journals.isEmpty) {
      return const [];
    }

    final comparison = compareMoodByJournal(
      byDay,
      _journals,
      since: DateTime(today.year, today.month, today.day - 29),
    );

    return [
      const AppSectionHeader(
        title: 'Journaling and mood',
        subtitle: 'Last 30 days',
      ),
      VitaMindCard(
        child: comparison == null
            ? Text(
                'Not enough logs to compare yet. This needs at least 3 days with a journal entry and 3 without, each with a mood check-in.',
                style: AppTextStyles.cardBody(context),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MoodStatTile(
                          title: 'Days you journaled',
                          summary: comparison.journaled,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MoodStatTile(
                          title: 'Other days',
                          summary: comparison.notJournaled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'A pattern, not a cause. Sleep, stress, and many other things affect mood too.',
                    style: AppTextStyles.meta(context),
                  ),
                ],
              ),
      ),
    ];
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
        icon: LucideIcons.pencil,
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
          icon: LucideIcons.activity,
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
          icon: LucideIcons.smile,
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

class _MoodStatTile extends StatelessWidget {
  const _MoodStatTile({required this.title, required this.summary});

  final String title;
  final MoodSummary summary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title: ${summary.band.label}, from ${summary.days} days',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.meta(context)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: moodBandColor(summary.band),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  summary.band.label,
                  style: AppTextStyles.cardTitle(context),
                ),
              ),
            ],
          ),
          Text('${summary.days} days', style: AppTextStyles.meta(context)),
        ],
      ),
    );
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

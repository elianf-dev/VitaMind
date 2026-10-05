import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/insight_math.dart';

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdayShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

Color moodBandColor(MoodBand band) {
  switch (band) {
    case MoodBand.veryUnpleasant:
      return AppColors.moodVeryUnpleasant;
    case MoodBand.unpleasant:
      return AppColors.moodUnpleasant;
    case MoodBand.neutral:
      return AppColors.moodNeutral;
    case MoodBand.pleasant:
      return AppColors.moodPleasant;
    case MoodBand.veryPleasant:
      return AppColors.moodVeryPleasant;
  }
}

/// Day-number ink that stays readable on each band's fill.
Color _inkOn(MoodBand band) {
  return band == MoodBand.veryUnpleasant || band == MoodBand.veryPleasant
      ? Colors.white
      : AppColors.text;
}

/// Month grid where each day is filled by that day's average mood. Tapping a
/// day lists its check-ins; every day also has a screen-reader label, so the
/// color is never the only way to read it.
class MoodCalendar extends StatefulWidget {
  const MoodCalendar({super.key, required this.byDay, required this.today});

  final Map<DateTime, DayMood> byDay;
  final DateTime today;

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  late DateTime _month;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = dayOf(widget.today);
    _month = DateTime(today.year, today.month);
    if (widget.byDay.containsKey(today)) {
      _selectedDay = today;
    }
  }

  DateTime get _currentMonth {
    final today = dayOf(widget.today);
    return DateTime(today.year, today.month);
  }

  DateTime get _earliestMonth {
    if (widget.byDay.isEmpty) {
      return _currentMonth;
    }
    final first = widget.byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(first.year, first.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = null;
    });
  }

  String _dayLabel(DateTime day) {
    final weekday = _weekdayShort[day.weekday - 1];
    return '$weekday, ${_monthNames[day.month - 1]} ${day.day}';
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = _month.isAfter(_earliestMonth);
    final canGoForward = _month.isBefore(_currentMonth);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month).weekday - 1;
    final today = dayOf(widget.today);
    final loggedDays = widget.byDay.keys
        .where((day) => day.year == _month.year && day.month == _month.month)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: canGoBack ? () => _shiftMonth(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle(context),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: canGoForward ? () => _shiftMonth(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final name in _weekdayShort)
                Expanded(
                  child: Text(
                    name.substring(0, 1),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.meta(context),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var date = 1; date <= daysInMonth; date++)
              _buildDayCell(
                context,
                DateTime(_month.year, _month.month, date),
                today,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          loggedDays == 0
              ? 'No mood check-ins this month.'
              : 'Mood logged on $loggedDays day${loggedDays == 1 ? '' : 's'} this month.',
          style: AppTextStyles.meta(context),
        ),
        const SizedBox(height: AppSpacing.md),
        const _MoodLegend(),
        if (_selectedDay != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SelectedDayDetails(
            label: _dayLabel(_selectedDay!),
            dayMood: widget.byDay[_selectedDay!],
          ),
        ],
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, DateTime today) {
    final dayMood = widget.byDay[day];
    final isFuture = day.isAfter(today);
    final isToday = day == today;
    final isSelected = day == _selectedDay;
    final band = dayMood?.band;

    final description = dayMood == null
        ? (isFuture ? 'upcoming' : 'no check-in')
        : '${band!.label}: ${dayMood.entries.map((entry) => entry.label).join(', ')}';

    return Semantics(
      button: !isFuture,
      selected: isSelected,
      label: '${_dayLabel(day)}${isToday ? ', today' : ''}, $description',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isFuture ? null : () => setState(() => _selectedDay = day),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: band == null ? null : moodBandColor(band),
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: isSelected
                ? Border.all(color: AppColors.text, width: 2)
                : isToday
                ? Border.all(color: AppColors.primary, width: 2)
                : band == null && !isFuture
                ? Border.all(color: AppColors.mutedIcon.withValues(alpha: 0.5))
                : null,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: band == null
                  ? (isFuture ? AppColors.disabled : AppColors.mutedText)
                  : _inkOn(band),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodLegend extends StatelessWidget {
  const _MoodLegend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget swatch, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swatch,
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.meta(context)),
        ],
      );
    }

    Widget filled(Color color) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Semantics(
      container: true,
      label: 'Legend',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          for (final band in MoodBand.values.reversed)
            item(filled(moodBandColor(band)), band.label),
          item(
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.mutedIcon.withValues(alpha: 0.5),
                ),
              ),
            ),
            'No check-in',
          ),
        ],
      ),
    );
  }
}

/// Lists a tapped day's check-ins. Notes stay in the Mood tab so a chart
/// never puts private text on screen.
class _SelectedDayDetails extends StatelessWidget {
  const _SelectedDayDetails({required this.label, required this.dayMood});

  final String label;
  final DayMood? dayMood;

  @override
  Widget build(BuildContext context) {
    final mood = dayMood;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.recessedSurface,
          borderRadius: BorderRadius.circular(AppSpacing.tileRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mood == null
                  ? '$label · No check-in'
                  : '$label · ${mood.band.label}',
              style: AppTextStyles.cardTitle(context),
            ),
            if (mood != null)
              for (final entry in mood.entries)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${TimeOfDay.fromDateTime(entry.createdAt.toLocal()).format(context)}  ${entry.emoji} ${entry.label}',
                    style: AppTextStyles.cardBody(context),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

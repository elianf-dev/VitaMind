import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

const List<String> _monthShort = [
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

String formatShortDate(DateTime day) =>
    '${_monthShort[day.month - 1]} ${day.day}';

class ChartGuide {
  const ChartGuide(this.value, this.label);

  final double value;
  final String label;
}

/// One series of daily values (oldest first, ending on [end]). Missing days
/// break the line instead of being interpolated. Tap or drag to read a day.
class DailyLineChart extends StatefulWidget {
  const DailyLineChart({
    super.key,
    required this.values,
    required this.end,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.guides,
    required this.describePoint,
    required this.semanticSummary,
    this.height = 150,
  });

  final List<double?> values;
  final DateTime end;
  final double minY;
  final double maxY;
  final Color color;
  final List<ChartGuide> guides;
  final String Function(DateTime day, double value) describePoint;

  /// Read by screen readers in place of the drawing.
  final String semanticSummary;
  final double height;

  @override
  State<DailyLineChart> createState() => _DailyLineChartState();
}

class _DailyLineChartState extends State<DailyLineChart> {
  static const double _baseLeftInset = 32;
  static const double _rightInset = 8;

  int? _selected;
  bool _focused = false;

  @override
  void didUpdateWidget(DailyLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare contents: the parent rebuilds the list on every setState, and
    // an unrelated change (like a symptom chip) shouldn't clear the reading.
    if (!listEquals(oldWidget.values, widget.values)) {
      _selected = null;
    }
  }

  /// Moves the selection to the previous (-1) or next (1) day that has a
  /// value. With nothing selected, starts from the most recent day.
  void _step(int direction) {
    final index = _neighbor(direction);
    if (index != null) {
      setState(() => _selected = index);
    }
  }

  int? _neighbor(int direction) {
    final values = widget.values;
    var index = _selected ?? (direction < 0 ? values.length : -1);
    do {
      index += direction;
    } while (index >= 0 && index < values.length && values[index] == null);
    return index >= 0 && index < values.length ? index : null;
  }

  String _describe(int index) =>
      widget.describePoint(_dayAt(index), widget.values[index]!);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _step(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  DateTime _dayAt(int index) {
    final count = widget.values.length;
    return DateTime(
      widget.end.year,
      widget.end.month,
      widget.end.day - (count - 1 - index),
    );
  }

  void _selectAt(double dx, double width, double leftInset) {
    final count = widget.values.length;
    if (count == 0) {
      return;
    }
    final plotWidth = width - leftInset - _rightInset;
    final fraction = ((dx - leftInset) / plotWidth).clamp(0.0, 1.0);
    final target = count == 1 ? 0 : (fraction * (count - 1)).round();

    int? nearest;
    for (var offset = 0; offset < count && nearest == null; offset++) {
      for (final candidate in [target - offset, target + offset]) {
        if (candidate >= 0 &&
            candidate < count &&
            widget.values[candidate] != null) {
          nearest = candidate;
          break;
        }
      }
    }
    if (nearest != _selected) {
      setState(() => _selected = nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final readout = selected == null
        ? 'Tap the chart to see a day.'
        : _describe(selected);
    final next = _neighbor(1);
    final previous = _neighbor(-1);

    // Guide labels are painted, so apply the reader's text size and bold
    // text setting by hand, and widen the label column to fit.
    final textScaler = MediaQuery.textScalerOf(context);
    final leftInset = textScaler
        .scale(_baseLeftInset)
        .clamp(_baseLeftInset, _baseLeftInset * 2.25);
    var guideStyle =
        AppTextStyles.meta(context) ?? const TextStyle(fontSize: 11);
    if (MediaQuery.boldTextOf(context)) {
      guideStyle = guideStyle.copyWith(fontWeight: FontWeight.bold);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(readout, style: AppTextStyles.meta(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Screen readers adjust the chart (swipe up or down on Android) to
        // step through days; keyboards use the arrow keys.
        Semantics(
          container: true,
          label: widget.semanticSummary,
          value: selected == null ? null : readout,
          // Flutter requires the neighboring readings alongside a value.
          increasedValue: selected == null || next == null
              ? null
              : _describe(next),
          decreasedValue: selected == null || previous == null
              ? null
              : _describe(previous),
          hint: 'Adjust to move between days',
          onIncrease: next == null ? null : () => _step(1),
          onDecrease: previous == null ? null : () => _step(-1),
          child: ExcludeSemantics(
            child: Focus(
              onKeyEvent: _onKey,
              onFocusChange: (focused) => setState(() => _focused = focused),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  border: Border.all(
                    color: _focused ? AppColors.focusRing : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: SizedBox(
                  height: widget.height,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _selectAt(
                          details.localPosition.dx,
                          width,
                          leftInset,
                        ),
                        onHorizontalDragUpdate: (details) => _selectAt(
                          details.localPosition.dx,
                          width,
                          leftInset,
                        ),
                        child: CustomPaint(
                          size: Size(width, widget.height),
                          painter: _DailyLinePainter(
                            values: widget.values,
                            minY: widget.minY,
                            maxY: widget.maxY,
                            color: widget.color,
                            guides: widget.guides,
                            selected: selected,
                            leftInset: leftInset,
                            rightInset: _rightInset,
                            guideStyle: guideStyle,
                            textScaler: textScaler,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.only(left: leftInset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatShortDate(_dayAt(0)),
                  style: AppTextStyles.meta(context),
                ),
                Text('Today', style: AppTextStyles.meta(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyLinePainter extends CustomPainter {
  _DailyLinePainter({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.guides,
    required this.selected,
    required this.leftInset,
    required this.rightInset,
    required this.guideStyle,
    required this.textScaler,
  });

  static const double _verticalInset = 10;
  // Matches the card surface so overlapping marks stay separated.
  static const Color _surfaceRing = Color(0xFFF1F6F4);

  final List<double?> values;
  final double minY;
  final double maxY;
  final Color color;
  final List<ChartGuide> guides;
  final int? selected;
  final double leftInset;
  final double rightInset;
  final TextStyle guideStyle;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final count = values.length;
    final plotWidth = size.width - leftInset - rightInset;
    final plotHeight = size.height - _verticalInset * 2;

    double xFor(int index) =>
        leftInset +
        (count <= 1 ? plotWidth / 2 : plotWidth * index / (count - 1));
    double yFor(double value) =>
        _verticalInset +
        (1 - (value - minY) / (maxY - minY)).clamp(0.0, 1.0) * plotHeight;

    final guidePaint = Paint()
      ..color = AppColors.mutedIcon.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (final guide in guides) {
      final y = yFor(guide.value);
      canvas.drawLine(
        Offset(leftInset, y),
        Offset(size.width - rightInset, y),
        guidePaint,
      );
      final label = TextPainter(
        text: TextSpan(text: guide.label, style: guideStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: leftInset - 4);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path? run;
    for (var i = 0; i < count; i++) {
      final value = values[i];
      if (value == null) {
        if (run != null) {
          canvas.drawPath(run, linePaint);
          run = null;
        }
        continue;
      }
      final point = Offset(xFor(i), yFor(value));
      if (run == null) {
        run = Path()..moveTo(point.dx, point.dy);
      } else {
        run.lineTo(point.dx, point.dy);
      }
    }
    if (run != null) {
      canvas.drawPath(run, linePaint);
    }

    // Dots on every point for short ranges; on long ranges only where a
    // point has no neighbors (otherwise it would be invisible).
    final showAllDots = count <= 14;
    final dotPaint = Paint()..color = color;
    final ringPaint = Paint()..color = _surfaceRing;
    for (var i = 0; i < count; i++) {
      final value = values[i];
      if (value == null || i == selected) {
        continue;
      }
      final isolated =
          (i == 0 || values[i - 1] == null) &&
          (i == count - 1 || values[i + 1] == null);
      if (!showAllDots && !isolated) {
        continue;
      }
      final point = Offset(xFor(i), yFor(value));
      canvas.drawCircle(point, 6, ringPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }

    final selectedIndex = selected;
    if (selectedIndex != null && values[selectedIndex] != null) {
      final x = xFor(selectedIndex);
      final crosshair = Paint()
        ..color = AppColors.text.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, _verticalInset / 2),
        Offset(x, size.height - _verticalInset / 2),
        crosshair,
      );
      final point = Offset(x, yFor(values[selectedIndex]!));
      canvas.drawCircle(point, 8, ringPaint);
      canvas.drawCircle(point, 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DailyLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selected != selected ||
        oldDelegate.color != color ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.leftInset != leftInset ||
        oldDelegate.guideStyle != guideStyle ||
        oldDelegate.textScaler != textScaler;
  }
}

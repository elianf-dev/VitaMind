import 'package:flutter/material.dart';

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
  static const double _leftInset = 32;
  static const double _rightInset = 8;

  int? _selected;

  @override
  void didUpdateWidget(DailyLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _selected = null;
    }
  }

  DateTime _dayAt(int index) {
    final count = widget.values.length;
    return DateTime(
      widget.end.year,
      widget.end.month,
      widget.end.day - (count - 1 - index),
    );
  }

  void _selectAt(double dx, double width) {
    final count = widget.values.length;
    if (count == 0) {
      return;
    }
    final plotWidth = width - _leftInset - _rightInset;
    final fraction = ((dx - _leftInset) / plotWidth).clamp(0.0, 1.0);
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
        : widget.describePoint(_dayAt(selected), widget.values[selected]!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(readout, style: AppTextStyles.meta(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: widget.semanticSummary,
          child: ExcludeSemantics(
            child: SizedBox(
              height: widget.height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) =>
                        _selectAt(details.localPosition.dx, width),
                    onHorizontalDragUpdate: (details) =>
                        _selectAt(details.localPosition.dx, width),
                    child: CustomPaint(
                      size: Size(width, widget.height),
                      painter: _DailyLinePainter(
                        values: widget.values,
                        minY: widget.minY,
                        maxY: widget.maxY,
                        color: widget.color,
                        guides: widget.guides,
                        selected: selected,
                        leftInset: _leftInset,
                        rightInset: _rightInset,
                        guideStyle:
                            AppTextStyles.meta(context) ??
                            const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(left: _leftInset),
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
        oldDelegate.maxY != maxY;
  }
}

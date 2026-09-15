import 'package:flutter/material.dart';

/// A front + back body diagram that highlights the muscles worked by an
/// exercise. Muscle names match the free-exercise-db vocabulary
/// (e.g. `chest`, `lats`, `quadriceps`).
class MuscleMap extends StatelessWidget {
  const MuscleMap({
    super.key,
    required this.primary,
    this.secondary = const {},
    this.height = 240,
  });

  final Set<String> primary;
  final Set<String> secondary;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.tertiary;
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _MuscleMapPainter(
              primary: primary,
              secondary: secondary,
              base: theme.colorScheme.surfaceContainerHighest,
              outline: theme.colorScheme.outlineVariant,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor.withValues(alpha: 0.55),
              labelColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            _LegendDot(color: primaryColor, label: 'Primary'),
            if (secondary.isNotEmpty)
              _LegendDot(
                  color: secondaryColor.withValues(alpha: 0.7),
                  label: 'Secondary'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MuscleMapPainter extends CustomPainter {
  _MuscleMapPainter({
    required this.primary,
    required this.secondary,
    required this.base,
    required this.outline,
    required this.primaryColor,
    required this.secondaryColor,
    required this.labelColor,
  });

  final Set<String> primary;
  final Set<String> secondary;
  final Color base;
  final Color outline;
  final Color primaryColor;
  final Color secondaryColor;
  final Color labelColor;

  static const double _lw = 100; // local figure width
  static const double _lh = 220; // local figure height

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 18.0;
    final halfW = (size.width - gap) / 2;
    final s = (halfW / _lw).clamp(0.0, size.height / _lh);
    final oy = (size.height - _lh * s) / 2;
    final frontOx = (halfW - _lw * s) / 2;
    final backOx = halfW + gap + (halfW - _lw * s) / 2;

    _drawFigure(canvas, frontOx, oy, s, back: false);
    _drawFigure(canvas, backOx, oy, s, back: true);

    _label(canvas, 'FRONT', frontOx + _lw * s / 2, oy + _lh * s + 2);
    _label(canvas, 'BACK', backOx + _lw * s / 2, oy + _lh * s + 2);
  }

  void _drawFigure(Canvas canvas, double ox, double oy, double s,
      {required bool back}) {
    Rect t(double l, double top, double r, double b) =>
        Rect.fromLTRB(ox + l * s, oy + top * s, ox + r * s, oy + b * s);

    final basePaint = Paint()..color = base;
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    void part(Rect r, [double radius = 5]) {
      final rr = RRect.fromRectAndRadius(r, Radius.circular(radius * s));
      canvas.drawRRect(rr, basePaint);
      canvas.drawRRect(rr, outlinePaint);
    }

    // Base silhouette (shared by both views).
    canvas.drawCircle(
        Offset(ox + 50 * s, oy + 16 * s), 12 * s, basePaint);
    canvas.drawCircle(
        Offset(ox + 50 * s, oy + 16 * s), 12 * s, outlinePaint);
    part(t(45, 26, 55, 34));
    part(t(32, 38, 68, 96), 10); // torso
    part(t(20, 44, 31, 84)); // left upper arm
    part(t(69, 44, 80, 84)); // right upper arm
    part(t(18, 86, 28, 120)); // left forearm
    part(t(72, 86, 82, 120)); // right forearm
    part(t(36, 96, 64, 116), 8); // pelvis
    part(t(37, 116, 48, 166)); // left thigh
    part(t(52, 116, 63, 166)); // right thigh
    part(t(38, 168, 47, 210)); // left shin
    part(t(53, 168, 62, 210)); // right shin

    // Highlights: secondary first, then primary on top.
    void highlight(Set<String> muscles, Color color) {
      final paint = Paint()..color = color;
      for (final m in muscles) {
        for (final r in _regions(m, back)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(t(r.left, r.top, r.right, r.bottom),
                Radius.circular(5 * s)),
            paint,
          );
        }
      }
    }

    highlight(secondary.difference(primary), secondaryColor);
    highlight(primary, primaryColor);
  }

  /// Local-space rectangles for a muscle, for the given view.
  List<Rect> _regions(String muscle, bool back) {
    Rect r(double l, double t, double rt, double b) => Rect.fromLTRB(l, t, rt, b);
    if (!back) {
      switch (muscle) {
        case 'shoulders':
          return [r(24, 40, 36, 52), r(64, 40, 76, 52)];
        case 'chest':
          return [r(34, 44, 49, 64), r(51, 44, 66, 64)];
        case 'abdominals':
          return [r(42, 65, 58, 94)];
        case 'traps':
          return [r(40, 36, 48, 44), r(52, 36, 60, 44)];
        case 'neck':
          return [r(45, 27, 55, 35)];
        case 'biceps':
          return [r(20, 50, 31, 80), r(69, 50, 80, 80)];
        case 'forearms':
          return [r(18, 88, 28, 118), r(72, 88, 82, 118)];
        case 'quadriceps':
          return [r(37, 118, 48, 164), r(52, 118, 63, 164)];
        case 'adductors':
          return [r(46, 120, 54, 160)];
        case 'abductors':
          return [r(34, 118, 39, 150), r(61, 118, 66, 150)];
        case 'calves':
          return [r(38, 170, 47, 208), r(53, 170, 62, 208)];
      }
    } else {
      switch (muscle) {
        case 'traps':
          return [r(38, 38, 62, 58)];
        case 'lats':
          return [r(33, 58, 46, 84), r(54, 58, 67, 84)];
        case 'middle back':
          return [r(44, 56, 56, 82)];
        case 'lower back':
          return [r(42, 84, 58, 98)];
        case 'shoulders':
          return [r(24, 40, 36, 52), r(64, 40, 76, 52)];
        case 'triceps':
          return [r(20, 50, 31, 80), r(69, 50, 80, 80)];
        case 'forearms':
          return [r(18, 88, 28, 118), r(72, 88, 82, 118)];
        case 'glutes':
          return [r(37, 98, 63, 116)];
        case 'hamstrings':
          return [r(37, 118, 48, 164), r(52, 118, 63, 164)];
        case 'calves':
          return [r(38, 170, 47, 208), r(53, 170, 62, 208)];
      }
    }
    return const [];
  }

  void _label(Canvas canvas, String text, double cx, double top) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: labelColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, top));
  }

  @override
  bool shouldRepaint(_MuscleMapPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.primaryColor != primaryColor;
}

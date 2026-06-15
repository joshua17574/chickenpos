import 'package:flutter/material.dart';
import '../theme.dart';

class CutPattern extends StatelessWidget {
  final Color color;
  const CutPattern({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _CutPatternPainter(color.withValues(alpha: 0.09)),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BrandMarkPainter()),
    );
  }
}

class ProductVisual extends StatelessWidget {
  final String name;
  final String category;
  final double height;
  const ProductVisual({
    super.key,
    required this.name,
    required this.category,
    this.height = 76,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ProductVisualPainter(
          name: name,
          color: _visualColor(name, category),
        ),
      ),
    );
  }

  static Color _visualColor(String name, String category) {
    final normalized = name.trim().toUpperCase();
    if (normalized == 'PEPSI') return AppColors.pepsi;
    if (normalized == 'C59') return AppColors.teal;
    if (normalized == 'C99') return AppColors.indigo;
    return AppColors.category(category);
  }
}

class EmptyStateArt extends StatelessWidget {
  final double size;
  const EmptyStateArt({super.key, this.size = 112});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _EmptyStatePainter()),
    );
  }
}

/// Full-width gradient pill button.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular initials avatar tinted by category.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final String category;
  final double size;
  const InitialsAvatar({
    super.key,
    required this.name,
    required this.category,
    this.size = 40,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final take = parts.first.length < 2 ? parts.first.length : 2;
      return parts.first.substring(0, take).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.category(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.withValues(alpha: 0.2),
            c.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// Small rounded status pill.
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const StatusPill({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded qty stepper used in the cart.
class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onMinus),
          SizedBox(
            width: 26,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _btn(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _btn(IconData i, VoidCallback f) => InkWell(
        onTap: f,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(i, size: 18, color: AppColors.primary),
        ),
      );
}

class _CutPatternPainter extends CustomPainter {
  final Color color;
  const _CutPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var y = 12.0; y < size.height + 24; y += 24) {
      for (var x = -20.0; x < size.width + 30; x += 54) {
        canvas.drawLine(Offset(x, y), Offset(x + 18, y - 9), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CutPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final bg = Paint()..color = AppColors.primary;
    final deep = Paint()..color = AppColors.header;
    final cream = Paint()..color = const Color(0xFFFFF3D7);
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(s * 0.26),
      ),
      bg,
    );
    canvas.drawCircle(Offset(s * 0.72, s * 0.24), s * 0.18, deep);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.48, s * 0.58),
        width: s * 0.62,
        height: s * 0.42,
      ),
      cream,
    );
    canvas.drawLine(
        Offset(s * 0.25, s * 0.48), Offset(s * 0.7, s * 0.68), line);
    canvas.drawLine(
        Offset(s * 0.68, s * 0.47), Offset(s * 0.28, s * 0.69), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProductVisualPainter extends CustomPainter {
  final String name;
  final Color color;
  const _ProductVisualPainter({required this.name, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = name.trim().toUpperCase();
    final plate = Paint()..color = Colors.white.withValues(alpha: 0.78);
    final shadow = Paint()..color = color.withValues(alpha: 0.1);
    final accent = Paint()..color = color;
    final light = Paint()..color = color.withValues(alpha: 0.16);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            4, size.height * 0.15, size.width - 8, size.height * 0.78),
        const Radius.circular(20),
      ),
      shadow,
    );

    if (normalized == 'PEPSI') {
      _drawCan(canvas, size, accent, light);
      return;
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.58),
        width: size.width * 0.74,
        height: size.height * 0.46,
      ),
      plate,
    );
    _drawCut(canvas, size, accent, light);
    _drawLabel(canvas, size, normalized);
  }

  void _drawCan(Canvas canvas, Size size, Paint accent, Paint light) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.52),
        width: size.width * 0.32,
        height: size.height * 0.72,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(body, accent);
    canvas.drawRRect(
      body.deflate(7),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.52),
        width: size.width * 0.24,
        height: size.height * 0.24,
      ),
      -0.7,
      3.5,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.16),
        width: size.width * 0.26,
        height: size.height * 0.1,
      ),
      light,
    );
  }

  void _drawCut(Canvas canvas, Size size, Paint accent, Paint light) {
    final accentColor = accent.color;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.22,
        size.width * 0.72,
        size.height * 0.28,
        size.width * 0.72,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.78,
        size.width * 0.42,
        size.height * 0.78,
        size.width * 0.28,
        size.height * 0.52,
      )
      ..close();
    canvas.drawPath(path, light);
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(size.width * 0.36, size.height * 0.48), 5,
        Paint()..color = accentColor);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.56), 4,
        Paint()..color = accentColor);
  }

  void _drawLabel(Canvas canvas, Size size, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.header,
          fontSize: size.height * 0.16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    painter.paint(
      canvas,
      Offset((size.width - painter.width) / 2, size.height * 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _ProductVisualPainter oldDelegate) =>
      oldDelegate.name != name || oldDelegate.color != color;
}

class _EmptyStatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final plate = Paint()..color = AppColors.primary.withValues(alpha: 0.1);
    final stroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final teal = Paint()..color = AppColors.teal.withValues(alpha: 0.18);

    canvas.drawCircle(size.center(Offset.zero), size.width * 0.46, teal);
    canvas.drawOval(
      Rect.fromCenter(
        center: size.center(const Offset(0, 10)),
        width: size.width * 0.68,
        height: size.height * 0.38,
      ),
      plate,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * 0.42,
        height: size.height * 0.34,
      ),
      0.6,
      3.9,
      false,
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.7),
      Offset(size.width * 0.72, size.height * 0.7),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

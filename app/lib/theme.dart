import 'package:flutter/material.dart';

/// PeriBuds design tokens — locked by Vijay, 18 Nov 2026.
/// Outfit ONLY, no serif anywhere. Rose #C24E64 primary.
class PB {
  static const rose = Color(0xFFC24E64);
  static const roseDark = Color(0xFF8F2F3D);
  static const roseDeep = Color(0xFFA63D4E);
  static const roseLight = Color(0xFFFBD9D6);
  static const roseSoft = Color(0xFFFFF0EE);
  static const rosePale = Color(0xFFFFF7F3);
  static const bg = Color(0xFFFFFAF7);
  static const ink = Color(0xFF3D2C33);
  // Near-black warm brown — used ONLY for the "Log period" button and
  // for TODAY on the Home mini-calendar (approved screenshots, 18 Nov).
  // NEVER for a selected day on the Calendar screen (that stays rose).
  static const dark = Color(0xFF2B2320);
  // #9A828B is the reference grey-pink — eyebrows and tiny labels ONLY.
  static const muted = Color(0xFF9A828B);
  static const muted2 = Color(0xFF9A828B);
  // Body copy: darker warm grey from the reference files. Never use
  // muted/muted2 for body text — that is what made v1.0.0 look washed out.
  static const softText = Color(0xFF7A5A63);
  static const bodyText = Color(0xFF6E5560);
  static const line = Color(0xFFF8ECE9);
  static const lavender = Color(0xFFEDE7FA);
  static const mint = Color(0xFFDCEFE7);
  static const green = Color(0xFF2F6B4F);
  static const greenBg = Color(0xFFEAF4ED);
  static const amberBg = Color(0xFFFFF7E8);
  static const amberText = Color(0xFF8A6A2A);

  static ThemeData theme() {
    const outfit = 'Outfit';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      fontFamily: outfit,
      colorScheme: const ColorScheme.light(
        primary: rose,
        onPrimary: Colors.white,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: outfit, color: ink),
        displayMedium: TextStyle(fontFamily: outfit, color: ink),
        displaySmall: TextStyle(fontFamily: outfit, color: ink),
        headlineLarge: TextStyle(fontFamily: outfit, color: ink),
        headlineMedium: TextStyle(fontFamily: outfit, color: ink),
        headlineSmall: TextStyle(fontFamily: outfit, color: ink),
        titleLarge: TextStyle(fontFamily: outfit, color: ink),
        titleMedium: TextStyle(fontFamily: outfit, color: ink),
        titleSmall: TextStyle(fontFamily: outfit, color: ink),
        bodyLarge: TextStyle(fontFamily: outfit, color: ink),
        bodyMedium: TextStyle(fontFamily: outfit, color: ink),
        bodySmall: TextStyle(fontFamily: outfit, color: ink),
        labelLarge: TextStyle(fontFamily: outfit, color: ink),
        labelMedium: TextStyle(fontFamily: outfit, color: ink),
        labelSmall: TextStyle(fontFamily: outfit, color: ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: outfit,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: rose,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: outfit,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Short rose pill button — one line, never wraps (design rule, 18 Nov).
class RosePillButton extends StatelessWidget {
  const RosePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  // The Calendar "Mark … as period" CTA is a SHORT centred pill
  // (approved design); the Reports PDF button stays full-width.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: PB.rose,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PB.rose.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shadowColor: PB.rose.withValues(alpha: 0.35),
          elevation: 4,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}

/// Ghost / secondary pill button — one line, never wraps.
class GhostPillButton extends StatelessWidget {
  const GhostPillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE8C9C4)),
          backgroundColor: Colors.white,
          foregroundColor: PB.ink,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}

/// Full-width button with a 2px DASHED rounded border (the "+ Add meal"
/// button in the reference). Flutter's BorderStyle has no dashed style,
/// so the dashes are painted with a CustomPainter.
class DashedButton extends StatelessWidget {
  const DashedButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CustomPaint(
        painter: _DashedRoundedRectPainter(color: const Color(0xFFE8C9C4)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: PB.rose,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rect border painter (public — the calendar's predicted
/// days use it too; Flutter's BorderStyle has no dashed style).
/// Approved design: predicted period days are a DASHED rose outline,
/// white fill, rose text (screenshots, 18 Nov 2026).
class DashedRectPainter extends CustomPainter {
  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 12,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    const dash = 5.0;
    const gap = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A box with a dashed rose border (predicted days, legend icon).
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.radius = 12,
    this.color = PB.rose,
    this.background,
  });

  final Widget child;
  final double radius;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedRectPainter(color: color, radius: radius),
      child: Container(
        decoration: BoxDecoration(
          color: background ?? Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Marked-period status row (design rule, 18 Nov):
/// green check circle + left-aligned "Period marked" / dates + small Remove.
/// NEVER a long green pill with wrapping text.
class MarkedStatusRow extends StatelessWidget {
  const MarkedStatusRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRemove,
    this.removeLabel = 'Remove',
  });

  final String title;
  final String subtitle;
  final VoidCallback onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PB.greenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: PB.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF234D38),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A7A68),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              removeLabel,
              style: const TextStyle(
                color: PB.rose,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White card with soft shadow, as used across all four screens.
class PBCard extends StatelessWidget {
  const PBCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE2E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF502332).withValues(alpha: 0.075),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    );
  }
}

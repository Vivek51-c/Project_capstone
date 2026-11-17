import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// A simple, original geometric mark: an "O" ring with an upward arrow
/// breaking through the top-right — opportunity + upward career growth.
///
/// This is a placeholder brand identity built entirely in code (no SVG/PNG
/// asset pipeline), not final design art — swap for real brand assets when
/// you have them. Kept as one widget so that swap only happens in one place.
class AppLogoMark extends StatelessWidget {
  final double size;

  const AppLogoMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Base ring, gradient-filled.
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryLight, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.19
      ..strokeCap = StrokeCap.round;

    // Leave a gap at top-right for the arrow to "break through".
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - ringPaint.strokeWidth / 2),
      0.55, // start angle (radians)
      5.3, // sweep, leaving ~1 rad gap near top-right
      false,
      ringPaint,
    );

    // Upward arrow breaking through the gap.
    final arrowPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowStart = Offset(size.width * 0.40, size.height * 0.62);
    final arrowTip = Offset(size.width * 0.82, size.height * 0.20);

    final path = Path()
      ..moveTo(arrowStart.dx, arrowStart.dy)
      ..lineTo(arrowTip.dx, arrowTip.dy);
    canvas.drawPath(path, arrowPaint);

    // Arrowhead.
    final headPaint = Paint()..color = AppColors.success;
    final headPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowTip.dx - size.width * 0.17, arrowTip.dy)
      ..lineTo(arrowTip.dx, arrowTip.dy + size.height * 0.17)
      ..close();
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo + wordmark, for the AppBar / any header context.
class AppWordmark extends StatelessWidget {
  final double logoSize;
  final bool showTagline;

  const AppWordmark({super.key, this.logoSize = 30, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: logoSize),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Opportune JobMate',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              if (showTagline)
                Text(
                  'AI-Powered Career Assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 0.1),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

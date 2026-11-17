import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_typography.dart';

/// Large circular score ring that counts up from 0 on first display
/// (brief §23/§28 — animated score).
class AnimatedScoreGauge extends StatelessWidget {
  final int score;
  final String label;
  final String? caption;
  final double size;
  final Color? color;

  const AnimatedScoreGauge({
    super.key,
    required this.score,
    required this.label,
    this.caption,
    this.size = 168,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? AppColors.forScore(score);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble().clamp(0, 100)),
      duration: AppDuration.score,
      curve: AppDuration.curve,
      builder: (context, value, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: _RingPainter(
                      progress: value / 100,
                      color: ringColor,
                      trackColor: AppColors.surfaceAlt,
                      strokeWidth: size * 0.075,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.round().toString(),
                        style: context.text.displaySmall?.copyWith(
                          color: ringColor,
                          fontSize: size * 0.26,
                          height: 1.05,
                        ),
                      ),
                      Text(
                        'out of 100',
                        style: context.text.labelSmall?.copyWith(letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            Text(label, style: context.text.titleMedium),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(
                caption!,
                style: context.text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [color.withValues(alpha: 0.65), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.strokeWidth != strokeWidth;
}

/// Compact ring for inline/secondary use (e.g. SkillBridge coverage).
class MiniScoreRing extends StatelessWidget {
  final double progress; // 0..1
  final String centerLabel;
  final Color color;
  final double size;

  const MiniScoreRing({
    super.key,
    required this.progress,
    required this.centerLabel,
    required this.color,
    this.size = 76,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: AppDuration.score,
      curve: AppDuration.curve,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: value,
                color: color,
                trackColor: AppColors.surfaceAlt,
                strokeWidth: size * 0.11,
              ),
            ),
            Text(
              centerLabel,
              style: context.text.titleSmall?.copyWith(color: color, fontSize: size * 0.21),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled animated progress bar — the workhorse for every "X of Y" or
/// percentage breakdown in the app.
class MetricBar extends StatelessWidget {
  final String label;
  final double progress; // 0..1
  final String valueLabel;
  final Color? color;
  final String? helper;

  const MetricBar({
    super.key,
    required this.label,
    required this.progress,
    required this.valueLabel,
    this.color,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final barColor = color ?? AppColors.forScore(p * 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.text.titleSmall?.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.wGapXs,
              Text(valueLabel, style: context.text.labelMedium?.copyWith(color: barColor)),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p),
            duration: AppDuration.slow,
            curve: AppDuration.curve,
            builder: (context, value, _) => ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Horizontal step progress used by the ResumeBuilder wizard.
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 0-based
  final int totalSteps;
  final String stepLabel;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps == 0 ? 0.0 : (currentStep + 1) / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(stepLabel, style: context.text.titleMedium)),
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: context.text.labelMedium,
            ),
          ],
        ),
        AppSpacing.gapXs,
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: AppDuration.normal,
          curve: AppDuration.curve,
          builder: (context, value, _) => ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

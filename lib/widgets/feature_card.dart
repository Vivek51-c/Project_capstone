import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_typography.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Tool card used in the Home "Career tools" section. Each feature carries
/// its own accent + icon (brief §10 — the six features should not look like
/// six identical cards), while sharing one layout so the product stays
/// coherent.
class FeatureCard extends StatelessWidget {
  final AppFeature feature;
  final VoidCallback onTap;

  /// Optional real, locally-cached metric (e.g. "Last score 82"). Never a
  /// placeholder — omitted entirely when the user hasn't run the tool.
  final String? metricLabel;

  const FeatureCard({
    super.key,
    required this.feature,
    required this.onTap,
    this.metricLabel,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconWell(
              icon: feature.icon,
              color: feature.accent,
              background: feature.accentSurface,
            ),
            AppSpacing.wGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          feature.label,
                          style: context.text.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (metricLabel != null) ...[
                        AppSpacing.wGapXs,
                        StatusBadge(
                          label: metricLabel!,
                          color: feature.accent,
                          background: feature.accentSurface,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    feature.tagline,
                    style: context.text.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.wGapXs,
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides its child up on first build. Used to give screens and
/// result sections a gentle entrance (brief §23).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 0.06,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      // Still defer by a frame so the animation actually runs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _shown = true);
      });
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: AppDuration.normal,
      curve: AppDuration.curve,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : Offset(0, widget.offsetY),
        duration: AppDuration.normal,
        curve: AppDuration.curve,
        child: widget.child,
      ),
    );
  }
}

/// Applies a staggered entrance to a column of children.
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final int staggerMs;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.staggerMs = 55,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: (i * staggerMs).clamp(0, 500)),
            child: children[i],
          ),
      ],
    );
  }
}

/// Constrains page content to a readable width on tablets/large screens
/// (brief §24) while staying edge-to-edge on phones.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = AppBreakpoints.contentMaxWidth(constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}

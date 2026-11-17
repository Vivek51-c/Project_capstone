import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_typography.dart';

/// Base surface for everything in the app. Soft shadow + hairline border +
/// optional press feedback. Prefer this over raw `Card`.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final double radius;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.background,
    this.borderColor,
    this.shadow,
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: background ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: shadow ?? AppShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
    return content;
  }
}

/// Rounded square icon "well" — the recurring visual motif for features.
class IconWell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const IconWell({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Gradient hero header used at the top of Home. Deliberately compact so it
/// still works on small phones (brief §9).
class GradientHeader extends StatelessWidget {
  final String greeting;
  final String headline;
  final String? subline;
  final Widget? trailing;
  final Widget? footer;
  /// When true, all four corners are rounded (for use as a padded card
  /// inside a scroll body). Default false keeps the original edge-to-edge
  /// banner look (bottom corners only).
  final bool fullRadius;

  const GradientHeader({
    super.key,
    required this.greeting,
    required this.headline,
    this.subline,
    this.trailing,
    this.footer,
    this.fullRadius = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < AppBreakpoints.compact;
        // Reduce padding and headline size on very small screens to prevent overflow.
        final hPad = isCompact ? AppSpacing.md : AppSpacing.lg;
        final headlineStyle = isCompact
            ? context.text.headlineSmall?.copyWith(color: Colors.white)
            : context.text.headlineMedium?.copyWith(color: Colors.white);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: fullRadius
                ? BorderRadius.circular(AppRadius.xl)
                : const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      greeting,
                      style: context.text.labelMedium?.copyWith(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              AppSpacing.gapXs,
              Text(
                headline,
                style: headlineStyle,
              ),
              if (subline != null) ...[
                AppSpacing.gapXs,
                Text(
                  subline!,
                  style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                ),
              ],
              if (footer != null) ...[
                AppSpacing.gapMd,
                footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Consistent section heading with an optional action on the right.
class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Small stat tile — a label, a big value, and optional context line.
/// Used on Home for cached ATS / match figures.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color accent;
  final Color accentSurface;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.accentSurface,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconWell(icon: icon, color: accent, background: accentSurface, size: 34),
              AppSpacing.wGapXs,
              Expanded(
                child: Text(
                  label,
                  style: context.text.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.headlineSmall?.copyWith(color: accent)),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: context.text.labelSmall?.copyWith(letterSpacing: 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline informational / insight banner.
class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color accent;
  final Color background;
  final String? actionLabel;
  final VoidCallback? onAction;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.lightbulb_outline_rounded,
    this.accent = AppColors.primary,
    this.background = AppColors.primarySurface,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: accent),
              AppSpacing.wGapSm,
              Expanded(
                child: Text(
                  message,
                  style: context.text.bodyMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.gapXs,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  minimumSize: const Size(0, 36),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel!),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small status pill (e.g. "Core", "AI analysis", "3 fixes").
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: color, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

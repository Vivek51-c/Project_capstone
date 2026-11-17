import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_typography.dart';

enum SkillChipKind { matched, missing, neutral }

/// A single skill pill. `matched` = green tick, `missing` = amber plus.
class SkillChip extends StatelessWidget {
  final String label;
  final SkillChipKind kind;
  final VoidCallback? onTap;

  const SkillChip({
    super.key,
    required this.label,
    this.kind = SkillChipKind.neutral,
    this.onTap,
  });

  Color get _fg => switch (kind) {
        SkillChipKind.matched => AppColors.success,
        SkillChipKind.missing => AppColors.warning,
        SkillChipKind.neutral => AppColors.textSecondary,
      };

  Color get _bg => switch (kind) {
        SkillChipKind.matched => AppColors.successSurface,
        SkillChipKind.missing => AppColors.warningSurface,
        SkillChipKind.neutral => AppColors.surfaceAlt,
      };

  IconData? get _icon => switch (kind) {
        SkillChipKind.matched => Icons.check_rounded,
        SkillChipKind.missing => Icons.add_rounded,
        SkillChipKind.neutral => null,
      };

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.only(
        left: _icon == null ? AppSpacing.sm : AppSpacing.xs,
        right: onTap != null ? AppSpacing.xs : AppSpacing.sm,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: _fg.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_icon != null) ...[
            Icon(_icon, size: 14, color: _fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: context.text.labelMedium?.copyWith(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 15, color: _fg),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return Semantics(
      button: true,
      label: '$label, view learning resources',
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: AppRadius.brPill, onTap: onTap, child: chip),
      ),
    );
  }
}

/// Wraps a list of skills, fading/sliding them in with a short stagger.
class SkillChipWrap extends StatelessWidget {
  final List<String> skills;
  final SkillChipKind kind;
  final void Function(String skill)? onSkillTap;
  final String emptyLabel;
  final int? maxVisible;

  const SkillChipWrap({
    super.key,
    required this.skills,
    this.kind = SkillChipKind.neutral,
    this.onSkillTap,
    this.emptyLabel = 'None',
    this.maxVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Text(
        emptyLabel,
        style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    final visible = maxVisible != null && skills.length > maxVisible!
        ? skills.take(maxVisible!).toList()
        : skills;
    final overflowCount = skills.length - visible.length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < visible.length; i++)
          _StaggeredFadeIn(
            // Cap the stagger so a long list doesn't take forever to appear.
            delay: Duration(milliseconds: (i * 28).clamp(0, 400)),
            child: SkillChip(
              label: visible[i],
              kind: kind,
              onTap: onSkillTap == null ? null : () => onSkillTap!(visible[i]),
            ),
          ),
        if (overflowCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.border),
            ),
            child: Text('+$overflowCount more', style: context.text.labelMedium),
          ),
      ],
    );
  }
}

class _StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _StaggeredFadeIn({required this.child, required this.delay});

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: AppDuration.normal,
      curve: AppDuration.curve,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.18),
        duration: AppDuration.normal,
        curve: AppDuration.curve,
        child: widget.child,
      ),
    );
  }
}

/// A titled group of skill chips with a count badge — used repeatedly across
/// JobMatcher / CareerMatch / SkillBridge.
class SkillGroup extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> skills;
  final SkillChipKind kind;
  final void Function(String skill)? onSkillTap;
  final String emptyLabel;

  const SkillGroup({
    super.key,
    required this.title,
    required this.skills,
    this.subtitle,
    this.kind = SkillChipKind.neutral,
    this.onSkillTap,
    this.emptyLabel = 'None',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: context.text.titleSmall?.copyWith(color: AppColors.textPrimary)),
            AppSpacing.wGapXs,
            Text('${skills.length}', style: context.text.labelSmall),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: context.text.bodySmall),
        ],
        AppSpacing.gapXs,
        SkillChipWrap(
          skills: skills,
          kind: kind,
          onSkillTap: onSkillTap,
          emptyLabel: emptyLabel,
        ),
      ],
    );
  }
}

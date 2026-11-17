import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_typography.dart';
import '../core/error_presenter.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Friendly empty state (brief §20 — never leave a blank screen).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final Color accentSurface;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.accent = AppColors.primary,
    this.accentSurface = AppColors.primarySurface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accentSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 34, color: accent),
          ),
          AppSpacing.gapMd,
          Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
          AppSpacing.gapXs,
          Text(message, style: context.text.bodyMedium, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.gapLg,
            SecondaryButton(label: actionLabel!, onPressed: onAction, expand: false),
          ],
        ],
      ),
    );
  }
}

/// Polished error state with a Try Again action and collapsible technical
/// detail for debugging (brief §21).
class ErrorStateView extends StatefulWidget {
  final Object error;
  final Future<void> Function()? onRetry;

  const ErrorStateView({super.key, required this.error, this.onRetry});

  @override
  State<ErrorStateView> createState() => _ErrorStateViewState();
}

class _ErrorStateViewState extends State<ErrorStateView> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final friendly = FriendlyError.from(widget.error);

    return PremiumCard(
      background: AppColors.errorSurface,
      borderColor: AppColors.error.withValues(alpha: 0.2),
      shadow: const [],
      padding: AppSpacing.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(friendly.icon, color: AppColors.error, size: 22),
              AppSpacing.wGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friendly.title, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(friendly.message, style: context.text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (widget.onRetry != null && friendly.isRetryable) ...[
            AppSpacing.gapMd,
            PrimaryButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: widget.onRetry,
              expand: false,
            ),
          ],
          AppSpacing.gapXs,
          InkWell(
            onTap: () => setState(() => _showDetail = !_showDetail),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showDetail ? 'Hide technical details' : 'Show technical details',
                    style: context.text.labelMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  Icon(
                    _showDetail ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brSm,
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                friendly.technicalDetail,
                style: context.text.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            crossFadeState: _showDetail ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: AppDuration.fast,
          ),
        ],
      ),
    );
  }
}

/// One stage in a multi-step loading sequence.
class LoadingStage {
  final String label;
  const LoadingStage(this.label);
}

/// Staged loader for long AI/NLP operations (brief §19). Stages advance on a
/// timer purely as *progress feedback* — the backend does not stream real
/// progress, so stage timings are indicative, and the final stage stays
/// active until the actual request completes.
class StagedLoader extends StatefulWidget {
  final List<LoadingStage> stages;
  final String title;
  final Duration stageInterval;

  const StagedLoader({
    super.key,
    required this.stages,
    required this.title,
    this.stageInterval = const Duration(milliseconds: 1400),
  });

  @override
  State<StagedLoader> createState() => _StagedLoaderState();
}

class _StagedLoaderState extends State<StagedLoader> {
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _advance();
  }

  void _advance() {
    Future.delayed(widget.stageInterval, () {
      if (!mounted) return;
      // Hold on the last stage rather than pretending we've finished.
      if (_active < widget.stages.length - 1) {
        setState(() => _active += 1);
        _advance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: AppSpacing.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              AppSpacing.wGapSm,
              Expanded(child: Text(widget.title, style: context.text.titleMedium)),
            ],
          ),
          AppSpacing.gapMd,
          for (var i = 0; i < widget.stages.length; i++)
            _StageRow(
              label: widget.stages[i].label,
              state: i < _active
                  ? _StageState.done
                  : (i == _active ? _StageState.active : _StageState.pending),
            ),
        ],
      ),
    );
  }
}

enum _StageState { done, active, pending }

class _StageRow extends StatelessWidget {
  final String label;
  final _StageState state;

  const _StageRow({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      _StageState.done => (Icons.check_circle_rounded, AppColors.success),
      _StageState.active => (Icons.radio_button_checked_rounded, AppColors.primary),
      _StageState.pending => (Icons.radio_button_unchecked_rounded, AppColors.textTertiary),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppDuration.fast,
            child: Icon(icon, key: ValueKey(state), size: 18, color: color),
          ),
          AppSpacing.wGapSm,
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: AppDuration.fast,
              style: (context.text.bodyMedium ?? const TextStyle()).copyWith(
                color: state == _StageState.pending
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
                fontWeight: state == _StageState.active ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering placeholder block for skeleton screens.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonBox({super.key, required this.height, this.width, this.radius = AppRadius.sm});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.surfaceAlt, AppColors.border, _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Generic skeleton for a list of cards while data loads.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({super.key, this.itemCount = 3, this.itemHeight = 84});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          SkeletonBox(height: itemHeight, radius: AppRadius.lg),
          if (i != itemCount - 1) AppSpacing.gapSm,
        ],
      ],
    );
  }
}

/// Success/warning finding row, shared by ATS TuneUp and ResumeBuilder
/// validation.
class FindingTile extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const FindingTile({super.key, required this.isSuccess, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 18,
            color: color,
          ),
          AppSpacing.wGapXs,
          Expanded(
            child: Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Themed snackbar helper — replaces the old raw `e.toString()` snackbar.
void showFriendlySnackBar(BuildContext context, Object error) {
  final friendly = FriendlyError.from(error);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(friendly.icon, color: Colors.white, size: 19),
            AppSpacing.wGapSm,
            Expanded(child: Text('${friendly.title} — ${friendly.message}')),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
}

void showSuccessSnackBar(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 19),
            AppSpacing.wGapSm,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        action: action,
      ),
    );
}

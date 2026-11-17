import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_typography.dart';
import 'buttons.dart';

/// Premium file upload component (brief §18) with four visual states:
/// idle (dashed drop zone), reading, uploaded (filename + change), error.
///
/// Behaviour is unchanged from the original FileUploadCard: PDF/DOCX only,
/// `withData: true` so bytes are available on every platform, and the same
/// 10 MB cap the backend enforces (app.core.config.MAX_UPLOAD_SIZE_BYTES).
class UploadCard extends StatefulWidget {
  final String label;
  final String hint;
  final ValueChanged<PickedFile?> onChanged;
  final Color accent;
  final Color accentSurface;
  final IconData icon;

  const UploadCard({
    super.key,
    required this.label,
    required this.onChanged,
    this.hint = 'PDF or DOCX · up to 10 MB',
    this.accent = AppColors.primary,
    this.accentSurface = AppColors.primarySurface,
    this.icon = Icons.cloud_upload_outlined,
  });

  @override
  State<UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends State<UploadCard> {
  PickedFile? _picked;
  String? _error;
  bool _reading = false;

  static const int _maxBytes = 10 * 1024 * 1024;

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _reading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _reading = false);
        return;
      }

      final file = result.files.single;

      if (file.bytes == null) {
        setState(() {
          _reading = false;
          _error = "We couldn't read that file. Please try another one.";
        });
        return;
      }

      if (file.bytes!.length > _maxBytes) {
        final mb = (file.bytes!.length / (1024 * 1024)).toStringAsFixed(1);
        setState(() {
          _reading = false;
          _error = 'That file is $mb MB. Please upload one under 10 MB.';
        });
        return;
      }

      final picked = PickedFile(
        filename: file.name,
        bytes: file.bytes!,
        contentType: file.extension == 'pdf'
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );

      setState(() {
        _picked = picked;
        _reading = false;
      });
      widget.onChanged(picked);
    } catch (e) {
      setState(() {
        _reading = false;
        _error = 'Something went wrong picking that file. Please try again.';
      });
    }
  }

  void _clear() {
    setState(() {
      _picked = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDuration.fast,
      curve: AppDuration.curve,
      child: _picked != null ? _buildUploaded(context) : _buildIdle(context),
    );
  }

  // --- Uploaded state ----------------------------------------------------

  Widget _buildUploaded(BuildContext context) {
    final file = _picked!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
          ),
          AppSpacing.wGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.filename,
                  style: context.text.titleSmall?.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.label} · ${_sizeLabel(file.bytes.length)}',
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _clear,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // --- Idle / reading / error state ---------------------------------------

  Widget _buildIdle(BuildContext context) {
    final hasError = _error != null;
    final borderColor = hasError ? AppColors.error : widget.accent.withValues(alpha: 0.35);

    return PressableScale(
      onTap: _reading ? null : _pick,
      child: Semantics(
        button: true,
        label: 'Upload ${widget.label}',
        child: CustomPaint(
          painter: _DashedBorderPainter(color: borderColor, radius: AppRadius.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: hasError ? AppColors.errorSurface : widget.accentSurface.withValues(alpha: 0.45),
              borderRadius: AppRadius.brLg,
            ),
            child: Column(
              children: [
                if (_reading)
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(widget.accent),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: hasError ? AppColors.errorSurface : widget.accentSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasError ? Icons.error_outline_rounded : widget.icon,
                      color: hasError ? AppColors.error : widget.accent,
                      size: 23,
                    ),
                  ),
                AppSpacing.gapSm,
                Text(
                  _reading ? 'Reading file…' : widget.label,
                  style: context.text.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  _error ?? widget.hint,
                  style: context.text.bodySmall?.copyWith(
                    color: hasError ? AppColors.error : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!_reading) ...[
                  AppSpacing.gapMd,
                  OutlinedButton(
                    onPressed: _pick,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: widget.accent.withValues(alpha: 0.4)),
                      foregroundColor: widget.accent,
                    ),
                    child: Text(hasError ? 'Try another file' : 'Choose file'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rect border for the drop-zone look.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
  }) : dashWidth = 6, dashGap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}

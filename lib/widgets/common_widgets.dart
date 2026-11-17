import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Home-screen tile for each of the 6 features.
class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular score gauge used by JobMatcher / ATS TuneUp.
class ScoreGauge extends StatelessWidget {
  final int score; // 0-100
  final String label;

  const ScoreGauge({super.key, required this.score, this.label = 'Score'});

  Color get _color {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _color)),
                  const Text('/ 100', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// Wraps a list of skill names as small pill chips.
class SkillChipList extends StatelessWidget {
  final List<String> skills;
  final Color color;
  final IconData icon;

  const SkillChipList({
    super.key,
    required this.skills,
    this.color = AppTheme.primary,
    this.icon = Icons.check_circle,
  });

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Text('None', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map((s) => Chip(
                avatar: Icon(icon, size: 16, color: color),
                label: Text(s),
                backgroundColor: color.withValues(alpha: 0.08),
                side: BorderSide(color: color.withValues(alpha: 0.25)),
              ))
          .toList(),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Button that shows a spinner and disables itself while `onPressed` runs.
class LoadingButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final IconData? icon;

  const LoadingButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    setState(() => _loading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _handleTap,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(widget.icon ?? Icons.arrow_forward),
      label: Text(_loading ? 'Working…' : widget.label),
    );
  }
}

/// Standard findings row used by ATS TuneUp (green check / amber warning).
class FindingRow extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const FindingRow({super.key, required this.isSuccess, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppTheme.success : AppTheme.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isSuccess ? Icons.check_circle : Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

void showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString()), backgroundColor: AppTheme.danger),
  );
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/local_history.dart';
import '../main.dart';
import '../models/skill_bridge_models.dart';
import '../widgets/common_widgets.dart' show showErrorSnackBar;
import '../widgets/ui_kit.dart';

class SkillBridgeScreen extends StatefulWidget {
  const SkillBridgeScreen({super.key});

  @override
  State<SkillBridgeScreen> createState() => _SkillBridgeScreenState();
}

class _SkillBridgeScreenState extends State<SkillBridgeScreen> {
  PickedFile? _resume;
  List<String> _roles = [];
  String? _selectedRole;
  bool _loadingRoles = true;
  SkillBridgeResult? _result;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await apiClient.getSkillBridgeRoles();
      setState(() {
        _roles = roles;
        _loadingRoles = false;
      });
    } catch (e) {
      setState(() => _loadingRoles = false);
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _analyze() async {
    if (_resume == null || _selectedRole == null) {
      showErrorSnackBar(context, 'Upload a resume and pick a role first.');
      return;
    }
    try {
      final result = await apiClient.analyzeSkillGap(resume: _resume!, role: _selectedRole!);
      await LocalHistory.instance.recordSkillGap(
        role: result.role,
        matched: result.matchedSkillCount,
        required_: result.requiredSkillCount,
        missingTop: result.missingSkills,
      );
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _openResourcesFor(String skill) async {
    try {
      final links = await apiClient.getLearningResources(skill);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _ResourceSheet(links: links),
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('SkillBridge')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const GradientHeader(
              fullRadius: true,
              greeting: 'Upskilling Roadmap',
              headline: 'Bridge the gap to your\ndream career.',
              subline: 'Select a target job profile to detect missing proficiencies and access curated learning paths.',
            ),
            AppSpacing.gapXl,

            UploadCard(
              label: 'Your Resume',
              hint: 'PDF or DOCX · up to 10 MB',
              accent: AppColors.skillBridge,
              accentSurface: AppColors.skillBridgeSurface,
              icon: Icons.school_outlined,
              onChanged: (f) => setState(() => _resume = f),
            ),
            AppSpacing.gapLg,

            PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeading(
                    title: 'Target Role',
                    subtitle: 'Choose the career path you want to prepare for',
                  ),
                  if (_loadingRoles)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    DropdownMenu<String>(
                      expandedInsets: EdgeInsets.zero,
                      hintText: 'Select a role…',
                      enableSearch: true,
                      dropdownMenuEntries:
                          _roles.map((r) => DropdownMenuEntry(value: r, label: r)).toList(),
                      onSelected: (v) => setState(() => _selectedRole = v),
                    ),
                  AppSpacing.gapLg,
                  PrimaryButton(
                    label: 'Analyze Skill Gap',
                    loadingLabel: 'Mapping required competencies…',
                    icon: Icons.school_outlined,
                    onPressed: _analyze,
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              AppSpacing.gapXl,
              ..._buildResult(_result!),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResult(SkillBridgeResult result) {
    return [
      PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            MetricBar(
              label: '${result.role} Match',
              progress: result.matchRatio,
              valueLabel: '${result.matchedSkillCount} / ${result.requiredSkillCount} skills (${(result.matchRatio * 100).round()}%)',
              color: AppColors.skillBridge,
            ),
            Text(
              result.missingSkills.isEmpty
                  ? 'Ready to apply! You possess all core skills identified for this role.'
                  : 'You have a solid foundation. Bridge the remaining ${result.missingSkills.length} skills below.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      AppSpacing.gapXl,

      const SectionHeading(
        title: 'Acquired Proficiencies',
        subtitle: 'Skills from your resume matched with this role',
      ),
      PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SkillChipWrap(
          skills: result.matchedSkills,
          kind: SkillChipKind.matched,
        ),
      ),
      AppSpacing.gapXl,

      const SectionHeading(
        title: 'Skills to Bridge',
        subtitle: 'Tap any skill to explore recommended courses & tutorials',
      ),
      PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: result.missingSkills.isEmpty
            ? const Text(
                'No skill gap detected — you are fully qualified!',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
              )
            : SkillChipWrap(
                skills: result.missingSkills,
                kind: SkillChipKind.missing,
                onSkillTap: _openResourcesFor,
              ),
      ),
    ];
  }
}

class _ResourceSheet extends StatelessWidget {
  final LearningResourceLinks links;
  const _ResourceSheet({required this.links});

  static const _providerIcons = {
    'YouTube': Icons.smart_display_rounded,
    'Udemy': Icons.ondemand_video_rounded,
    'Coursera': Icons.menu_book_rounded,
    'edX': Icons.school_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final entries = {
      'YouTube': links.youtube,
      'Udemy': links.udemy,
      'Coursera': links.coursera,
      'edX': links.edx,
    };
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.gapLg,
              Row(
                children: [
                  const IconWell(
                    icon: Icons.school_rounded,
                    color: AppColors.skillBridge,
                    background: AppColors.skillBridgeSurface,
                    size: 42,
                  ),
                  AppSpacing.wGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learn "${links.skill}"',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const Text(
                          'Curated courses & interactive tutorials',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              const Divider(),
              ...entries.entries.map(
                (e) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  leading: Icon(_providerIcons[e.key] ?? Icons.open_in_new_rounded, color: AppColors.skillBridge),
                  title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Open platform search in browser', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_outward_rounded, size: 18, color: AppColors.textTertiary),
                  onTap: () => launchUrl(Uri.parse(e.value), mode: LaunchMode.externalApplication),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

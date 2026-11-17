import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/local_history.dart';
import '../main.dart';
import '../models/career_match_models.dart';
import '../widgets/common_widgets.dart' show showErrorSnackBar;
import '../widgets/ui_kit.dart';

class CareerMatchScreen extends StatefulWidget {
  const CareerMatchScreen({super.key});

  @override
  State<CareerMatchScreen> createState() => _CareerMatchScreenState();
}

class _CareerMatchScreenState extends State<CareerMatchScreen> {
  PickedFile? _resume;
  CareerMatchResult? _result;

  Future<void> _analyze() async {
    if (_resume == null) {
      showErrorSnackBar(context, 'Upload a resume first.');
      return;
    }
    try {
      final result = await apiClient.analyzeCareerMatch(resume: _resume!, topN: 5);
      if (result.recommendedJobs.isNotEmpty) {
        final top = result.recommendedJobs.first;
        await LocalHistory.instance.recordCareerTopRole(top.title, top.matchCount);
      }
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CareerMatch')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const GradientHeader(
              fullRadius: true,
              greeting: 'Career Discovery',
              headline: 'Discover the right roles\nfor your profile.',
              subline: 'Extract your experience, education, and skills to find top matching career paths.',
            ),
            AppSpacing.gapXl,

            UploadCard(
              label: 'Your Resume',
              hint: 'PDF or DOCX · up to 10 MB',
              accent: AppColors.careerMatch,
              accentSurface: AppColors.careerMatchSurface,
              icon: Icons.psychology_outlined,
              onChanged: (f) => setState(() => _resume = f),
            ),
            AppSpacing.gapLg,

            PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PrimaryButton(
                label: 'Find Matching Roles',
                loadingLabel: 'Analyzing career matches…',
                icon: Icons.work_outline_rounded,
                onPressed: _analyze,
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

  List<Widget> _buildResult(CareerMatchResult result) {
    final info = result.extractedInfo;
    return [
      const SectionHeading(
        title: 'Extracted Profile',
        subtitle: 'Details recognized from your uploaded document',
      ),
      PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.name != null) _infoRow('Name', info.name!),
            if (info.email != null) _infoRow('Email', info.email!),
            if (info.phone != null) _infoRow('Phone', info.phone!),
            if (info.degree != null) _infoRow('Degree', info.degree!),
            if (info.specialization != null) _infoRow('Specialization', info.specialization!),
            if (info.university != null) _infoRow('University', info.university!),
            if (info.graduationYear != null) _infoRow('Graduation Year', info.graduationYear!),
            if (info.skills.isNotEmpty) ...[
              AppSpacing.gapMd,
              Text(
                'Identified Skills (${info.skills.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              AppSpacing.gapSm,
              SkillChipWrap(
                skills: info.skills,
                kind: SkillChipKind.matched,
              ),
            ],
          ],
        ),
      ),
      AppSpacing.gapXl,
      const SectionHeading(
        title: 'Recommended Roles',
        subtitle: 'Roles ranked by skills alignment',
      ),
      ...result.recommendedJobs.map(
        (job) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: PremiumCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              initiallyExpanded: job == result.recommendedJobs.first,
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              leading: const IconWell(
                icon: Icons.stars_rounded,
                color: AppColors.careerMatch,
                background: AppColors.careerMatchSurface,
                size: 40,
              ),
              title: Text(
                job.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                '${job.matchCount} matching skills',
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              children: [
                const Divider(),
                AppSpacing.gapSm,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Matched Skills (${job.matchedSkills.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                AppSpacing.gapSm,
                SkillChipWrap(skills: job.matchedSkills, kind: SkillChipKind.matched),
                if (job.descriptions.isNotEmpty) ...[
                  AppSpacing.gapLg,
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Role Details',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                  AppSpacing.gapSm,
                  ...job.descriptions.map(
                    (d) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(d.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

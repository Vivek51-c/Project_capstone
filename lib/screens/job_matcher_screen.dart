import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/local_history.dart';
import '../main.dart';
import '../models/job_matcher_models.dart';
import '../widgets/auth/app_text_field.dart';
import '../widgets/common_widgets.dart' show showErrorSnackBar;
import '../widgets/ui_kit.dart';

class JobMatcherScreen extends StatefulWidget {
  const JobMatcherScreen({super.key});

  @override
  State<JobMatcherScreen> createState() => _JobMatcherScreenState();
}

class _JobMatcherScreenState extends State<JobMatcherScreen> {
  PickedFile? _resume;
  PickedFile? _jdFile;
  bool _useJdFile = false;
  final _jdTextController = TextEditingController();

  JobMatchResult? _result;

  bool get _canAnalyze =>
      _resume != null && (_useJdFile ? _jdFile != null : _jdTextController.text.trim().isNotEmpty);

  Future<void> _analyze() async {
    if (!_canAnalyze) {
      showErrorSnackBar(context, 'Add a resume and a job description first.');
      return;
    }
    try {
      final result = await apiClient.analyzeJobMatch(
        resume: _resume!,
        jdFile: _useJdFile ? _jdFile : null,
        jdText: _useJdFile ? null : _jdTextController.text.trim(),
      );
      await LocalHistory.instance.recordJobMatch(result.finalScore);
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  void dispose() {
    _jdTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('JobMatcher')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const GradientHeader(
              fullRadius: true,
              greeting: 'Role Alignment',
              headline: 'Match your resume to\nany job description.',
              subline: 'Compare core competencies, hard skills, and soft skills with detailed overlap scoring.',
            ),
            AppSpacing.gapXl,

            UploadCard(
              label: 'Your Resume',
              hint: 'PDF or DOCX · up to 10 MB',
              accent: AppColors.jobMatcher,
              accentSurface: AppColors.jobMatcherSurface,
              icon: Icons.description_rounded,
              onChanged: (f) => setState(() => _resume = f),
            ),
            AppSpacing.gapLg,

            PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeading(
                    title: 'Target Job Description',
                    subtitle: 'Choose how to provide the job listing',
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 380) {
                        return DropdownButtonFormField<bool>(
                          initialValue: _useJdFile,
                          decoration: const InputDecoration(
                              labelText: 'Job description input'),
                          items: const [
                            DropdownMenuItem(
                                value: false, child: Text('Paste text')),
                            DropdownMenuItem(
                                value: true, child: Text('Upload file')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _useJdFile = value);
                            }
                          },
                        );
                      }
                      return SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: false,
                              label: Text('Paste text'),
                              icon: Icon(Icons.edit_note_rounded)),
                          ButtonSegment(
                              value: true,
                              label: Text('Upload file'),
                              icon: Icon(Icons.upload_file_rounded)),
                        ],
                        selected: {_useJdFile},
                        onSelectionChanged: (s) =>
                            setState(() => _useJdFile = s.first),
                      );
                    },
                  ),
                  AppSpacing.gapLg,
                  if (_useJdFile)
                    UploadCard(
                      label: 'Job Description File',
                      hint: 'PDF or DOCX · up to 10 MB',
                      accent: AppColors.jobMatcher,
                      accentSurface: AppColors.jobMatcherSurface,
                      icon: Icons.article_outlined,
                      onChanged: (f) => setState(() => _jdFile = f),
                    )
                  else
                    AppTextField(
                      controller: _jdTextController,
                      maxLines: 6,
                      label: 'Job Description',
                      hint: 'Paste the requirements, responsibilities, or entire job post here…',
                      onChanged: (_) => setState(() {}),
                    ),
                  AppSpacing.gapLg,
                  PrimaryButton(
                    label: 'Analyze Match',
                    loadingLabel: 'Comparing skills & requirements…',
                    icon: Icons.compare_arrows_rounded,
                    onPressed: _analyze,
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              AppSpacing.gapXl,
              _ResultView(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final JobMatchResult result;
  const _ResultView({required this.result});

  String get _verdictLabel {
    switch (result.verdict) {
      case 'excellent':
        return 'Excellent match!';
      case 'good':
        return 'Good match';
      default:
        return 'Needs improvement';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
          child: Column(
            children: [
              Center(
                child: AnimatedScoreGauge(
                  score: result.finalScore,
                  label: _verdictLabel,
                  caption: 'Weighted compatibility score',
                ),
              ),
              AppSpacing.gapLg,
              const Divider(),
              AppSpacing.gapMd,
              MetricBar(
                label: 'Hard Skills Match (Weight 90%)',
                progress: result.hardPct / 100,
                valueLabel: '${result.hardPct.toStringAsFixed(0)}%',
                color: AppColors.jobMatcher,
              ),
              MetricBar(
                label: 'Soft Skills Match (Weight 10%)',
                progress: result.softPct / 100,
                valueLabel: '${result.softPct.toStringAsFixed(0)}%',
                color: AppColors.careerMatch,
              ),
            ],
          ),
        ),
        AppSpacing.gapXl,

        const SectionHeading(
          title: 'Matched Skills',
          subtitle: 'Skills found in both your resume and the job description',
        ),
        PremiumCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.matchedHardSkills.core.isNotEmpty) ...[
                SkillGroup(
                  title: 'Core Hard Skills',
                  skills: result.matchedHardSkills.core,
                  kind: SkillChipKind.matched,
                ),
                AppSpacing.gapMd,
              ],
              if (result.matchedHardSkills.important.isNotEmpty) ...[
                SkillGroup(
                  title: 'Important Hard Skills',
                  skills: result.matchedHardSkills.important,
                  kind: SkillChipKind.matched,
                ),
                AppSpacing.gapMd,
              ],
              if (result.matchedHardSkills.optional.isNotEmpty) ...[
                SkillGroup(
                  title: 'Nice-to-Have Skills',
                  skills: result.matchedHardSkills.optional,
                  kind: SkillChipKind.neutral,
                ),
                AppSpacing.gapMd,
              ],
              SkillGroup(
                title: 'Soft Skills',
                skills: result.matchedSoftSkills,
                kind: SkillChipKind.matched,
              ),
            ],
          ),
        ),
        AppSpacing.gapXl,

        const SectionHeading(
          title: 'Missing Skills',
          subtitle: 'Required qualifications not detected in your resume',
        ),
        PremiumCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.missingHardSkills.core.isNotEmpty) ...[
                SkillGroup(
                  title: 'Critical Missing Skills',
                  skills: result.missingHardSkills.core,
                  kind: SkillChipKind.missing,
                ),
                AppSpacing.gapMd,
              ],
              if (result.missingHardSkills.important.isNotEmpty) ...[
                SkillGroup(
                  title: 'Important Missing Skills',
                  skills: result.missingHardSkills.important,
                  kind: SkillChipKind.missing,
                ),
                AppSpacing.gapMd,
              ],
              if (result.missingHardSkills.optional.isNotEmpty) ...[
                SkillGroup(
                  title: 'Optional Missing Skills',
                  skills: result.missingHardSkills.optional,
                  kind: SkillChipKind.neutral,
                ),
              ],
              if (result.missingHardSkills.core.isEmpty &&
                  result.missingHardSkills.important.isEmpty &&
                  result.missingHardSkills.optional.isEmpty)
                const Text(
                  'No critical missing skills found!',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

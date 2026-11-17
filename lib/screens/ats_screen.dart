import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth/session_controller.dart';
import '../core/local_history.dart';
import '../main.dart';
import '../models/ats_models.dart';
import '../models/resume_builder_models.dart';
import '../widgets/auth/app_text_field.dart';
import '../widgets/common_widgets.dart' show showErrorSnackBar, FindingRow;
import '../widgets/ui_kit.dart';

class AtsTuneUpScreen extends StatefulWidget {
  const AtsTuneUpScreen({super.key});

  @override
  State<AtsTuneUpScreen> createState() => _AtsTuneUpScreenState();
}

class _AtsTuneUpScreenState extends State<AtsTuneUpScreen> {
  PickedFile? _resume;
  bool _useAi = false;
  final _geminiKeyController = TextEditingController();

  LocalAtsResult? _localResult;
  AiAtsResult? _aiResult;
  List<SavedResumeVersion> _savedVersions = [];
  SavedResumeVersion? _selectedVersion;
  bool _loadingVersions = true;
  bool _runningSavedAnalysis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedVersions());
  }

  Future<void> _loadSavedVersions() async {
    final token = SessionScope.of(context).token;
    if (token == null) {
      if (mounted) setState(() => _loadingVersions = false);
      return;
    }
    try {
      final versions = await apiClient.getResumeVersions(token: token);
      if (!mounted) return;
      setState(() {
        _savedVersions = versions;
        _selectedVersion = versions.isEmpty ? null : versions.first;
        _loadingVersions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingVersions = false);
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _run() async {
    if (_resume == null) {
      showErrorSnackBar(context, 'Upload a resume first.');
      return;
    }
    try {
      if (_useAi) {
        final result = await apiClient.runAiAts(
            resume: _resume!, geminiApiKey: _geminiKeyController.text.trim());
        if (result.atsScore != null) {
          await LocalHistory.instance
              .recordAtsScore(result.atsScore!, source: 'ai');
        }
        setState(() {
          _aiResult = result;
          _localResult = null;
        });
      } else {
        final result = await apiClient.runLocalAts(resume: _resume!);
        final totalFindings =
            result.steps.fold(0, (sum, s) => sum + s.findings.length);
        final cleanFindings = totalFindings - result.totalWarnings;
        if (totalFindings > 0) {
          final score = ((cleanFindings / totalFindings) * 100).round();
          await LocalHistory.instance.recordAtsScore(score, source: 'local');
        }
        setState(() {
          _localResult = result;
          _aiResult = null;
        });
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _runSavedResume() async {
    final version = _selectedVersion;
    final token = SessionScope.of(context).token;
    if (version == null || token == null) {
      showErrorSnackBar(
          context, 'Save a resume version before running this analysis.');
      return;
    }
    setState(() => _runningSavedAnalysis = true);
    try {
      final result = await apiClient.runSavedResumeAts(
        token: token,
        versionId: version.id,
        useAi: _useAi,
        geminiApiKey: _geminiKeyController.text.trim(),
      );
      if (result.score != null) {
        await LocalHistory.instance
            .recordAtsScore(result.score!, source: result.mode);
      }
      if (!mounted) return;
      setState(() {
        if (result.mode == 'ai') {
          _aiResult = AiAtsResult.fromJson(result.analysis);
          _localResult = null;
        } else {
          _localResult = LocalAtsResult.fromJson(result.analysis);
          _aiResult = null;
        }
        _runningSavedAnalysis = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _runningSavedAnalysis = false);
      showErrorSnackBar(context, e);
    }
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ATS TuneUp')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const GradientHeader(
              fullRadius: true,
              greeting: 'Resume Diagnostics',
              headline: 'Beat the ATS.\nLand more interviews.',
              subline:
                  'Validate formatting, section structure, keyword signals, and contact info against standard applicant tracking systems.',
            ),
            AppSpacing.gapXl,
            PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeading(
                    title: 'Analyze a saved resume',
                    subtitle:
                        'Results are kept with the selected version in Profile.',
                  ),
                  AppSpacing.gapSm,
                  if (_loadingVersions)
                    const LinearProgressIndicator()
                  else if (_savedVersions.isEmpty)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final builderButton = TextButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/resume-builder')
                                  .then((_) => _loadSavedVersions()),
                          icon: const Icon(Icons.edit_document),
                          label: const Text('Resume Builder'),
                        );
                        if (constraints.maxWidth < 420) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('No saved resume versions yet.'),
                              Align(
                                alignment: Alignment.centerRight,
                                child: builderButton,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            const Expanded(
                                child: Text('No saved resume versions yet.')),
                            builderButton,
                          ],
                        );
                      },
                    )
                  else ...[
                    DropdownButtonFormField<SavedResumeVersion>(
                      initialValue: _selectedVersion,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Resume version'),
                      items: _savedVersions
                          .map((version) => DropdownMenuItem(
                                value: version,
                                child: Text(
                                  'Version ${version.version} · ${version.filename}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (version) =>
                          setState(() => _selectedVersion = version),
                    ),
                    AppSpacing.gapMd,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _runningSavedAnalysis ? null : _runSavedResume,
                        icon: _runningSavedAnalysis
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.fact_check_outlined),
                        label: Text(
                          _useAi
                              ? 'Run AI analysis on saved version'
                              : 'Run local checks on saved version',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapLg,
            UploadCard(
              label: 'Your Resume',
              hint: 'PDF or DOCX · up to 10 MB',
              accent: AppColors.atsTuneUp,
              accentSurface: AppColors.atsTuneUpSurface,
              icon: Icons.description_rounded,
              onChanged: (f) => setState(() => _resume = f),
            ),
            AppSpacing.gapLg,
            PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 380) {
                        return DropdownButtonFormField<bool>(
                          initialValue: _useAi,
                          decoration:
                              const InputDecoration(labelText: 'Analysis mode'),
                          items: const [
                            DropdownMenuItem(
                                value: false, child: Text('Local checks')),
                            DropdownMenuItem(
                                value: true, child: Text('AI analysis')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _useAi = value);
                            }
                          },
                        );
                      }
                      return SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: false,
                              label: Text('Local checks'),
                              icon: Icon(Icons.rule_rounded)),
                          ButtonSegment(
                              value: true,
                              label: Text('AI analysis'),
                              icon: Icon(Icons.auto_awesome_rounded)),
                        ],
                        selected: {_useAi},
                        onSelectionChanged: (s) =>
                            setState(() => _useAi = s.first),
                      );
                    },
                  ),
                  if (_useAi) ...[
                    AppSpacing.gapLg,
                    AppTextField(
                      controller: _geminiKeyController,
                      isPassword: true,
                      label: 'Gemini API key',
                      hint: 'Leave blank to use server default (if configured)',
                      prefixIcon: Icons.key_rounded,
                    ),
                  ],
                  AppSpacing.gapLg,
                  PrimaryButton(
                    label: _useAi ? 'Run AI Analysis' : 'Run Local Checks',
                    loadingLabel: 'Analyzing resume…',
                    icon: Icons.fact_check_outlined,
                    onPressed: _run,
                  ),
                ],
              ),
            ),
            if (_localResult != null || _aiResult != null) ...[
              AppSpacing.gapXl,
              if (_localResult != null) _LocalResultView(result: _localResult!),
              if (_aiResult != null) _AiResultView(result: _aiResult!),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocalResultView extends StatelessWidget {
  final LocalAtsResult result;
  const _LocalResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final totalFindings =
        result.steps.fold(0, (sum, s) => sum + s.findings.length);
    final cleanFindings = totalFindings - result.totalWarnings;
    final score = totalFindings == 0
        ? 0
        : ((cleanFindings / totalFindings) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
          child: Center(
            child: AnimatedScoreGauge(
              score: score,
              label: 'ATS Readiness',
              caption: '$cleanFindings of $totalFindings audit checks passed',
            ),
          ),
        ),
        AppSpacing.gapLg,
        const SectionHeading(
          title: 'Detailed Checkpoints',
          subtitle: 'Expand each category to review findings',
        ),
        ...result.steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: PremiumCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded: step.warningCount > 0,
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Text(
                  '${step.step}. ${step.title}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  step.warningCount == 0
                      ? 'All good'
                      : '${step.warningCount} item(s) to improve',
                  style: TextStyle(
                    color: step.warningCount == 0
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                children: step.findings
                    .map((f) =>
                        FindingRow(isSuccess: f.isSuccess, message: f.message))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiResultView extends StatelessWidget {
  final AiAtsResult result;
  const _AiResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.atsScore != null) ...[
          PremiumCard(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
            child: Center(
              child: AnimatedScoreGauge(
                score: result.atsScore!,
                label: 'AI ATS Score',
                caption: 'AI-evaluated resume screening compatibility',
              ),
            ),
          ),
          AppSpacing.gapLg,
        ],
        const SectionHeading(
          title: 'Category Breakdown',
          subtitle: 'AI strengths and recommended improvements',
        ),
        ...result.categories.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: PremiumCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Text(entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${entry.value.positives.length} positive · ${entry.value.negatives.length} warning(s)',
                  style: TextStyle(
                    color: entry.value.negatives.isEmpty
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                children: [
                  ...entry.value.positives
                      .map((p) => FindingRow(isSuccess: true, message: p)),
                  ...entry.value.negatives
                      .map((n) => FindingRow(isSuccess: false, message: n)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/local_history.dart';
import '../main.dart';
import '../widgets/auth/app_text_field.dart';
import '../widgets/ui_kit.dart';

class JobRadarScreen extends StatefulWidget {
  const JobRadarScreen({super.key});

  @override
  State<JobRadarScreen> createState() => _JobRadarScreenState();
}

class _JobRadarScreenState extends State<JobRadarScreen> {
  final _jobController = TextEditingController();
  final _locationController = TextEditingController(text: 'India');
  Map<String, String>? _links;
  String? _searchError;
  String _selectedPlatform = 'all';

  static const _platformLabels = {
    'linkedin': 'LinkedIn',
    'foundit': 'Foundit',
    'timesjobs': 'TimesJobs',
    'indeed': 'Indeed',
    'naukri': 'Naukri',
    'freshersworld': 'FreshersWorld',
    'instahyre': 'Instahyre',
    'shine': 'Shine',
  };

  static const _platformInitials = {
    'linkedin': 'in',
    'foundit': 'f',
    'timesjobs': 'T',
    'indeed': 'i',
    'naukri': 'N',
    'freshersworld': 'FW',
    'instahyre': 'I',
    'shine': 'S',
  };

  static const _platformColors = {
    'linkedin': Color(0xFF0A66C2),
    'foundit': Color(0xFF5427A5),
    'timesjobs': Color(0xFF2457A7),
    'indeed': Color(0xFF2164F3),
    'naukri': Color(0xFF27835B),
    'freshersworld': Color(0xFF168A91),
    'instahyre': Color(0xFFD65C32),
    'shine': Color(0xFFD18A12),
  };

  Future<void> _search() async {
    final job = _jobController.text.trim();
    if (job.isEmpty) {
      setState(() => _searchError = 'Enter a job title to search across platforms.');
      return;
    }
    final enteredLocation = _locationController.text.trim();
    final location = enteredLocation.isEmpty ? 'India' : enteredLocation;
    setState(() {
      _searchError = null;
      _links = null;
      _selectedPlatform = 'all';
    });
    try {
      final links = await apiClient.getJobSearchLinks(job: job, location: location);
      await LocalHistory.instance.recordJobSearch(job, location);
      if (!mounted) return;
      setState(() => _links = links);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = e.toString());
    }
  }

  Future<void> _openPlatform(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _jobController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('JobRadar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Search form
            PremiumCard(
              background: AppColors.primarySurface,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Find your next opportunity', style: context.text.headlineSmall),
                  AppSpacing.gapXs,
                  Text(
                    'Search trusted job platforms from one focused workspace.',
                    style: context.text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  AppSpacing.gapLg,
                  if (_searchError != null) ...[
                    InfoBanner(
                      message: _searchError!,
                      icon: Icons.error_outline_rounded,
                      accent: AppColors.error,
                      background: AppColors.errorSurface,
                    ),
                    AppSpacing.gapMd,
                  ],
                  AppTextField(
                    controller: _jobController,
                    label: 'Job title',
                    hint: 'e.g. Backend Engineer',
                    prefixIcon: Icons.work_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  AppSpacing.gapMd,
                  AppTextField(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'e.g. Bangalore',
                    prefixIcon: Icons.location_on_outlined,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _search(),
                  ),
                  AppSpacing.gapMd,
                  PrimaryButton(
                    label: 'Search all platforms',
                    loadingLabel: 'Searching…',
                    onPressed: _search,
                  ),
                ],
              ),
            ),

            if (_links != null && _links!.isNotEmpty) ...[
              AppSpacing.gapXl,
              Row(
                children: [
                  Expanded(child: Text('Explore platforms', style: context.text.titleLarge)),
                  Text(
                    '${_links!.length} platforms',
                    style: context.text.labelLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _platformFilter('all', 'All platforms'),
                    for (final entry in _links!.entries)
                      _platformFilter(entry.key, _platformLabels[entry.key] ?? entry.key),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              ..._links!.entries
                  .where((entry) => _selectedPlatform == 'all' || entry.key == _selectedPlatform)
                  .map((entry) {
                final platform = _platformLabels[entry.key] ?? entry.key;
                final color = _platformColors[entry.key] ?? AppColors.jobRadar;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Text(
                                _platformInitials[entry.key] ?? platform.substring(0, 1),
                                style: context.text.titleMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: AppRadius.brPill,
                              ),
                              child: Text(
                                'SEARCH',
                                style: context.text.labelSmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapMd,
                        Text(jobTitle, style: context.text.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Matching roles on $platform',
                          style: context.text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        AppSpacing.gapMd,
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textTertiary),
                            AppSpacing.wGapXs,
                            Expanded(
                              child: Text(
                                locationText,
                                style: context.text.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 18, color: AppColors.textTertiary),
                            AppSpacing.wGapXs,
                            Text(
                              'Salary varies by listing',
                              style: context.text.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        AppSpacing.gapMd,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openPlatform(entry.value),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: Text('View jobs on $platform'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              AppSpacing.gapXl,
              const SectionHeading(
                title: 'Explore platforms',
                subtitle: 'Search LinkedIn, Indeed, Naukri, and 5 more platforms together.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get jobTitle => _jobController.text.trim();

  String get locationText => _locationController.text.trim().isEmpty
      ? 'India'
      : _locationController.text.trim();

  Widget _platformFilter(String key, String label) {
    final selected = _selectedPlatform == key;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedPlatform = key),
        showCheckmark: false,
        selectedColor: AppColors.primarySurface,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/session_controller.dart';
import '../main.dart';
import '../models/saved_job_models.dart';
import '../widgets/auth/app_text_field.dart';
import '../widgets/common_widgets.dart' show showErrorSnackBar;
import '../widgets/ui_kit.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  List<SavedJob>? _jobs;
  bool _loading = true;
  String? _selectedStatus; // null for All

  static const _statusOptions = [
    'saved',
    'applied',
    'interviewing',
    'offered',
    'rejected',
    'archived',
  ];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final token = SessionScope.of(context).token;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final jobs = await apiClient.getSavedJobs(token: token, status: _selectedStatus);
      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'offered':
        return AppColors.success;
      case 'interviewing':
        return AppColors.primary;
      case 'applied':
        return AppColors.careerMatch;
      case 'saved':
        return AppColors.jobRadar;
      case 'rejected':
        return AppColors.error;
      case 'archived':
      default:
        return AppColors.textTertiary;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'offered':
        return AppColors.successSurface;
      case 'interviewing':
        return AppColors.primarySurface;
      case 'applied':
        return AppColors.careerMatchSurface;
      case 'saved':
        return AppColors.jobRadarSurface;
      case 'rejected':
        return AppColors.errorSurface;
      case 'archived':
      default:
        return AppColors.surfaceAlt;
    }
  }

  Future<void> _showAddOrEditDialog([SavedJob? existing]) async {
    final token = SessionScope.of(context).token;
    if (token == null) return;

    final titleController = TextEditingController(text: existing?.title ?? '');
    final companyController = TextEditingController(text: existing?.company ?? '');
    final locationController = TextEditingController(text: existing?.location ?? '');
    final sourceController = TextEditingController(text: existing?.source ?? '');
    final urlController = TextEditingController(text: existing?.jobUrl ?? '');
    final salaryController = TextEditingController(text: existing?.salary ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String currentStatus = existing?.status ?? 'saved';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Text(
                  existing == null ? 'Add Job to Pipeline' : 'Edit Job Opportunity',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                AppSpacing.gapLg,
                AppTextField(
                  controller: titleController,
                  label: 'Job Title *',
                  hint: 'e.g. Senior Software Engineer',
                  prefixIcon: Icons.work_outline_rounded,
                ),
                AppSpacing.gapMd,
                AppTextField(
                  controller: companyController,
                  label: 'Company',
                  hint: 'e.g. Google, Stripe',
                  prefixIcon: Icons.business_rounded,
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: locationController,
                        label: 'Location',
                        hint: 'e.g. Remote / Bangalore',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                    ),
                    AppSpacing.wGapMd,
                    Expanded(
                      child: AppTextField(
                        controller: salaryController,
                        label: 'Salary',
                        hint: 'e.g. ₹20-25 LPA',
                        prefixIcon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: sourceController,
                        label: 'Source',
                        hint: 'e.g. LinkedIn, Referral',
                        prefixIcon: Icons.tag_rounded,
                      ),
                    ),
                    AppSpacing.wGapMd,
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: currentStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _statusOptions
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s[0].toUpperCase() + s.substring(1)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => currentStatus = v);
                        },
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                AppTextField(
                  controller: urlController,
                  label: 'Job Listing URL',
                  hint: 'https://...',
                  prefixIcon: Icons.link_rounded,
                ),
                AppSpacing.gapMd,
                AppTextField(
                  controller: notesController,
                  maxLines: 3,
                  label: 'Notes / Referrals',
                  hint: 'Referral details, interview schedule, questions to ask…',
                ),
                AppSpacing.gapLg,
                PrimaryButton(
                  label: existing == null ? 'Save Opportunity' : 'Update Details',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      showErrorSnackBar(sheetContext, 'Job title is required.');
                      return;
                    }
                    Navigator.of(sheetContext).pop();
                    try {
                      if (existing == null) {
                        await apiClient.saveJob(
                          token: token,
                          title: title,
                          company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
                          location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                          source: sourceController.text.trim().isEmpty ? null : sourceController.text.trim(),
                          jobUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                          salary: salaryController.text.trim().isEmpty ? null : salaryController.text.trim(),
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          status: currentStatus,
                        );
                      } else {
                        await apiClient.updateSavedJob(
                          token: token,
                          jobId: existing.id,
                          title: title,
                          company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
                          location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                          source: sourceController.text.trim().isEmpty ? null : sourceController.text.trim(),
                          jobUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                          salary: salaryController.text.trim().isEmpty ? null : salaryController.text.trim(),
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          status: currentStatus,
                        );
                      }
                      await _loadJobs();
                    } catch (e) {
                      if (mounted) showErrorSnackBar(this.context, e);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteJob(SavedJob job) async {
    final token = SessionScope.of(context).token;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Pipeline?'),
        content: Text('Are you sure you want to remove "${job.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiClient.deleteSavedJob(token: token, jobId: job.id);
      await _loadJobs();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        actions: [
          IconButton(
            tooltip: 'Add Opportunity',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddOrEditDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadJobs,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const GradientHeader(
                fullRadius: true,
                greeting: 'Career Pipeline',
                headline: 'Track your opportunities\nand applications.',
                subline: 'Bookmark roles from JobRadar or enter direct referrals to manage your hiring pipeline.',
              ),
              AppSpacing.gapLg,

              // Status Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (_) {
                        setState(() => _selectedStatus = null);
                        _loadJobs();
                      },
                    ),
                    ..._statusOptions.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(status[0].toUpperCase() + status.substring(1)),
                          selected: _selectedStatus == status,
                          onSelected: (_) {
                            setState(() => _selectedStatus = status);
                            _loadJobs();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              // Main Content
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_jobs == null || _jobs!.isEmpty)
                EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: _selectedStatus == null ? 'No saved jobs yet' : 'No jobs in "$_selectedStatus"',
                  message: 'Keep track of target positions by bookmarking them here or adding referrals.',
                  actionLabel: 'Add Opportunity',
                  onAction: () => _showAddOrEditDialog(),
                )
              else
                ..._jobs!.map((job) => _buildJobCard(job)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Job'),
      ),
    );
  }

  Widget _buildJobCard(SavedJob job) {
    final statusFg = _statusColor(job.status);
    final statusBg = _statusBackground(job.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconWell(
                  icon: Icons.business_center_rounded,
                  color: statusFg,
                  background: statusBg,
                  size: 44,
                ),
                AppSpacing.wGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (job.company != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          job.company!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: statusFg.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    job.status[0].toUpperCase() + job.status.substring(1),
                    style: TextStyle(color: statusFg, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (job.location != null || job.salary != null || job.source != null) ...[
              AppSpacing.gapMd,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (job.location != null)
                    _pill(Icons.location_on_outlined, job.location!),
                  if (job.salary != null)
                    _pill(Icons.payments_outlined, job.salary!),
                  if (job.source != null)
                    _pill(Icons.tag_rounded, job.source!),
                ],
              ),
            ],
            if (job.notes != null && job.notes!.isNotEmpty) ...[
              AppSpacing.gapMd,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  job.notes!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                ),
              ),
            ],
            AppSpacing.gapMd,
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (job.jobUrl != null && job.jobUrl!.isNotEmpty)
                  IconButton(
                    tooltip: 'Open Link',
                    icon: const Icon(Icons.open_in_new_rounded, size: 20, color: AppColors.primary),
                    onPressed: () => launchUrl(Uri.parse(job.jobUrl!), mode: LaunchMode.externalApplication),
                  ),
                IconButton(
                  tooltip: 'Edit Job',
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                  onPressed: () => _showAddOrEditDialog(job),
                ),
                IconButton(
                  tooltip: 'Delete Job',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                  onPressed: () => _deleteJob(job),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

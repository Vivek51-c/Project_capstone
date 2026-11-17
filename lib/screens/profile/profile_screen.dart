import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../../core/auth/session_controller.dart';
import '../../core/profile/profile_models.dart';
import '../../core/resume_download.dart';
import '../../main.dart';
import '../../models/ats_models.dart';
import '../../models/resume_builder_models.dart';
import '../../widgets/ui_kit.dart';
import 'edit_profile_screen.dart';
import '../resume_builder_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileData? _profile;
  List<SavedResumeVersion> _versions = [];
  List<SavedAtsAnalysis> _atsAnalyses = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = SessionScope.of(context);
    final token = session.token;
    if (token == null) return; // AuthGate handles routing away in this case

    try {
      final profile = await apiClient.getProfile(token: token);
      final versions = await apiClient.getResumeVersions(token: token);
      final atsAnalyses = await apiClient.getSavedAtsAnalyses(token: token);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _versions = versions;
        _atsAnalyses = atsAnalyses;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token expired/revoked (e.g. password changed elsewhere) --
        // AuthGate swaps to LoginScreen as soon as the session updates.
        await session.forceSignOut();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            "You'll need to log in again to access your saved data."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await SessionScope.of(context).logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _openEdit() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(initialProfile: profile)),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  Future<void> _openResumeBuilder() async {
    final token = SessionScope.of(context).token;
    if (token == null) return;
    ResumeBuilderFormState? form;
    if (_versions.isNotEmpty) {
      try {
        form = (await apiClient.getResumeVersion(
          token: token,
          versionId: _versions.first.id,
        ))
            .form;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load the saved resume: $e')),
        );
        return;
      }
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ResumeBuilderScreen(initialForm: form)),
    );
    if (mounted) await _load();
  }

  Future<void> _downloadResume(SavedResumeVersion version) async {
    final token = SessionScope.of(context).token;
    if (token == null) return;
    try {
      final (bytes, filename) = await apiClient.downloadResumeVersion(
        token: token,
        versionId: version.id,
      );
      final path = await saveResumeDownload(bytes, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(path == null ? 'Downloading $filename' : 'Saved $filename'),
          action: path == null
              ? null
              : SnackBarAction(
                  label: 'Open', onPressed: () => OpenFilex.open(path)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download the resume: $e')),
        );
      }
    }
  }

  Future<void> _deleteResume(SavedResumeVersion version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resume version?'),
        content:
            const Text('Are you sure you want to delete this resume version?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = SessionScope.of(context).token;
    if (token == null) return;
    try {
      await apiClient.deleteResumeVersion(token: token, versionId: version.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Version ${version.version} deleted.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete the resume version: $e')),
        );
      }
    }
  }

  Future<void> _openAtsTuneUp() async {
    await Navigator.pushNamed(context, '/ats-tuneup');
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth > 920 ? 920 : constraints.maxWidth,
                child: _buildBody(context, session),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SessionController session) {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          SkeletonBox(height: 96, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.md),
          SkeletonList(itemCount: 4, itemHeight: 64),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [ErrorStateView(error: _error!, onRetry: _load)],
      );
    }

    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
      children: [
        _ProfileHeaderCard(profile: profile, onEdit: _openEdit),
        AppSpacing.gapLg,
        _ResumeManagementCard(
          versions: _versions,
          onUpdate: _openResumeBuilder,
          onDownload: _downloadResume,
          onDelete: _deleteResume,
        ),
        AppSpacing.gapMd,
        _AtsHistoryCard(
          analyses: _atsAnalyses,
          versions: _versions,
          onAnalyze: _openAtsTuneUp,
        ),
        AppSpacing.gapMd,
        PremiumCard(
          onTap: () => Navigator.pushNamed(context, '/saved-jobs'),
          child: Row(
            children: [
              const IconWell(
                icon: Icons.bookmark_outline_rounded,
                color: AppColors.primary,
                background: AppColors.primarySurface,
              ),
              AppSpacing.wGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved Jobs', style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text('View and track your saved job postings',
                        style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
        AppSpacing.gapXl,
        SecondaryButton(
          label: 'Log out',
          icon: Icons.logout_rounded,
          onPressed: _confirmLogout,
        ),
        AppSpacing.gapLg,
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final ProfileData profile;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final initial = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()[0].toUpperCase()
        : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        initial,
                        style: context.text.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppSpacing.wGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.email,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final completion = Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Profile completion',
                                  style: context.text.titleSmall),
                              AppSpacing.gapXs,
                              ClipRRect(
                                borderRadius: AppRadius.brPill,
                                child: LinearProgressIndicator(
                                  value: profile.completionRatio,
                                  minHeight: 7,
                                  backgroundColor: AppColors.surfaceAlt,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.wGapSm,
                        Text('${(profile.completionRatio * 100).round()}%',
                            style: context.text.titleSmall
                                ?.copyWith(color: AppColors.primary)),
                      ],
                    );
                    final editButton = OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit profile'),
                    );
                    if (constraints.maxWidth < 420) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          completion,
                          AppSpacing.gapSm,
                          Align(
                            alignment: Alignment.centerRight,
                            child: editButton,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: completion),
                        AppSpacing.wGapMd,
                        editButton,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumeManagementCard extends StatelessWidget {
  final List<SavedResumeVersion> versions;
  final VoidCallback onUpdate;
  final ValueChanged<SavedResumeVersion> onDownload;
  final ValueChanged<SavedResumeVersion> onDelete;

  const _ResumeManagementCard({
    required this.versions,
    required this.onUpdate,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final latest = versions.isEmpty ? null : versions.first;
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconWell(
                icon: Icons.description_outlined,
                color: AppColors.resumeBuilder,
                background: AppColors.resumeBuilderSurface,
              ),
              AppSpacing.wGapSm,
              Expanded(
                  child: Text('My Resume', style: context.text.titleMedium)),
              if (latest != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text('v${latest.version}',
                      style: context.text.labelMedium
                          ?.copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          AppSpacing.gapMd,
          if (latest == null) ...[
            Text('No saved resume yet.', style: context.text.bodyMedium),
            AppSpacing.gapMd,
            FilledButton.icon(
              onPressed: onUpdate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Resume'),
            ),
          ] else ...[
            Text(
              latest.filename,
              style: context.text.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.gapXs,
            Text('Last updated ${_formatDate(latest.createdAt)}',
                style: context.text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: onUpdate,
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Update Resume'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onDownload(latest),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download Resume'),
                ),
                IconButton(
                  tooltip: 'Delete version ${latest.version}',
                  onPressed: () => onDelete(latest),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                ),
              ],
            ),
            if (versions.length > 1) ...[
              AppSpacing.gapMd,
              const Divider(height: 1),
              AppSpacing.gapXs,
              Text('Version history', style: context.text.titleSmall),
              for (final version in versions.skip(1))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded),
                  title: Text('Version ${version.version}'),
                  subtitle: Text(
                    '${version.filename} · ${_formatDate(version.createdAt)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Download version ${version.version}',
                        onPressed: () => onDownload(version),
                        icon: const Icon(Icons.download_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete version ${version.version}',
                        onPressed: () => onDelete(version),
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AtsHistoryCard extends StatelessWidget {
  final List<SavedAtsAnalysis> analyses;
  final List<SavedResumeVersion> versions;
  final VoidCallback onAnalyze;

  const _AtsHistoryCard({
    required this.analyses,
    required this.versions,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final labels = {
      for (final version in versions) version.id: version.version
    };
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconWell(
                icon: Icons.fact_check_outlined,
                color: AppColors.atsTuneUp,
                background: AppColors.atsTuneUpSurface,
              ),
              AppSpacing.wGapSm,
              Expanded(
                  child: Text('ATS Analysis', style: context.text.titleMedium)),
              IconButton(
                tooltip: 'Analyze a saved resume',
                onPressed: onAnalyze,
                icon: const Icon(Icons.add_chart_rounded),
              ),
            ],
          ),
          AppSpacing.gapSm,
          if (analyses.isEmpty)
            Text('No saved ATS results yet.',
                style: context.text.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
          else
            for (final result in analyses)
              _AtsResultRow(
                result: result,
                versionNumber: labels[result.resumeVersionId],
              ),
        ],
      ),
    );
  }
}

class _AtsResultRow extends StatelessWidget {
  final SavedAtsAnalysis result;
  final int? versionNumber;

  const _AtsResultRow({required this.result, required this.versionNumber});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (result.score ?? 0) >= 70
            ? AppColors.successSurface
            : AppColors.warningSurface,
        child: Text(result.score?.toString() ?? '—',
            style: context.text.labelLarge),
      ),
      title: Text(
          'Version ${versionNumber ?? '—'} · ${result.mode == 'ai' ? 'AI analysis' : 'Local checks'}'),
      subtitle: Text(_formatDate(result.createdAt)),
      trailing: TextButton(
        onPressed: () => _showAnalysis(context, result),
        child: const Text('View ATS Analysis'),
      ),
    );
  }
}

void _showAnalysis(BuildContext context, SavedAtsAnalysis result) {
  final analysis = result.analysis;
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('ATS score ${result.score?.toString() ?? 'Not scored'}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: result.mode == 'local'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step
                        in analysis['steps'] as List? ?? const []) ...[
                      Text(step['title'] as String? ?? 'Check',
                          style: Theme.of(context).textTheme.titleSmall),
                      for (final finding
                          in step['findings'] as List? ?? const [])
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            finding['level'] == 'success'
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: finding['level'] == 'success'
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          title: Text(finding['message'] as String? ?? ''),
                        ),
                    ],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry
                        in (analysis['categories'] as Map<String, dynamic>? ??
                                {})
                            .entries) ...[
                      Text(entry.key,
                          style: Theme.of(context).textTheme.titleSmall),
                      for (final note
                          in entry.value['positives'] as List? ?? const [])
                        ListTile(
                            dense: true,
                            leading: const Icon(Icons.check,
                                color: AppColors.success),
                            title: Text(note.toString())),
                      for (final note
                          in entry.value['negatives'] as List? ?? const [])
                        ListTile(
                            dense: true,
                            leading: const Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning),
                            title: Text(note.toString())),
                    ],
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Close'))
      ],
    ),
  );
}

String _formatDate(DateTime value) {
  final date = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

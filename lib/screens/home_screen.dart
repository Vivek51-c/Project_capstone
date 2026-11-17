import 'package:flutter/material.dart';

import '../core/auth/session_controller.dart';
import '../core/local_history.dart';
import '../widgets/ui_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HistorySnapshot? _history;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Prevent concurrent loads triggered by rapid _go() returns.
    if (_loadingHistory) return;
    _loadingHistory = true;
    try {
      final snapshot = await LocalHistory.instance.load();
      if (mounted) setState(() => _history = snapshot);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  /// Navigates then refreshes the dashboard on return, so real numbers the
  /// user just produced (an ATS score, a match %, a skill gap) show up
  /// immediately without a manual refresh.
  Future<void> _go(String route) async {
    await Navigator.pushNamed(context, route);
    _load();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Real, locally-cached metric for a feature's card — never a placeholder.
  /// Returns null (badge omitted) when the user hasn't run that tool.
  String? _metricFor(AppFeature feature, HistorySnapshot h) {
    switch (feature) {
      case AppFeature.atsTuneUp:
        return h.toolsUsed.contains('atsTuneUp') ? 'Checked' : null;
      case AppFeature.jobMatcher:
        return h.jobMatchScore == null ? null : 'Last ${h.jobMatchScore}%';
      case AppFeature.careerMatch:
        return h.topRole == null ? null : 'Explored';
      case AppFeature.skillBridge:
        return h.gapRole == null ? null : '${h.gapMatched}/${h.gapRequired} skills';
      case AppFeature.resumeBuilder:
        return h.toolsUsed.contains('resumeBuilder') ? 'Used' : null;
      case AppFeature.jobRadar:
        return h.lastJobQuery == null ? null : 'Recent search';
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final sessionUser = SessionScope.of(context).user;
    final initial =
        (sessionUser?.fullName.trim().isNotEmpty ?? false) ? sessionUser!.fullName.trim()[0].toUpperCase() : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppWordmark(),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Saved Jobs',
            onPressed: () => _go('/saved-jobs'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _ProfileAvatarButton(
              initial: initial,
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: history == null
              ? _LoadingSkeleton()
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  children: [
                    ResponsiveBody(
                      child: StaggeredColumn(
                        children: [
                          AppSpacing.gapXs,
                          _buildHero(history),
                          AppSpacing.gapXl,
                          _buildSnapshotSection(context, history),
                          AppSpacing.gapXl,
                          const SectionHeading(title: 'Quick Actions'),
                          _buildQuickActions(),
                          if (history.derivedInsight != null) ...[
                            AppSpacing.gapXl,
                            _buildInsight(history),
                          ],
                          if (history.lastJobQuery != null) ...[
                            AppSpacing.gapXl,
                            _buildContinueSearch(history),
                          ],
                          AppSpacing.gapXl,
                          const SectionHeading(
                            title: 'Career Tools',
                            subtitle: 'Everything you need, in one place',
                          ),
                          ..._buildToolCards(history),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---- sections -----------------------------------------------------

  Widget _buildHero(HistorySnapshot history) {
    return GradientHeader(
      fullRadius: true,
      greeting: '${_greeting()} 👋',
      headline: 'Your career,\nsmarter with AI.',
      subline: 'Discover jobs, sharpen your resume, and close the skill gaps that matter.',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.brPill,
                  child: LinearProgressIndicator(
                    value: history.toolkitProgress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              AppSpacing.wGapSm,
              Text(
                '${history.toolsUsedCount}/6 tools tried',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotSection(BuildContext context, HistorySnapshot history) {
    if (history.isEmpty) {
      return PremiumCard(
        padding: AppSpacing.cardLarge,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No checks run yet', style: context.text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Run ATS TuneUp or JobMatcher to see your scores here.',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            AppSpacing.wGapSm,
            SecondaryButton(
              label: 'Start',
              icon: Icons.arrow_forward_rounded,
              expand: false,
              onPressed: () => _go(AppFeature.atsTuneUp.route),
            ),
          ],
        ),
      );
    }

    // Build up to 2 stat cards, in priority order, using whatever the user
    // has actually produced. No placeholders — a metric only appears here
    // once its tool has actually been run.
    final cards = <Widget>[];

    if (history.jobMatchScore != null) {
      cards.add(StatCard(
        label: 'Job Match',
        value: '${history.jobMatchScore}%',
        caption: HistorySnapshot.relativeTime(history.jobMatchAt),
        icon: Icons.join_inner_rounded,
        accent: AppColors.jobMatcher,
        accentSurface: AppColors.jobMatcherSurface,
        onTap: () => _go(AppFeature.jobMatcher.route),
      ));
    }
    if (cards.length < 2 && history.gapRole != null && (history.gapRequired ?? 0) > 0) {
      final coverage = (((history.gapMatched ?? 0) / history.gapRequired!) * 100).round();
      cards.add(StatCard(
        label: 'Skill Coverage',
        value: '$coverage%',
        caption: history.gapRole!,
        icon: Icons.insights_rounded,
        accent: AppColors.skillBridge,
        accentSurface: AppColors.skillBridgeSurface,
        onTap: () => _go(AppFeature.skillBridge.route),
      ));
    }
    // Covers the case where only CareerMatch has been run so far.
    if (cards.isEmpty && history.topRole != null) {
      cards.add(StatCard(
        label: 'Top Role Match',
        value: '${history.topRoleSkillCount ?? 0} skills',
        caption: history.topRole!,
        icon: Icons.auto_awesome_rounded,
        accent: AppColors.careerMatch,
        accentSurface: AppColors.careerMatchSurface,
        onTap: () => _go(AppFeature.careerMatch.route),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(title: 'Your Career Snapshot'),
        Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) AppSpacing.wGapSm,
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = [
          (AppFeature.jobMatcher, 'Analyze Resume', Icons.fact_check_outlined),
          (AppFeature.resumeBuilder, 'Build Resume', Icons.edit_document),
          (AppFeature.atsTuneUp, 'Check ATS', Icons.verified_outlined),
          (AppFeature.jobRadar, 'Find Jobs', Icons.travel_explore_outlined),
        ];
        // Responsive aspect ratio: smaller phones need a slightly taller cell
        // so the label doesn't overflow; wider screens can stay compact.
        final double aspectRatio = constraints.maxWidth < AppBreakpoints.compact
            ? 2.2
            : constraints.maxWidth >= AppBreakpoints.medium
                ? 3.0
                : 2.6;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: aspectRatio,
          children: actions
              .map((a) => QuickActionCard(
                    label: a.$2,
                    icon: a.$3,
                    accent: a.$1.accent,
                    accentSurface: a.$1.accentSurface,
                    onTap: () => _go(a.$1.route),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildInsight(HistorySnapshot history) {
    final targetRoute =
        history.gapRole != null ? AppFeature.skillBridge.route : AppFeature.careerMatch.route;
    return InfoBanner(
      icon: Icons.auto_awesome_rounded,
      accent: AppColors.secondary,
      background: AppColors.secondarySurface,
      message: history.derivedInsight!,
      actionLabel: history.gapRole != null ? 'View Skill Gap' : 'Explore Careers',
      onAction: () => _go(targetRoute),
    );
  }

  Widget _buildContinueSearch(HistorySnapshot history) {
    final job = history.lastJobQuery!['job'] ?? '';
    final location = history.lastJobQuery!['location'] ?? '';
    return PremiumCard(
      onTap: () => _go(AppFeature.jobRadar.route),
      child: Row(
        children: [
          const IconWell(
            icon: Icons.history_rounded,
            color: AppColors.jobRadar,
            background: AppColors.jobRadarSurface,
          ),
          AppSpacing.wGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue your search', style: context.text.titleSmall?.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '$job · $location',
                  style: context.text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  List<Widget> _buildToolCards(HistorySnapshot history) {
    return [
      for (final feature in AppFeature.values) ...[
        FeatureCard(
          feature: feature,
          metricLabel: _metricFor(feature, history),
          onTap: () => _go(feature.route),
        ),
        if (feature != AppFeature.values.last) AppSpacing.gapSm,
      ],
    ];
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapMd,
            SkeletonBox(height: 168, radius: AppRadius.xl),
            AppSpacing.gapXl,
            SkeletonList(itemCount: 2, itemHeight: 96),
            AppSpacing.gapXl,
            SkeletonList(itemCount: 6, itemHeight: 78),
          ],
        ),
      ),
    );
  }
}

/// Small avatar/account entry point in the AppBar -> Profile screen.
class _ProfileAvatarButton extends StatelessWidget {
  final String? initial;
  final VoidCallback onTap;

  const _ProfileAvatarButton({required this.initial, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brPill,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primarySurface,
        child: initial != null
            ? Text(
                initial!,
                style: context.text.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              )
            : const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
      ),
    );
  }
}

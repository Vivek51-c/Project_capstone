import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Locally-cached results of the user's last runs.
///
/// IMPORTANT (brief §31 — do not fabricate data): the backend has no auth,
/// no database, and no persistence. It cannot tell us "your ATS score is 82".
/// Everything in this store is a real value the user actually produced on
/// this device, recorded at the moment they ran the tool, and always shown
/// with its timestamp so it is never mistaken for a live figure.
///
/// If nothing has been run yet, the Home dashboard shows empty states rather
/// than placeholder numbers.
class LocalHistory {
  LocalHistory._();
  static final LocalHistory instance = LocalHistory._();

  static const _kAtsScore = 'history.ats.score';
  static const _kAtsAt = 'history.ats.at';
  static const _kAtsSource = 'history.ats.source'; // 'local' | 'ai'

  static const _kMatchScore = 'history.match.score';
  static const _kMatchAt = 'history.match.at';

  static const _kTopRole = 'history.career.topRole';
  static const _kTopRoleSkillCount = 'history.career.topRoleSkillCount';
  static const _kCareerAt = 'history.career.at';

  static const _kGapRole = 'history.gap.role';
  static const _kGapMatched = 'history.gap.matched';
  static const _kGapRequired = 'history.gap.required';
  static const _kGapMissingTop = 'history.gap.missingTop'; // JSON list
  static const _kGapAt = 'history.gap.at';

  static const _kToolsUsed = 'history.toolsUsed'; // JSON list of feature names
  static const _kLastJobQuery = 'history.jobRadar.lastQuery'; // JSON {job, location}

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async => _prefs ??= await SharedPreferences.getInstance();

  // ---- writes -----------------------------------------------------------

  Future<void> recordAtsScore(int score, {required String source}) async {
    final p = await _p;
    await p.setInt(_kAtsScore, score);
    await p.setString(_kAtsAt, DateTime.now().toIso8601String());
    await p.setString(_kAtsSource, source);
    await _markToolUsed('atsTuneUp');
  }

  Future<void> recordJobMatch(int score) async {
    final p = await _p;
    await p.setInt(_kMatchScore, score);
    await p.setString(_kMatchAt, DateTime.now().toIso8601String());
    await _markToolUsed('jobMatcher');
  }

  Future<void> recordCareerTopRole(String role, int matchedSkillCount) async {
    final p = await _p;
    await p.setString(_kTopRole, role);
    await p.setInt(_kTopRoleSkillCount, matchedSkillCount);
    await p.setString(_kCareerAt, DateTime.now().toIso8601String());
    await _markToolUsed('careerMatch');
  }

  Future<void> recordSkillGap({
    required String role,
    required int matched,
    required int required_,
    required List<String> missingTop,
  }) async {
    final p = await _p;
    await p.setString(_kGapRole, role);
    await p.setInt(_kGapMatched, matched);
    await p.setInt(_kGapRequired, required_);
    await p.setString(_kGapMissingTop, jsonEncode(missingTop.take(5).toList()));
    await p.setString(_kGapAt, DateTime.now().toIso8601String());
    await _markToolUsed('skillBridge');
  }

  Future<void> recordJobSearch(String job, String location) async {
    final p = await _p;
    await p.setString(_kLastJobQuery, jsonEncode({'job': job, 'location': location}));
    await _markToolUsed('jobRadar');
  }

  Future<void> recordResumeBuilt() async => _markToolUsed('resumeBuilder');

  Future<void> _markToolUsed(String feature) async {
    final p = await _p;
    final used = <String>{...await toolsUsed()};
    used.add(feature);
    await p.setString(_kToolsUsed, jsonEncode(used.toList()));
  }

  // ---- reads ------------------------------------------------------------

  Future<HistorySnapshot> load() async {
    final p = await _p;

    DateTime? parse(String? s) => s == null ? null : DateTime.tryParse(s);

    List<String> missingTop = const [];
    final rawMissing = p.getString(_kGapMissingTop);
    if (rawMissing != null) {
      try {
        missingTop = List<String>.from(jsonDecode(rawMissing) as List);
      } catch (_) {/* corrupt entry; ignore */}
    }

    Map<String, String>? lastQuery;
    final rawQuery = p.getString(_kLastJobQuery);
    if (rawQuery != null) {
      try {
        final m = jsonDecode(rawQuery) as Map<String, dynamic>;
        lastQuery = {'job': m['job'].toString(), 'location': m['location'].toString()};
      } catch (_) {/* ignore */}
    }

    // Read toolsUsed from the same prefs instance we already have — avoids
    // a redundant second await on _p inside toolsUsed().
    List<String> usedTools = const [];
    final rawTools = p.getString(_kToolsUsed);
    if (rawTools != null) {
      try {
        usedTools = List<String>.from(jsonDecode(rawTools) as List);
      } catch (_) {/* ignore */}
    }

    return HistorySnapshot(
      atsScore: p.getInt(_kAtsScore),
      atsAt: parse(p.getString(_kAtsAt)),
      atsSource: p.getString(_kAtsSource),
      jobMatchScore: p.getInt(_kMatchScore),
      jobMatchAt: parse(p.getString(_kMatchAt)),
      topRole: p.getString(_kTopRole),
      topRoleSkillCount: p.getInt(_kTopRoleSkillCount),
      careerAt: parse(p.getString(_kCareerAt)),
      gapRole: p.getString(_kGapRole),
      gapMatched: p.getInt(_kGapMatched),
      gapRequired: p.getInt(_kGapRequired),
      gapMissingTop: missingTop,
      gapAt: parse(p.getString(_kGapAt)),
      toolsUsed: usedTools,
      lastJobQuery: lastQuery,
    );
  }

  Future<List<String>> toolsUsed() async {
    final p = await _p;
    final raw = p.getString(_kToolsUsed);
    if (raw == null) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearAll() async {
    final p = await _p;
    for (final k in [
      _kAtsScore, _kAtsAt, _kAtsSource,
      _kMatchScore, _kMatchAt,
      _kTopRole, _kTopRoleSkillCount, _kCareerAt,
      _kGapRole, _kGapMatched, _kGapRequired, _kGapMissingTop, _kGapAt,
      _kToolsUsed, _kLastJobQuery,
    ]) {
      await p.remove(k);
    }
  }
}

class HistorySnapshot {
  final int? atsScore;
  final DateTime? atsAt;
  final String? atsSource;

  final int? jobMatchScore;
  final DateTime? jobMatchAt;

  final String? topRole;
  final int? topRoleSkillCount;
  final DateTime? careerAt;

  final String? gapRole;
  final int? gapMatched;
  final int? gapRequired;
  final List<String> gapMissingTop;
  final DateTime? gapAt;

  final List<String> toolsUsed;
  final Map<String, String>? lastJobQuery;

  const HistorySnapshot({
    this.atsScore,
    this.atsAt,
    this.atsSource,
    this.jobMatchScore,
    this.jobMatchAt,
    this.topRole,
    this.topRoleSkillCount,
    this.careerAt,
    this.gapRole,
    this.gapMatched,
    this.gapRequired,
    this.gapMissingTop = const [],
    this.gapAt,
    this.toolsUsed = const [],
    this.lastJobQuery,
  });

  bool get isEmpty => jobMatchScore == null && topRole == null && gapRole == null;

  /// Real progress metric: how many of the 6 tools the user has actually run.
  /// Replaces the brief's "profile completion 78%", which has no data source.
  int get toolsUsedCount => toolsUsed.length;
  double get toolkitProgress => toolsUsedCount / 6;

  /// Derived insight built strictly from cached real values. Returns null
  /// when there isn't enough real data to say anything true.
  String? get derivedInsight {
    if (topRole != null && gapRole != null && gapMissingTop.isNotEmpty) {
      return 'Your resume lines up best with $topRole. To close the gap for '
          '$gapRole, focus on ${gapMissingTop.take(2).join(" and ")}.';
    }
    if (topRole != null) {
      return 'Your strongest role match so far is $topRole. '
          'Run SkillBridge to see exactly which skills to build next.';
    }
    if (atsScore != null) {
      return atsScore! >= 80
          ? 'Your resume scored $atsScore on its last ATS check — that is a strong base. '
              'Try JobMatcher against a real posting next.'
          : 'Your resume scored $atsScore on its last ATS check. '
              'ATS TuneUp lists the specific fixes that will raise it.';
    }
    return null;
  }

  static String relativeTime(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

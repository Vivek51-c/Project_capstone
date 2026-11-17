import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../models/job_matcher_models.dart';
import '../models/career_match_models.dart';
import '../models/skill_bridge_models.dart';
import '../models/ats_models.dart';
import '../models/resume_builder_models.dart';
import '../models/saved_job_models.dart';
import 'auth/auth_models.dart';
import 'profile/profile_models.dart';

/// A file picked on-device, kept as raw bytes so this works identically on
/// mobile, desktop, and web (no reliance on a filesystem File/path).
class PickedFile {
  final String filename;
  final Uint8List bytes;
  final String? contentType; // e.g. "application/pdf"

  PickedFile({required this.filename, required this.bytes, this.contentType});
}

class ApiClient {
  final String? _customBaseUrl;
  final Duration? _customTimeout;
  final http.Client _client;

  ApiClient({String? baseUrl, Duration? timeout, http.Client? client})
      : _customBaseUrl = baseUrl,
        _customTimeout = timeout,
        _client = _TimeoutClient(client ?? http.Client(), () => timeout ?? kApiTimeout);

  String get baseUrl => _customBaseUrl ?? kApiBaseUrl;
  Duration get timeout => _customTimeout ?? kApiTimeout;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    Map<String, String>? cleanQuery;
    if (query != null) {
      cleanQuery = {};
      for (final entry in query.entries) {
        if (entry.value != null) cleanQuery[entry.key] = entry.value.toString();
      }
    }
    final rawUrl = '$baseUrl$path';
    Uri parsed = Uri.parse(rawUrl);
    if (kIsWeb && !parsed.hasScheme) {
      parsed = Uri.base.resolveUri(parsed);
    }
    return parsed.replace(queryParameters: cleanQuery);
  }

  Future<dynamic> _decodeOrThrow(http.BaseResponse response,
      {List<int>? bodyBytesOverride}) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    String message = 'Request failed (${response.statusCode})';
    try {
      final bodyString = response is http.Response
          ? response.body
          : utf8.decode(bodyBytesOverride ?? const []);
      final decoded = jsonDecode(bodyString);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {
      // Non-JSON error body; keep the generic message.
    }
    throw ApiException(response.statusCode, message);
  }

  http.MultipartFile _toMultipartFile(String field, PickedFile file) {
    return http.MultipartFile.fromBytes(field, file.bytes,
        filename: file.filename);
  }

  Map<String, String> _jsonHeaders({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  Future<AuthResult> signup({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async {
    final res = await _client.post(
      _uri('/auth/signup'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'accepted_terms': acceptedTerms,
      }),
    );
    await _decodeOrThrow(res);
    return AuthResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final res = await _client.post(
      _uri('/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode(
          {'email': email, 'password': password, 'remember_me': rememberMe}),
    );
    await _decodeOrThrow(res);
    return AuthResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AuthUser> getMe({required String token}) async {
    final res = await _client.get(_uri('/auth/me'),
        headers: _jsonHeaders(token: token));
    await _decodeOrThrow(res);
    return AuthUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// The first value is always the generic "if an account exists…"
  /// message, safe to show verbatim for both known and unknown emails.
  /// `devResetLink` is populated ONLY when talking to a backend running
  /// outside production with no SMTP configured -- it must never be shown
  /// or relied upon in a production build (see ForgotPasswordScreen).
  Future<(String message, String? devResetLink)> forgotPassword(
      String email) async {
    final res = await _client.post(
      _uri('/auth/forgot-password'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    await _decodeOrThrow(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['message'] as String, json['dev_reset_link'] as String?);
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final res = await _client.post(
      _uri('/auth/reset-password'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'token': token,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      }),
    );
    await _decodeOrThrow(res);
    return (jsonDecode(res.body) as Map<String, dynamic>)['message'] as String;
  }

  /// Returns a fresh AuthResult: the backend invalidates every token
  /// issued before this call (see backend AUTH_SETUP.md), so the caller
  /// must replace its stored token with the new one from this response.
  Future<AuthResult> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final res = await _client.post(
      _uri('/auth/change-password'),
      headers: _jsonHeaders(token: token),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      }),
    );
    await _decodeOrThrow(res);
    return AuthResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Server-side, this only confirms the token was valid -- actual logout
  /// (discarding the token) happens client-side. See SessionController.logout.
  Future<void> logout({required String token}) async {
    final res = await _client.post(_uri('/auth/logout'),
        headers: _jsonHeaders(token: token));
    await _decodeOrThrow(res);
  }

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  Future<ProfileData> getProfile({required String token}) async {
    final res = await _client.get(_uri('/profile'),
        headers: _jsonHeaders(token: token));
    await _decodeOrThrow(res);
    return ProfileData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ProfileData> updateProfile(
      {required String token, required ProfileUpdate update}) async {
    final res = await _client.put(
      _uri('/profile'),
      headers: _jsonHeaders(token: token),
      body: jsonEncode(update.toJson()),
    );
    await _decodeOrThrow(res);
    return ProfileData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // JobRadar
  // ---------------------------------------------------------------------

  Future<Map<String, String>> getJobSearchLinks(
      {required String job, required String location}) async {
    final res = await _client.get(
        _uri('/job-radar/search-links', {'job': job, 'location': location}));
    await _decodeOrThrow(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(k, v.toString()));
  }

  // ---------------------------------------------------------------------
  // JobMatcher
  // ---------------------------------------------------------------------

  Future<JobMatchResult> analyzeJobMatch({
    required PickedFile resume,
    PickedFile? jdFile,
    String? jdText,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/job-matcher/analyze'))
      ..files.add(_toMultipartFile('resume', resume));
    if (jdFile != null) {
      request.files.add(_toMultipartFile('jd_file', jdFile));
    } else if (jdText != null && jdText.isNotEmpty) {
      request.fields['jd_text'] = jdText;
    } else {
      throw ApiException(
          400, 'Provide either a job description file or pasted text.');
    }

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    await _decodeOrThrow(res);
    return JobMatchResult.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // CareerMatch
  // ---------------------------------------------------------------------

  Future<CareerMatchResult> analyzeCareerMatch(
      {required PickedFile resume, int topN = 5}) async {
    final request = http.MultipartRequest(
        'POST', _uri('/career-match/analyze', {'top_n': topN}))
      ..files.add(_toMultipartFile('resume', resume));

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    await _decodeOrThrow(res);
    return CareerMatchResult.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // SkillBridge
  // ---------------------------------------------------------------------

  Future<List<String>> getSkillBridgeRoles() async {
    final res = await _client.get(_uri('/skill-bridge/roles'));
    await _decodeOrThrow(res);
    return List<String>.from(jsonDecode(res.body) as List);
  }

  Future<SkillBridgeResult> analyzeSkillGap(
      {required PickedFile resume, required String role}) async {
    final request = http.MultipartRequest('POST', _uri('/skill-bridge/analyze'))
      ..fields['role'] = role
      ..files.add(_toMultipartFile('resume', resume));

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    await _decodeOrThrow(res);
    return SkillBridgeResult.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<LearningResourceLinks> getLearningResources(String skill) async {
    final res =
        await _client.get(_uri('/skill-bridge/resources', {'skill': skill}));
    await _decodeOrThrow(res);
    return LearningResourceLinks.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // ATS TuneUp
  // ---------------------------------------------------------------------

  Future<LocalAtsResult> runLocalAts({required PickedFile resume}) async {
    final request = http.MultipartRequest('POST', _uri('/ats/local'))
      ..files.add(_toMultipartFile('resume', resume));

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    await _decodeOrThrow(res);
    return LocalAtsResult.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AiAtsResult> runAiAts(
      {required PickedFile resume, String? geminiApiKey}) async {
    final request = http.MultipartRequest('POST', _uri('/ats/ai'))
      ..files.add(_toMultipartFile('resume', resume));
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      request.fields['gemini_api_key'] = geminiApiKey;
    }

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    await _decodeOrThrow(res);
    return AiAtsResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // ResumeBuilder
  // ---------------------------------------------------------------------

  Future<ValidationResult> validateResume(ResumeBuilderFormState form) async {
    final res = await _client.post(
      _uri('/resume-builder/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(form.toJson()),
    );
    await _decodeOrThrow(res);
    return ValidationResult.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<SavedResumeVersion?> getLatestResume({required String token}) async {
    final res = await _client.get(
      _uri('/resume-builder/latest'),
      headers: _jsonHeaders(token: token),
    );
    await _decodeOrThrow(res);
    final json = jsonDecode(res.body);
    return json == null
        ? null
        : SavedResumeVersion.fromJson(json as Map<String, dynamic>);
  }

  Future<List<SavedResumeVersion>> getResumeVersions(
      {required String token}) async {
    final res = await _client.get(
      _uri('/resume-builder/versions'),
      headers: _jsonHeaders(token: token),
    );
    await _decodeOrThrow(res);
    return (jsonDecode(res.body) as List)
        .map(
            (item) => SavedResumeVersion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SavedResumeDetails> getResumeVersion({
    required String token,
    required String versionId,
  }) async {
    final res = await _client.get(
      _uri('/resume-builder/versions/$versionId'),
      headers: _jsonHeaders(token: token),
    );
    await _decodeOrThrow(res);
    return SavedResumeDetails.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<(Uint8List bytes, String filename)> downloadResumeVersion({
    required String token,
    required String versionId,
  }) async {
    final res = await _client.get(
      _uri('/resume-builder/versions/$versionId/download'),
      headers: _jsonHeaders(token: token),
    );
    await _decodeOrThrow(res);
    final disposition = res.headers['content-disposition'];
    final match = disposition == null
        ? null
        : RegExp(r'filename="([^"]+)"').firstMatch(disposition);
    return (res.bodyBytes, match?.group(1) ?? 'Resume.docx');
  }

  Future<void> deleteResumeVersion({
    required String token,
    required String versionId,
  }) async {
    final res = await _client.delete(
      _uri('/resume-builder/versions/$versionId'),
      headers: _jsonHeaders(token: token),
    );
    await _decodeOrThrow(res);
  }

  Future<List<SavedAtsAnalysis>> getSavedAtsAnalyses(
      {required String token}) async {
    final res = await _client.get(
      _uri('/ats/resume-versions'),
      headers: _jsonHeaders(token: token),
    );
    await _decodeOrThrow(res);
    return (jsonDecode(res.body) as List)
        .map((item) => SavedAtsAnalysis.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SavedAtsAnalysis> runSavedResumeAts({
    required String token,
    required String versionId,
    required bool useAi,
    String? geminiApiKey,
  }) async {
    final uri =
        _uri('/ats/resume-versions/$versionId/${useAi ? 'ai' : 'local'}');
    final http.Response res;
    if (useAi) {
      final request = http.MultipartRequest('POST', uri);
      if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
        request.fields['gemini_api_key'] = geminiApiKey;
      }
      request.headers['Authorization'] = 'Bearer $token';
      final streamed = await _client.send(request);
      res = await http.Response.fromStream(streamed);
    } else {
      res = await _client.post(uri, headers: _jsonHeaders(token: token));
    }
    await _decodeOrThrow(res);
    return SavedAtsAnalysis.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Returns the generated .docx as raw bytes plus the filename the server
  /// suggested (from the Content-Disposition header), for the caller to
  /// write to disk.
  Future<(Uint8List bytes, String filename)> generateResume(
    ResumeBuilderFormState form, {
    required String token,
  }) async {
    final res = await _client.post(
      _uri('/resume-builder/generate'),
      headers: _jsonHeaders(token: token),
      body: jsonEncode(form.toJson()),
    );
    await _decodeOrThrow(res);

    String filename = 'Resume.docx';
    final disposition = res.headers['content-disposition'];
    if (disposition != null) {
      final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
      if (match != null) filename = match.group(1)!;
    }
    return (res.bodyBytes, filename);
  }

  Future<(Uint8List bytes, String filename)> updateSavedResume({
    required String token,
    required String newInformation,
  }) async {
    final res = await _client.post(
      _uri('/resume-builder/update'),
      headers: _jsonHeaders(token: token),
      body: jsonEncode({'new_information': newInformation}),
    );
    await _decodeOrThrow(res);

    String filename = 'Resume.docx';
    final disposition = res.headers['content-disposition'];
    if (disposition != null) {
      final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
      if (match != null) filename = match.group(1)!;
    }
    return (res.bodyBytes, filename);
  }

  // ---------------------------------------------------------------------
  // Saved Jobs
  // ---------------------------------------------------------------------

  Future<List<SavedJob>> getSavedJobs(
      {required String token, String? status}) async {
    final query = status != null ? {'status': status} : null;
    final res = await _client.get(_uri('/saved-jobs', query),
        headers: _jsonHeaders(token: token));
    await _decodeOrThrow(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((j) => SavedJob.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<SavedJob> saveJob({
    required String token,
    required String title,
    String? company,
    String? location,
    String? source,
    String? jobUrl,
    String? salary,
    String? notes,
    String? status,
  }) async {
    final res = await _client.post(
      _uri('/saved-jobs'),
      headers: _jsonHeaders(token: token),
      body: jsonEncode({
        'title': title,
        if (company != null) 'company': company,
        if (location != null) 'location': location,
        if (source != null) 'source': source,
        if (jobUrl != null) 'job_url': jobUrl,
        if (salary != null) 'salary': salary,
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
      }),
    );
    await _decodeOrThrow(res);
    return SavedJob.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<SavedJob> updateSavedJob({
    required String token,
    required String jobId,
    String? title,
    String? company,
    String? location,
    String? source,
    String? jobUrl,
    String? salary,
    String? notes,
    String? status,
  }) async {
    final res = await _client.put(
      _uri('/saved-jobs/$jobId'),
      headers: _jsonHeaders(token: token),
      body: jsonEncode({
        if (title != null) 'title': title,
        if (company != null) 'company': company,
        if (location != null) 'location': location,
        if (source != null) 'source': source,
        if (jobUrl != null) 'job_url': jobUrl,
        if (salary != null) 'salary': salary,
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
      }),
    );
    await _decodeOrThrow(res);
    return SavedJob.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteSavedJob(
      {required String token, required String jobId}) async {
    final res = await _client.delete(_uri('/saved-jobs/$jobId'),
        headers: _jsonHeaders(token: token));
    await _decodeOrThrow(res);
  }

  void dispose() => _client.close();
}

class _TimeoutClient extends http.BaseClient {
  final http.Client _inner;
  final Duration Function() _timeoutProvider;

  _TimeoutClient(this._inner, this._timeoutProvider);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(_timeoutProvider());
  }

  @override
  void close() => _inner.close();
}

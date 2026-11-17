/// Mirrors backend `app.schemas.auth.UserOut` exactly (field names and
/// types) -- see app/schemas/auth.py on the backend.
class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final bool isActive;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  AuthUser copyWith({String? fullName}) => AuthUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        isActive: isActive,
        createdAt: createdAt,
      );
}

/// Mirrors backend `app.schemas.auth.TokenResponse`. Returned by
/// signup/login/change-password (see app/api/routes/auth.py).
class AuthResult {
  final String accessToken;
  final String tokenType;
  final int expiresIn; // seconds
  final AuthUser user;

  const AuthResult({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
        expiresIn: json['expires_in'] as int,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

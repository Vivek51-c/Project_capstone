import 'package:flutter/widgets.dart';

/// Client-side validators. The password rule intentionally mirrors the
/// backend's exact rule in app/schemas/auth.py (_validate_password_strength)
/// so the user sees the same requirement in both places -- if that rule
/// ever changes server-side, update this too; the backend remains the
/// source of truth and will reject anything this misses.
class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? fullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Full name is required.';
    if (v.length < 2) return 'Full name is too short.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 8) return 'Must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter.';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add a lowercase letter.';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add a digit.';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Add a special character.';
    return null;
  }

  /// Returns a validator bound to [original] so it always compares against
  /// that field's *current* text, not a value captured at build time.
  static String? Function(String?) matches(TextEditingController original, {String label = 'Passwords'}) {
    return (value) => value == original.text ? null : '$label do not match.';
  }

  static String? required(String? value, {String label = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$label is required.';
    return null;
  }
}

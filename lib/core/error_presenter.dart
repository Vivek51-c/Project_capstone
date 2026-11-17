import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// User-facing presentation of an error: a short title, a plain-language
/// explanation, and the raw technical detail kept aside for debugging
/// (brief §21 — never show `Exception: ClientException...` to a user).
class FriendlyError {
  final String title;
  final String message;
  final String technicalDetail;
  final IconData icon;
  final bool isRetryable;

  const FriendlyError({
    required this.title,
    required this.message,
    required this.technicalDetail,
    this.icon = Icons.error_outline_rounded,
    this.isRetryable = true,
  });

  /// Translates any thrown object into something worth showing a person.
  factory FriendlyError.from(Object error) {
    final detail = error.toString();

    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return FriendlyError(
            title: 'Check your input',
            message: error.message,
            technicalDetail: detail,
            icon: Icons.info_outline_rounded,
          );
        case 401:
          return FriendlyError(
            title: 'API key needed',
            message: error.message.isNotEmpty
                ? error.message
                : 'This feature needs a valid Gemini API key. Add one and try again.',
            technicalDetail: detail,
            icon: Icons.key_off_rounded,
          );
        case 413:
          return FriendlyError(
            title: 'File is too large',
            message: 'Please upload a resume under 10 MB.',
            technicalDetail: detail,
            icon: Icons.folder_off_rounded,
          );
        case 415:
          return FriendlyError(
            title: 'Unsupported file type',
            message: 'Only PDF and DOCX files can be read. Please convert your file and try again.',
            technicalDetail: detail,
            icon: Icons.description_outlined,
          );
        case 429:
          return FriendlyError(
            title: 'Too many requests',
            message: "You've hit the AI usage limit. Wait a minute, then try again.",
            technicalDetail: detail,
            icon: Icons.hourglass_empty_rounded,
          );
        case 502:
          return FriendlyError(
            title: 'AI service unavailable',
            message: "The AI service didn't respond properly. Try again in a moment.",
            technicalDetail: detail,
            icon: Icons.cloud_off_rounded,
          );
        default:
          return FriendlyError(
            title: 'Something went wrong',
            message: error.message.isNotEmpty ? error.message : 'Please try again.',
            technicalDetail: detail,
          );
      }
    }

    // Detected by type for http, and by message for dart:io's SocketException,
    // which we deliberately don't import so this file still compiles for web.
    final looksLikeNetworkFailure = error is http.ClientException ||
        detail.contains('SocketException') ||
        detail.contains('Connection refused') ||
        detail.contains('Failed host lookup') ||
        detail.contains('Connection closed');

    if (looksLikeNetworkFailure) {
      return FriendlyError(
        title: "Can't reach the server",
        message: 'Check your connection and make sure the backend is running, then try again.',
        technicalDetail: detail,
        icon: Icons.wifi_off_rounded,
      );
    }

    if (error is TimeoutException) {
      return FriendlyError(
        title: 'This is taking too long',
        message: 'The server took too long to respond. Try again.',
        technicalDetail: detail,
        icon: Icons.schedule_rounded,
      );
    }

    if (error is FormatException) {
      return FriendlyError(
        title: 'Unexpected response',
        message: "The server sent something we couldn't read. Try again.",
        technicalDetail: detail,
        icon: Icons.report_gmailerrorred_rounded,
      );
    }

    return FriendlyError(
      title: 'Something went wrong',
      message: 'An unexpected error occurred. Please try again.',
      technicalDetail: detail,
    );
  }
}

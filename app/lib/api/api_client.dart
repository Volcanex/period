import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Thin HTTP wrapper around the Period FastAPI backend.
///
/// Stays intentionally tiny: a base URL, JSON GET/POST, a request timeout,
/// and a typed error. No retries, no global state, no auth — the backend
/// is stateless and there are no accounts in this pass. Each call site
/// decides how to handle failure (typically: log + fall back to bundled
/// defaults).
class ApiClient {
  /// Public production base. Override for local dev (`flutter run --dart-define
  /// PERIOD_API=http://127.0.0.1:8001`) or tests.
  static const String defaultBaseUrl = String.fromEnvironment(
    'PERIOD_API',
    defaultValue: 'https://api.period.gabrielpenman.com',
  );

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  ApiClient({
    String? baseUrl,
    this.timeout = const Duration(seconds: 6),
    http.Client? client,
  }) : baseUrl = baseUrl ?? defaultBaseUrl,
       _http = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// GET a JSON endpoint. Returns the decoded body. Throws [ApiError] on
  /// network failure, timeout, non-2xx status, or unparseable body.
  Future<dynamic> getJson(String path) async {
    final uri = _uri(path);
    try {
      final res = await _http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiError(
          message: 'GET $path returned ${res.statusCode}',
          status: res.statusCode,
        );
      }
      try {
        return jsonDecode(res.body);
      } catch (e) {
        throw ApiError(message: 'GET $path: invalid JSON ($e)');
      }
    } on TimeoutException {
      throw ApiError(
        message: 'GET $path timed out after ${timeout.inSeconds}s',
      );
    } on http.ClientException catch (e) {
      throw ApiError(message: 'GET $path: ${e.message}');
    } catch (e) {
      // Re-raise ApiError, wrap anything else.
      if (e is ApiError) rethrow;
      throw ApiError(message: 'GET $path failed: $e');
    }
  }

  void close() => _http.close();
}

/// Lightweight error type so call sites don't need to catch the union of
/// http exceptions, format exceptions, and timeouts.
@immutable
class ApiError implements Exception {
  final String message;
  final int? status;
  const ApiError({required this.message, this.status});

  @override
  String toString() => 'ApiError($status): $message';
}

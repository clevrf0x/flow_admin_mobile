import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── Result model ──────────────────────────────────────────────────────────────

/// Parsed data from a successful login response.
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String username;
  final String name;
  final String role;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    required this.name,
    required this.role,
  });
}

// ── Error model ───────────────────────────────────────────────────────────────

/// Thrown by [AuthService] when the API returns an error or the network fails.
///
/// [code] matches the backend's standard error codes:
///   'AUTHENTICATION_FAILED' — bad username/password
///   'ROLE_MISMATCH'         — correct credentials but wrong login endpoint
///   'NETWORK_ERROR'         — could not reach the server
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}

// ── Service ───────────────────────────────────────────────────────────────────

class AuthService {
  /// Lazily creates a Dio instance with the base URL from .env.
  static Dio get _dio => Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Calls POST /api/v1/auth/admin/login/ with [username] and [password].
  ///
  /// Returns [AuthResult] on success.
  /// Throws [AuthException] on API error or network failure.
  static Future<AuthResult> adminLogin(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/admin/login/',
        data: {'username': username, 'password': password},
      );

      // Standard envelope: { success: true, data: { user: {...}, tokens: {...} } }
      final data   = response.data['data']   as Map<String, dynamic>;
      final user   = data['user']            as Map<String, dynamic>;
      final tokens = data['tokens']          as Map<String, dynamic>;

      return AuthResult(
        accessToken:  tokens['access']  as String,
        refreshToken: tokens['refresh'] as String,
        username:     user['username']  as String,
        name:         user['name']      as String,
        role:         user['role']      as String,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        // API returned a standard error envelope
        final error = e.response!.data['error'] as Map<String, dynamic>;
        throw AuthException(
          error['code']    as String,
          error['message'] as String,
        );
      }
      // Network-level failure (no response)
      throw const AuthException(
        'NETWORK_ERROR',
        'Could not reach the server. Check your connection.',
      );
    }
  }
}

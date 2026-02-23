// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';

/// Shared, lazily-initialised Dio instance for all authenticated API calls.
///
/// Automatically attaches the Bearer token from secure storage on every
/// request. Call [reset] after logout so the next request gets a fresh instance
/// (avoiding stale tokens).
class ApiClient {
  ApiClient._();

  static Dio? _instance;

  static Dio get dio {
    if (_instance != null) return _instance!;

    _instance = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Inject Bearer token before every request
    _instance!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return _instance!;
  }

  /// Discard the cached instance — call this after logout so the next
  /// authenticated request starts fresh.
  static void reset() => _instance = null;
}

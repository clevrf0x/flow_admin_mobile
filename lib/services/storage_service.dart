import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for typed auth data read/write.
///
/// All values are stored as encrypted key-value pairs on the device keystore.
/// Call [saveAuthData] after a successful login, [clearAll] on logout.
class StorageService {
  static const _storage = FlutterSecureStorage();

  // ── Key constants ──────────────────────────────────────────────────────────
  static const _keyAccessToken  = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUsername     = 'username';
  static const _keyName         = 'name';
  static const _keyRole         = 'role';

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Saves all auth data from a successful login response in parallel.
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String username,
    required String name,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken,  value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyUsername,     value: username),
      _storage.write(key: _keyName,         value: name),
      _storage.write(key: _keyRole,         value: role),
    ]);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  static Future<String?> getAccessToken()  => _storage.read(key: _keyAccessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  static Future<String?> getUsername()     => _storage.read(key: _keyUsername);
  static Future<String?> getName()         => _storage.read(key: _keyName);
  static Future<String?> getRole()         => _storage.read(key: _keyRole);

  /// Returns true if an access token exists (user is logged in).
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Clears all stored auth data. Call on logout.
  static Future<void> clearAll() => _storage.deleteAll();
}

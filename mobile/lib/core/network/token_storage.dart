import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT. Keychain / Keystore on mobile, encrypted storage elsewhere.
abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

final class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth_token';
  final FlutterSecureStorage _storage;
  String? _cache;

  @override
  Future<String?> read() async => _cache ??= await _storage.read(key: _key);

  @override
  Future<void> write(String token) async {
    _cache = token;
    await _storage.write(key: _key, value: token);
  }

  @override
  Future<void> clear() async {
    _cache = null;
    await _storage.delete(key: _key);
  }
}

/// In-memory storage for tests.
final class MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

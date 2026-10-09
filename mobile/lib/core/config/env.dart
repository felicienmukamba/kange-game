import 'package:flutter/foundation.dart';

/// Build-time configuration.
///
/// Override at build time, e.g.
/// `flutter run --dart-define=API_URL=https://api.rewify.app`.
/// `WS_URL` defaults to the API host with the `/ws-native` endpoint.
abstract final class Env {
  static const appName = 'REWIFY';

  static const _apiOverride = String.fromEnvironment('API_URL');
  static const _wsOverride = String.fromEnvironment('WS_URL');

  /// Base URL of the backend, without the `/api/v1` suffix.
  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) return _apiOverride;
    // The Android emulator reaches the host machine through 10.0.2.2.
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
    return 'http://$host:8080';
  }

  static String get apiUrl => '$apiBaseUrl/api/v1';

  static String get wsUrl {
    if (_wsOverride.isNotEmpty) return _wsOverride;
    final base = Uri.parse(apiBaseUrl);
    return base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: '/ws-native').toString();
  }
}

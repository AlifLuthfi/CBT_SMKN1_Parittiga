import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const String baseUrlWeb          = 'http://localhost:8000/api';
  static const String baseUrlLocal        = 'http://127.0.0.1:8000/api';
  static const String baseUrlAndroidEmu   = 'http://10.0.2.2:8000/api';
  static const String baseUrlLocalNetwork = 'http://192.168.74.128:8000/api';
  static const String baseUrlHosting    = ''; // set via .env atau runtime
  static String get baseUrlDefault => kIsWeb || defaultTargetPlatform != TargetPlatform.android
      ? baseUrlWeb
      : baseUrlAndroidEmu;

  static const int    connectTimeoutMs    = 30000;
  static const int    receiveTimeoutMs    = 30000;
  static const String keyToken       = 'ec_token';
  static const String keyUser        = 'ec_user';
  static const String keyRole        = 'ec_role';
  static const String keyBaseUrl     = 'ec_base_url';
  static const String keyExamSession = 'ec_exam_session';
  static const String keyDeviceId    = 'ec_device_id';
  static const String keyBiometric   = 'ec_biometric_enabled';
  static const String keyTheme       = 'ec_theme';
  static const String roleAdmin      = 'admin';
  static const String roleGuru       = 'guru';
  static const String roleSiswa      = 'siswa';
  static const int maxViolations        = 5;
  static const int autoSaveIntervalSecs = 10;
  static const int warningTimeSecs      = 300;
  static const int dangerTimeSecs       = 60;
  static const int lcgA = 1664525;
  static const int lcgC = 1013904223;
  static const int lcgM = 4294967296;
  static const int defaultPerPage = 15;

  /// Resolve relative image URL (e.g. "/storage/questions/...png")
  /// ke absolute URL pakai base yang sesuai platform.
  /// Kalau udah absolute (http/https) dibiarin.
  static String? resolveImageUrl(String? url) {
    if (url == null) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) {
      final base = baseUrlDefault.replaceAll('/api', '');
      return '$base$url';
    }
    return url;
  }
}

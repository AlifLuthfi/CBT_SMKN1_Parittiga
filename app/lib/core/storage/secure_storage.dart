import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static Future<void>    saveToken(String t)  => _storage.write(key: AppConstants.keyToken, value: t);
  static Future<String?> getToken()           => _storage.read(key: AppConstants.keyToken);
  static Future<void>    deleteToken()        => _storage.delete(key: AppConstants.keyToken);

  static Future<void> saveUser(Map<String, dynamic> u) =>
      _storage.write(key: AppConstants.keyUser, value: jsonEncode(u));
  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: AppConstants.keyUser);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }

  static Future<void>    saveRole(String r)  => _storage.write(key: AppConstants.keyRole, value: r);
  static Future<String?> getRole()           => _storage.read(key: AppConstants.keyRole);

  static Future<void>   saveBaseUrl(String u) => _storage.write(key: AppConstants.keyBaseUrl, value: u);
  static Future<String> getBaseUrl() async =>
      (await _storage.read(key: AppConstants.keyBaseUrl)) ?? AppConstants.baseUrlDefault;

  static Future<void> saveExamSession(Map<String, dynamic> s) =>
      _storage.write(key: AppConstants.keyExamSession, value: jsonEncode(s));
  static Future<Map<String, dynamic>?> getExamSession() async {
    final raw = await _storage.read(key: AppConstants.keyExamSession);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }
  static Future<void> clearExamSession() => _storage.delete(key: AppConstants.keyExamSession);

  static Future<void>    saveDeviceId(String id) => _storage.write(key: AppConstants.keyDeviceId, value: id);
  static Future<String?> getDeviceId()           => _storage.read(key: AppConstants.keyDeviceId);

  static Future<void> saveBiometricEnabled(bool v) =>
      _storage.write(key: AppConstants.keyBiometric, value: v.toString());
  static Future<bool> getBiometricEnabled() async =>
      (await _storage.read(key: AppConstants.keyBiometric)) == 'true';

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  static Future<void> clearAll()  => _storage.deleteAll();
  static Future<void> clearAuth() async {
    await deleteToken();
    await _storage.delete(key: AppConstants.keyUser);
    await _storage.delete(key: AppConstants.keyRole);
  }
}

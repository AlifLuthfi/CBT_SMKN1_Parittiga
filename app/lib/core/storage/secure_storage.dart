import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Native → FlutterSecureStorage (keystore/keychain).
/// Web → SharedPreferences (karena FSS gak support web).
class SecureStorage {
  static final _storage = FlutterSecureStorage(
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

  static bool get _isWeb => kIsWeb;

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<void> _write(String key, String value) async {
    if (_isWeb) {
      final p = await _prefs;
      await p.setString(key, value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  static Future<String?> _read(String key) async {
    if (_isWeb) {
      final p = await _prefs;
      return p.getString(key);
    }
    return _storage.read(key: key);
  }

  static Future<void> _delete(String key) async {
    if (_isWeb) {
      final p = await _prefs;
      await p.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }

  static Future<void> _deleteAll() async {
    if (_isWeb) {
      final p = await _prefs;
      await p.clear();
    } else {
      await _storage.deleteAll();
    }
  }

  static Future<void>    saveToken(String t)  => _write(AppConstants.keyToken, t);
  static Future<String?> getToken()           => _read(AppConstants.keyToken);
  static Future<void>    deleteToken()        => _delete(AppConstants.keyToken);

  static Future<void> saveUser(Map<String, dynamic> u) =>
      _write(AppConstants.keyUser, jsonEncode(u));
  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _read(AppConstants.keyUser);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }

  static Future<void>    saveRole(String r)  => _write(AppConstants.keyRole, r);
  static Future<String?> getRole()           => _read(AppConstants.keyRole);

  static Future<void>   saveBaseUrl(String u) => _write(AppConstants.keyBaseUrl, u);
  static Future<String> getBaseUrl() async =>
      (await _read(AppConstants.keyBaseUrl)) ?? AppConstants.baseUrlDefault;

  static Future<void> saveExamSession(Map<String, dynamic> s) =>
      _write(AppConstants.keyExamSession, jsonEncode(s));
  static Future<Map<String, dynamic>?> getExamSession() async {
    final raw = await _read(AppConstants.keyExamSession);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }
  static Future<void> clearExamSession() => _delete(AppConstants.keyExamSession);

  static Future<void>    saveDeviceId(String id) => _write(AppConstants.keyDeviceId, id);
  static Future<String?> getDeviceId()           => _read(AppConstants.keyDeviceId);

  static Future<void> saveBiometricEnabled(bool v) =>
      _write(AppConstants.keyBiometric, v.toString());
  static Future<bool> getBiometricEnabled() async =>
      (await _read(AppConstants.keyBiometric)) == 'true';

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  static Future<void> clearAll()  => _deleteAll();
  static Future<void> clearAuth() async {
    await deleteToken();
    await _delete(AppConstants.keyUser);
    await _delete(AppConstants.keyRole);
  }
}

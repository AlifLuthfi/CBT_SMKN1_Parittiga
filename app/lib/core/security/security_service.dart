import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../storage/secure_storage.dart';

class SecurityService {
  static final _localAuth  = LocalAuthentication();
  static final _deviceInfo = DeviceInfoPlugin();

  // ── Device ID ─────────────────────────────────────────
  static Future<String> getDeviceId() async {
    final saved = await SecureStorage.getDeviceId();
    if (saved != null) return saved;
    String raw = '';
    try {
      if (Platform.isAndroid) {
        final i = await _deviceInfo.androidInfo;
        raw = '${i.id}_${i.model}_${i.brand}_${i.fingerprint}';
      } else if (Platform.isIOS) {
        final i = await _deviceInfo.iosInfo;
        raw = '${i.identifierForVendor}_${i.model}_${i.systemVersion}';
      } else {
        raw = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (_) {
      raw = _randomHex();
    }
    final id = sha256.convert(utf8.encode(raw)).toString();
    await SecureStorage.saveDeviceId(id);
    return id;
  }

  static String _randomHex() {
    final r = Random.secure();
    return List.generate(32, (_) => r.nextInt(256).toRadixString(16).padLeft(2,'0')).join();
  }

  // ── Biometric ─────────────────────────────────────────
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (_) { return false; }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try { return await _localAuth.getAvailableBiometrics(); }
    catch (_) { return []; }
  }

  static Future<bool> authenticateWithBiometric({String reason = 'Verifikasi identitas Anda'}) async {
    try {
      return await _localAuth.authenticate(localizedReason: reason);
    } catch (_) { return false; }
  }

  // ── Root / Jailbreak ──────────────────────────────────
  static Future<bool> isDeviceCompromised() async {
    if (kDebugMode) return false;
    try {
      if (Platform.isAndroid) return await _isRooted();
      if (Platform.isIOS)     return await _isJailbroken();
    } catch (_) {}
    return false;
  }

  static Future<bool> _isRooted() async {
    for (final p in ['/system/xbin/su','/system/bin/su','/sbin/su',
                     '/system/app/Superuser.apk','/data/local/su']) {
      if (await File(p).exists()) return true;
    }
    return false;
  }

  static Future<bool> _isJailbroken() async {
    for (final p in ['/Applications/Cydia.app','/usr/sbin/sshd',
                     '/etc/apt','/private/var/lib/apt']) {
      if (await File(p).exists()) return true;
    }
    return false;
  }

  // ── Hash token untuk logging (tidak expose token asli) ──
  static String hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString().substring(0, 16) + '...';

  // ── Certificate pinning helper ─────────────────────────
  static bool isValidHost(String url) {
    try {
      final uri = Uri.parse(url);
      // Izinkan localhost dan private IP
      return uri.host == 'localhost' ||
             uri.host.startsWith('192.168.') ||
             uri.host.startsWith('10.') ||
             uri.host.startsWith('172.') ||
             uri.host == '10.0.2.2' ||
             uri.host.endsWith('.school.id') ||
             uri.host.endsWith('.sch.id') ||
             uri.host.endsWith('.ngrok-free.app') ||
             uri.host.endsWith('.ngrok-free.dev') ||
             uri.host.endsWith('.ngrok.app') ||
             uri.host.endsWith('.ngrok.io');
    } catch (_) { return false; }
  }
}

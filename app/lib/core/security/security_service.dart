import 'dart:io';
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
      // catat error, jangan generate random — nanti device ID berubah2
      raw = 'fallback_device_id';
    }
    final id = sha256.convert(utf8.encode(raw)).toString();
    await SecureStorage.saveDeviceId(id);
    return id;
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
      final host = uri.host;
      // Izinkan localhost dan private IP
      if (host == 'localhost' || host == '10.0.2.2' || host == '127.0.0.1') return true;
      if (host.startsWith('192.168.')) return true;
      if (host.startsWith('10.') &&
          !host.startsWith('100.') &&
          !host.startsWith('101.') &&
          !host.startsWith('102.') &&
          !host.startsWith('103.') &&
          !host.startsWith('104.') &&
          !host.startsWith('105.') &&
          !host.startsWith('106.') &&
          !host.startsWith('107.') &&
          !host.startsWith('108.') &&
          !host.startsWith('109.') &&
          !host.startsWith('110.') &&
          !host.startsWith('111.') &&
          !host.startsWith('112.') &&
          !host.startsWith('113.') &&
          !host.startsWith('114.') &&
          !host.startsWith('115.') &&
          !host.startsWith('116.') &&
          !host.startsWith('117.') &&
          !host.startsWith('118.') &&
          !host.startsWith('119.') &&
          !host.startsWith('120.') &&
          !host.startsWith('121.') &&
          !host.startsWith('122.') &&
          !host.startsWith('123.') &&
          !host.startsWith('124.') &&
          !host.startsWith('125.') &&
          !host.startsWith('126.') &&
          !host.startsWith('127.')) return true;
      // prefix 172.16-31
      if (host.startsWith('172.')) {
        final parts = host.split('.');
        if (parts.length >= 3) {
          final octet = int.tryParse(parts[1]);
          if (octet != null && octet >= 16 && octet <= 31) return true;
        }
      }
      return host.endsWith('.school.id') ||
             host.endsWith('.sch.id');
    } catch (_) { return false; }
  }
}

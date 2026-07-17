import 'dart:io';
import 'package:flutter/services.dart';

/// Anti-cheat native platform bridge.
/// Full device lockdown: FLAG_SECURE, lock task (kiosk mode), multi-window
/// detection, screen recording detection.
class AntiCheatService {
  static const _channel = MethodChannel('com.smkn1parittiga.examcore/anticheat');

  // ── FLAG_SECURE — blocks screenshots & screen recording ─
  static Future<void> enableSecureFlag() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecureFlag');
    } catch (_) {}
  }

  static Future<void> disableSecureFlag() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecureFlag');
    } catch (_) {}
  }

  // ── Lock task (screen pinning / kiosk mode) ─────────────
  /// Enter Android lock task mode — blocks home, recents, nav bar.
  /// Requires screen pinning enabled in Settings → Security.
  static Future<void> enterLockTask() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enterLockTask');
    } catch (_) {}
  }

  /// Exit Android lock task mode.
  static Future<void> exitLockTask() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('exitLockTask');
    } catch (_) {}
  }

  // ── Multi-window & screen recording ────────────────────
  static Future<bool> isInMultiWindow() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('isInMultiWindow') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isScreenRecording() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('isScreenRecording') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Register multi-window change callback.
  static void onMultiWindowChanged(void Function(bool isMultiWindow) callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMultiWindowChanged') {
        callback(call.arguments as bool);
      }
    });
  }

  // ── Physical keyboard blocking (Android) ──────────────────
  static Future<void> enableKeyboardBlock() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableKeyboardBlock');
    } catch (_) {}
  }

  static Future<void> disableKeyboardBlock() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableKeyboardBlock');
    } catch (_) {}
  }
}

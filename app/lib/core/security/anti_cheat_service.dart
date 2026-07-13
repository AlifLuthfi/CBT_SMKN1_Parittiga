import 'dart:io';
import 'package:flutter/services.dart';

/// Anti-cheat native platform bridge.
/// Prevents screenshots, screen recording, detects split-screen/multi-window.
class AntiCheatService {
  static const _channel = MethodChannel('com.smkn1parittiga.examcore/anticheat');

  /// Enable FLAG_SECURE on Android — blocks screenshots & screen recording.
  static Future<void> enableSecureFlag() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecureFlag');
    } catch (_) {}
  }

  /// Disable FLAG_SECURE (on exam end).
  static Future<void> disableSecureFlag() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecureFlag');
    } catch (_) {}
  }

  /// Check if device is in multi-window / split-screen mode (Android only).
  static Future<bool> isInMultiWindow() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('isInMultiWindow') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if screen recording is active (Android 11+).
  static Future<bool> isScreenRecording() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('isScreenRecording') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Register multi-window change callback.
  /// Android sends "onMultiWindowChanged" event.
  static void onMultiWindowChanged(void Function(bool isMultiWindow) callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMultiWindowChanged') {
        callback(call.arguments as bool);
      }
    });
  }
}

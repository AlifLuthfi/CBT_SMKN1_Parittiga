import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Windows-specific exam lockdown.
/// Kiosk-style fullscreen: borderless, no close/minimize, no taskbar.
/// Low-level keyboard hook blocks alt+tab, win keys, alt+f4, etc.
class WindowsAntiCheat {
  static const _channel = MethodChannel('com.smkn1parittiga.examcore/anticheat_win');
  static bool _locked = false;

  static Future<void> lock() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await windowManager.waitUntilReadyToShow();
      await windowManager.setFullScreen(true);
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setResizable(false);
      // Block keyboard shortcuts via low-level hook
      await _channel.invokeMethod('enableKeyboardBlock');
      _locked = true;
    } catch (_) {}
  }

  static Future<void> unlock() async {
    if (!Platform.isWindows || !_locked) return;
    try {
      await windowManager.setFullScreen(false);
      await windowManager.setPreventClose(false);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setResizable(true);
      await _channel.invokeMethod('disableKeyboardBlock');
      _locked = false;
    } catch (_) {}
  }

  static Future<bool> hasFocus() async {
    if (!Platform.isWindows) return true;
    try {
      return await windowManager.isFocused();
    } catch (_) {
      return true;
    }
  }

  static bool get isLocked => _locked;
}

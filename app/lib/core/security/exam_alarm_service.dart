import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Android alarm service bridge.
/// Triggers a loud looping alarm via STREAM_ALARM (ignores ringer volume).
/// Alarm can only be stopped by calling [stopAlarm] — volume keys are
/// overridden server-side every 500ms.
///
/// Includes heartbeat ping to verify service is alive, auto-retrigger if dead.
class ExamAlarmService {
  static const _channel = MethodChannel('com.smkn1parittiga.examcore/alarm');
  static Timer? _heartbeat;
  static bool _shouldBePlaying = false;

  /// Start loud looping alarm on STREAM_ALARM.
  /// Volume enforced at max every 500ms, auto-stops after 15 min safety net.
  static Future<void> startAlarm() async {
    if (!Platform.isAndroid) return;
    _shouldBePlaying = true;
    try {
      await _channel.invokeMethod('startAlarm');
    } catch (_) {}
    _startHeartbeat();
  }

  /// Stop the alarm (called on successful unlock).
  static Future<void> stopAlarm() async {
    if (!Platform.isAndroid) return;
    _shouldBePlaying = false;
    _stopHeartbeat();
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (_) {}
  }

  /// Check if alarm is currently playing.
  static Future<bool> isAlarmPlaying() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('isAlarmPlaying') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Heartbeat — tiap 10s cek apakah service masih hidup.
  /// Kalo mati (tapi harusnya nyala), retrigger.
  static void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_shouldBePlaying) return;
      try {
        final playing = await isAlarmPlaying();
        if (!playing) {
          // Service mati — retrigger
          await _channel.invokeMethod('startAlarm');
        }
      } catch (_) {
        // Channel error — coba start ulang
        try {
          await _channel.invokeMethod('startAlarm');
        } catch (_) {}
      }
    });
  }

  static void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }
}

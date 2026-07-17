package id.sch.examcore

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import android.app.ActivityManager
import android.content.Context
import android.content.res.Configuration
import android.view.Window

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.smkn1parittiga.examcore/anticheat"
    private val ALARM_CHANNEL = "com.smkn1parittiga.examcore/alarm"

    private var _flutterEngine: FlutterEngine? = null

    @Volatile
    private var examMode = false           // lock task aktif
    @Volatile
    private var blockKeyboard = false      // block physical keyboard

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        _flutterEngine = flutterEngine

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureFlag" -> {
                        enableSecureFlag()
                        result.success(true)
                    }
                    "disableSecureFlag" -> {
                        disableSecureFlag()
                        result.success(true)
                    }
                    "isInMultiWindow" -> {
                        result.success(isInMultiWindowMode)
                    }
                    "isScreenRecording" -> {
                        result.success(isScreenRecording())
                    }
                    "enterLockTask" -> {
                        enterLockTask()
                        result.success(true)
                    }
                    "exitLockTask" -> {
                        exitLockTask()
                        result.success(true)
                    }
                    "enableKeyboardBlock" -> {
                        blockKeyboard = true
                        result.success(true)
                    }
                    "disableKeyboardBlock" -> {
                        blockKeyboard = false
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAlarm" -> {
                        startAlarmService()
                        result.success(true)
                    }
                    "stopAlarm" -> {
                        stopAlarmService()
                        result.success(true)
                    }
                    "isAlarmPlaying" -> {
                        result.success(AlarmService.isPlaying)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Lock Task (Screen Pinning) ────────────────────────
    // Blocks home, recent apps, nav bar — full kiosk mode.

    private fun enterLockTask() {
        runOnUiThread {
            examMode = true
            try {
                startLockTask()
            } catch (_: Exception) {
                // User must enable screen pinning in Settings → Security
            }
        }
    }

    private fun exitLockTask() {
        runOnUiThread {
            examMode = false
            try {
                stopLockTask()
            } catch (_: Exception) {}
        }
    }

    // Auto re-lock jika user berhasil tap home/recents (immediate re-pin)
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && examMode) {
            try { startLockTask() } catch (_: Exception) {}
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Try re-lock sebelum user benar-benar pindah
        if (examMode) {
            try { startLockTask() } catch (_: Exception) {}
        }
    }

    // ── Physical keyboard blocking ─────────────────────────
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (blockKeyboard && isExamBlockedKey(keyCode)) {
            return true // consume event, blocked
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (blockKeyboard && isExamBlockedKey(keyCode)) {
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    override fun onBackPressed() {
        // During exam, back press is blocked — Flutter handles it
        if (examMode) return
        super.onBackPressed()
    }

    private fun isExamBlockedKey(keyCode: Int): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_HOME -> true              // Home button (hardware)
            KeyEvent.KEYCODE_APP_SWITCH -> true          // Recent apps
            KeyEvent.KEYCODE_MENU -> true                // Menu key
            KeyEvent.KEYCODE_BACK -> true                // Back key
            KeyEvent.KEYCODE_VOLUME_UP -> true           // Volume (optional, can be unblocked)
            KeyEvent.KEYCODE_VOLUME_DOWN -> true
            KeyEvent.KEYCODE_CAMERA -> true              // Camera button
            KeyEvent.KEYCODE_SEARCH -> true              // Search key
            KeyEvent.KEYCODE_ESCAPE -> true              // ESC (external keyboard)
            KeyEvent.KEYCODE_F1, KeyEvent.KEYCODE_F2, KeyEvent.KEYCODE_F3, KeyEvent.KEYCODE_F4,
            KeyEvent.KEYCODE_F5, KeyEvent.KEYCODE_F6, KeyEvent.KEYCODE_F7, KeyEvent.KEYCODE_F8,
            KeyEvent.KEYCODE_F9, KeyEvent.KEYCODE_F10, KeyEvent.KEYCODE_F11, KeyEvent.KEYCODE_F12 -> true
            KeyEvent.KEYCODE_SYSRQ -> true               // Print Screen
            KeyEvent.KEYCODE_BRIGHTNESS_DOWN, KeyEvent.KEYCODE_BRIGHTNESS_UP -> true
            else -> false
        }
    }

    // ── Alarm Service ─────────────────────────────────────
    private fun startAlarmService() {
        val intent = Intent(this, AlarmService::class.java).apply {
            action = AlarmService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAlarmService() {
        val intent = Intent(this, AlarmService::class.java).apply {
            action = AlarmService.ACTION_STOP
        }
        startService(intent)
    }

    // ── FLAG_SECURE ───────────────────────────────────────
    private fun enableSecureFlag() {
        runOnUiThread {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    private fun disableSecureFlag() {
        runOnUiThread {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun onMultiWindowModeChanged(isInMultiWindow: Boolean) {
        super.onMultiWindowModeChanged(isInMultiWindow)
        MethodChannel(
            _flutterEngine?.dartExecutor?.binaryMessenger ?: return,
            CHANNEL
        ).invokeMethod("onMultiWindowChanged", isInMultiWindow)
    }

    @Suppress("DEPRECATION")
    private fun isScreenRecording(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningServices = am.getRunningServices(Int.MAX_VALUE)
        return runningServices.any { service ->
            service.service?.className?.contains("screenrecord", ignoreCase = true) == true ||
            service.service?.className?.contains("recording", ignoreCase = true) == true ||
            service.service?.className?.contains("MediaProjection", ignoreCase = true) == true
        }
    }

    override fun onPause() {
        // Keep FLAG_SECURE in picture-in-picture etc.
        super.onPause()
    }
}

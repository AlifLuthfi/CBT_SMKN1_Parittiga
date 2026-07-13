package id.sch.examcore

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.app.ActivityManager
import android.content.Context
import android.content.res.Configuration

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.smkn1parittiga.examcore/anticheat"
    private var secureEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    else -> result.notImplemented()
                }
            }
    }

    private fun enableSecureFlag() {
        runOnUiThread {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
            secureEnabled = true
        }
    }

    private fun disableSecureFlag() {
        runOnUiThread {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            secureEnabled = false
        }
    }

    override fun onMultiWindowModeChanged(newConfig: Configuration) {
        super.onMultiWindowModeChanged(newConfig)
        // Notify Flutter via method channel
        MethodChannel(
            (this as io.flutter.embedding.android.FlutterActivity).flutterEngine?.dartExecutor?.binaryMessenger ?: return,
            CHANNEL
        ).invokeMethod("onMultiWindowChanged", isInMultiWindowMode)
    }

    @Suppress("DEPRECATION")
    private fun isScreenRecording(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE)
        // We check via ActivityManager.RunningServiceInfo approach as fallback
        // MediaProjection API doesn't have a direct "is recording" query from non-owner
        // Best effort: check if any RecordingService is active
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningServices = am.getRunningServices(Int.MAX_VALUE)
        return runningServices.any { service ->
            service.service?.className?.contains("screenrecord", ignoreCase = true) == true ||
            service.service?.className?.contains("recording", ignoreCase = true) == true ||
            service.service?.className?.contains("MediaProjection", ignoreCase = true) == true
        }
    }

    override fun onBackPressed() {
        // Back button handled by Flutter — do nothing here
        // Flutter will show password dialog
    }
}

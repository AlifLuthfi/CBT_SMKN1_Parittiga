package id.sch.examcore

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.sin

class AlarmService : Service() {
    companion object {
        const val CHANNEL_ID = "exam_alarm_channel"
        const val NOTIFICATION_ID = 9001
        const val ACTION_START = "id.sch.examcore.ALARM_START"
        const val ACTION_STOP = "id.sch.examcore.ALARM_STOP"
        const val ACTION_CHECK = "id.sch.examcore.ALARM_CHECK"
        const val ACTION_STOP_FROM_NOTIF = "id.sch.examcore.ALARM_STOP_FROM_NOTIF"

        @Volatile
        var isPlaying = false
            private set

        private const val AUTO_STOP_MS = 15 * 60 * 1000L // 15 menit safety net
        private const val VOLUME_ENFORCE_MS = 100L       // enforce every 100ms — super aggressive
    }

    private var mediaPlayer: MediaPlayer? = null
    private var volumeHandler: Handler? = null
    private var volumeRunnable: Runnable? = null
    private var autoStopHandler: Handler? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        // Acquire partial wake lock to keep CPU alive
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "examcore:alarm")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                wakeLock?.acquire(15 * 60 * 1000L) // max 15 min
                startForeground(NOTIFICATION_ID, buildNotification())
                startAlarmImpl()
            }
            ACTION_STOP, ACTION_STOP_FROM_NOTIF -> stopAlarmImpl()
            ACTION_CHECK -> {
                isPlaying = mediaPlayer?.isPlaying == true
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Notification ──────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID, "Alarm Ujian", NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm keamanan saat ujian berlangsung"
                setSound(null, null)
                enableVibration(false)
            }
            val mgr = getSystemService(NotificationManager::class.java)
            mgr.createNotificationChannel(ch)
        }
    }

    private fun buildNotification(): Notification {
        // Stop action on notification
        val stopIntent = Intent(this, AlarmService::class.java).apply {
            action = ACTION_STOP_FROM_NOTIF
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Open app action
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val launchPendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this, 1, launchIntent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                else PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else null

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Alarm Keamanan Ujian")
            .setContentText("Alarm aktif — kembali ke aplikasi untuk mematikan")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(launchPendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "Stop Alarm", stopPendingIntent)
            .setFullScreenIntent(launchPendingIntent, true)
            .build()
    }

    // ── Alarm implementation ──────────────────────────────

    @Suppress("DEPRECATION")
    private fun startAlarmImpl() {
        try {
            // Generate alarm WAV → cache
            val wav = generateAlarmWav()
            val audioFile = File(cacheDir, "exam_alarm.wav")
            FileOutputStream(audioFile).use { it.write(wav) }

            val am = getSystemService(AUDIO_SERVICE) as AudioManager

            // Force max volume immediately
            am.setStreamVolume(
                AudioManager.STREAM_ALARM,
                am.getStreamMaxVolume(AudioManager.STREAM_ALARM),
                0
            )

            // Periodic volume enforcer — tiap 300ms
            volumeHandler = Handler(Looper.getMainLooper())
            volumeRunnable = Runnable {
                val audio = getSystemService(AUDIO_SERVICE) as AudioManager
                audio.setStreamVolume(
                    AudioManager.STREAM_ALARM,
                    audio.getStreamMaxVolume(AudioManager.STREAM_ALARM),
                    0
                )
                volumeHandler?.postDelayed(volumeRunnable!!, VOLUME_ENFORCE_MS)
            }
            volumeHandler?.post(volumeRunnable!!)

            // Auto-stop safety net — 15 menit
            autoStopHandler = Handler(Looper.getMainLooper())
            autoStopHandler?.postDelayed({
                if (isPlaying) stopAlarmImpl()
            }, AUTO_STOP_MS)

            // Play looping via MediaPlayer on STREAM_ALARM
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(audioFile.absolutePath)
                isLooping = true
                setVolume(1.0f, 1.0f)
                prepare()
                start()
            }

            isPlaying = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAlarmImpl() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            mediaPlayer = null
            volumeHandler?.removeCallbacksAndMessages(null)
            volumeHandler = null
            volumeRunnable = null
            autoStopHandler?.removeCallbacksAndMessages(null)
            autoStopHandler = null
            isPlaying = false

            // Hapus file audio sementara
            try { File(cacheDir, "exam_alarm.wav").delete() } catch (_: Exception) {}

            // Release wake lock
            try { wakeLock?.release() } catch (_: Exception) {}

            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ── WAV generator — nada alarm keras ──────────────────

    private fun generateAlarmWav(): ByteArray {
        val sampleRate = 22050
        val durationSec = 3
        val channels = 1
        val bps = 16
        val numSamples = sampleRate * durationSec
        val dataSize = numSamples * channels * (bps / 8)

        val bos = ByteArrayOutputStream()

        fun w16(v: Int) = bos.write(
            ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN).putShort(v.toShort()).array()
        )
        fun w32(v: Int) = bos.write(
            ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(v).array()
        )

        // RIFF header
        bos.write("RIFF".toByteArray()); w32(36 + dataSize)
        bos.write("WAVE".toByteArray())
        bos.write("fmt ".toByteArray()); w32(16); w16(1); w16(channels)
        w32(sampleRate)
        w32(sampleRate * channels * (bps / 8))
        w16(channels * (bps / 8)); w16(bps)
        bos.write("data".toByteArray()); w32(dataSize)

        // Sample data — campuran 3 frekuensi dissonant + AM 3Hz
        val buf = ByteArray(dataSize)
        for (i in 0 until numSamples) {
            val t = i.toDouble() / sampleRate
            val env = (sin(2.0 * PI * 3.0 * t) * 0.5 + 0.5) // amplitude modulation
            val s1 = sin(2.0 * PI * 800.0 * t)
            val s2 = sin(2.0 * PI * 1250.0 * t + PI / 3)
            val s3 = sin(2.0 * PI * 1800.0 * t + 2.0 * PI / 3)
            var mix = (s1 * 0.4 + s2 * 0.35 + s3 * 0.25) * env
            mix = mix.coerceIn(-0.8, 0.8) / 0.8 // clipping → harsh
            val s = (mix * Short.MAX_VALUE).toInt().toShort()
            buf[i * 2] = (s.toInt() and 0xFF).toByte()
            buf[i * 2 + 1] = ((s.toInt() shr 8) and 0xFF).toByte()
        }
        bos.write(buf)
        return bos.toByteArray()
    }
}

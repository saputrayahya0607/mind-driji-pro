package com.hn.mind_drji

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import io.flutter.plugin.common.EventChannel

/**
 * Android Foreground Service untuk Background Eye Monitoring.
 *
 * FITUR & KEAMANAN:
 * 1. Menggunakan foreground service type: camera (Android 14+ / API 34+ compliant).
 * 2. Hanya aktif setelah user memberikan camera permission dan eksplisit memilih "Aktifkan Monitoring".
 * 3. Kamera TIDAK MENYALA TERUS: kamera hanya melakukan sampling berkala (default 1 menit tiap 30 menit).
 * 4. Saat di luar sesi sampling, kamera dilepas (unbindAll, camera OFF).
 * 5. Tetap berjalan saat pengguna membuka aplikasi lain (TikTok, Instagram, YouTube, WhatsApp, dll).
 * 6. Stop total saat user memilih "Matikan Monitoring" atau saat user logout.
 * 7. Tidak menyimpan foto, video, ataupun raw frame wajah.
 */
class EyeMonitoringForegroundService : Service(), LifecycleOwner {

    private val lifecycleRegistry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle get() = lifecycleRegistry

    private val handler = Handler(Looper.getMainLooper())
    private var eyeMonitoringManager: EyeMonitoringManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // Konfigurasi & State
    private var intervalMillis: Long = 30 * 60 * 1000L // Default: 30 menit
    private var sessionDurationMillis: Long = 60 * 1000L // Default: 1 menit
    private var userId: String = "local_user"
    private var deviceId: String = "unknown_device"

    // Cooldown notifikasi indikasi kelelahan (default 15 menit)
    private var fatigueCooldownMillis: Long = 15 * 60 * 1000L
    private var lastFatigueNotificationTime: Long = 0L

    private val sessionRunner = Runnable {
        runCameraSession()
    }

    private val sessionStopper = Runnable {
        stopCameraSession("duration_elapsed")
    }

    companion object {
        const val TAG = "MIND_DRIJI_EYE_SVC"

        const val CHANNEL_ID = "minddriji_eye_monitoring"
        const val CHANNEL_NAME = "Eye Monitoring MIND DRIJI"
        const val NOTIFICATION_ID = 2001

        const val FATIGUE_CHANNEL_ID = "minddriji_eye_fatigue"
        const val FATIGUE_CHANNEL_NAME = "Indikasi Kondisi Mata"
        const val FATIGUE_NOTIFICATION_ID = 2002

        const val ACTION_START_SERVICE = "com.hn.mind_drji.action.START_EYE_MONITORING"
        const val ACTION_STOP_SERVICE = "com.hn.mind_drji.action.STOP_EYE_MONITORING"
        const val ACTION_TRIGGER_SESSION = "com.hn.mind_drji.action.TRIGGER_EYE_SESSION"

        const val EXTRA_INTERVAL_MS = "extra_interval_ms"
        const val EXTRA_SESSION_DURATION_MS = "extra_session_duration_ms"
        const val EXTRA_USER_ID = "extra_user_id"
        const val EXTRA_DEVICE_ID = "extra_device_id"
        const val EXTRA_IMMEDIATE_SESSION = "extra_immediate_session"

        @Volatile
        var isServiceRunning = false
            private set

        @Volatile
        var isSchedulerRunning = false
            private set

        @Volatile
        var isSessionRunning = false
            private set

        @Volatile
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onCreate() {
        super.onCreate()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_START)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)

        createNotificationChannels()
        eyeMonitoringManager = EyeMonitoringManager(applicationContext)

        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "MindDriji:EyeMonitoringWakeLock"
        )

        Log.d(TAG, "EyeMonitoringForegroundService onCreate")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START_SERVICE

        when (action) {
            ACTION_STOP_SERVICE -> {
                Log.d(TAG, "Received ACTION_STOP_SERVICE -> stopping service totally")
                stopServiceTotal()
                return START_NOT_STICKY
            }
            ACTION_TRIGGER_SESSION -> {
                Log.d(TAG, "Received ACTION_TRIGGER_SESSION -> triggering immediate session")
                if (!isSessionRunning) {
                    runCameraSession()
                }
                return START_STICKY
            }
            ACTION_START_SERVICE -> {
                // Update konfigurasi jika disediakan di intent
                intent?.let {
                    val customInterval = it.getLongExtra(EXTRA_INTERVAL_MS, -1L)
                    if (customInterval > 0) intervalMillis = customInterval

                    val customDuration = it.getLongExtra(EXTRA_SESSION_DURATION_MS, -1L)
                    if (customDuration > 0) sessionDurationMillis = customDuration

                    it.getStringExtra(EXTRA_USER_ID)?.let { uid -> userId = uid }
                    it.getStringExtra(EXTRA_DEVICE_ID)?.let { did -> deviceId = did }
                }

                startForegroundNotification()
                isServiceRunning = true

                // Guard: scheduler duplicate
                val immediate = intent?.getBooleanExtra(EXTRA_IMMEDIATE_SESSION, true) ?: true
                startScheduler(immediate)
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Membangun dan menjalankan Foreground Notification.
     */
    private fun startForegroundNotification() {
        val notification = buildForegroundNotification(
            title = "Monitoring Mata Aktif",
            content = "MIND DRIJI sedang memantau kondisi mata secara berkala."
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
                )
            } catch (e: Exception) {
                Log.w(TAG, "startForeground with TYPE_CAMERA fallback: ${e.localizedMessage}")
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    /**
     * Membuat Notification Channel untuk Foreground Service dan Indikasi Kelelahan.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // 1. Channel Foreground Service (LOW importance agar tidak bersuara)
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifikasi status pemantauan berkala kondisi mata MIND DRIJI"
                setShowBadge(false)
            }
            notificationManager?.createNotificationChannel(serviceChannel)

            // 2. Channel Indikasi Kondisi Mata (DEFAULT importance)
            val fatigueChannel = NotificationChannel(
                FATIGUE_CHANNEL_ID,
                FATIGUE_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Pengingat kesehatan & kebiasaan istirahat mata MIND DRIJI"
                setShowBadge(true)
            }
            notificationManager?.createNotificationChannel(fatigueChannel)
        }
    }

    /**
     * Membangun notifikasi foreground persisten.
     */
    private fun buildForegroundNotification(title: String, content: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/eye-monitoring")
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            pendingIntentFlags
        )

        val smallIcon = R.mipmap.ic_launcher

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(smallIcon)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    /**
     * Memperbarui teks notifikasi foreground yang sedang berjalan.
     */
    private fun updateForegroundNotification(title: String, content: String) {
        val notification = buildForegroundNotification(title, content)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.notify(NOTIFICATION_ID, notification)
    }

    /**
     * Memulai scheduler periodic camera sampling dengan guard anti-duplicate.
     */
    private fun startScheduler(runImmediate: Boolean) {
        if (isSchedulerRunning && !runImmediate) {
            Log.d(TAG, "Scheduler already active, skipping start")
            return
        }

        handler.removeCallbacks(sessionRunner)
        isSchedulerRunning = true

        if (runImmediate) {
            Log.d(TAG, "Scheduling initial camera session immediately")
            handler.post(sessionRunner)
        } else {
            Log.d(TAG, "Scheduling next session in ${intervalMillis / 1000} seconds")
            handler.postDelayed(sessionRunner, intervalMillis)
        }
    }

    /**
     * Menjalankan 1 sesi sampling kamera (±1 menit).
     */
    private fun runCameraSession() {
        if (!isServiceRunning) {
            Log.d(TAG, "Service is not running, skipping session")
            return
        }

        // Guard: duplicate session running
        if (isSessionRunning) {
            Log.w(TAG, "Camera session already running, skipping duplicate start")
            return
        }

        isSessionRunning = true
        Log.d(TAG, "Starting camera sampling session for $sessionDurationMillis ms")

        // 1. Update status notifikasi: kamera aktif
        updateForegroundNotification(
            title = "Sedang Memantau",
            content = "Kamera aktif untuk pemantauan mata."
        )

        // 2. Ambil WakeLock selama sampling agar CPU tidak tidur saat deep sleep
        try {
            wakeLock?.acquire(sessionDurationMillis + 15000L)
        } catch (e: Exception) {
            Log.w(TAG, "WakeLock acquire error: ${e.localizedMessage}")
        }

        // 3. Hubungkan event sink realtime jika tersedia
        val mgr = eyeMonitoringManager ?: EyeMonitoringManager(applicationContext).also { eyeMonitoringManager = it }
        mgr.eventSink = eventSink

        // 4. Nyalakan CameraX front camera terikat ke LifecycleOwner Service
        mgr.startMonitoring(this) { success, errorMsg ->
            if (!success) {
                Log.e(TAG, "Failed to start camera in foreground service: $errorMsg")
                isSessionRunning = false
                releaseWakeLockSafely()
                updateForegroundNotification(
                    title = "Monitoring Mata Aktif",
                    content = "MIND DRIJI sedang memantau kondisi mata secara berkala."
                )
                // Jadwalkan sesi berikutnya
                scheduleNextSession()
                return@startMonitoring
            }

            Log.d(TAG, "CameraX sampling running successfully")

            // 5. Jadwalkan penghentian kamera setelah sessionDurationMillis (default 1 menit)
            handler.removeCallbacks(sessionStopper)
            handler.postDelayed(sessionStopper, sessionDurationMillis)
        }
    }

    /**
     * Menghentikan sesi kamera, melepaskan hardware, menyimpan hasil sesi, dan menganalisis kelelahan.
     */
    private fun stopCameraSession(reason: String) {
        if (!isSessionRunning) return

        handler.removeCallbacks(sessionStopper)
        isSessionRunning = false
        releaseWakeLockSafely()

        Log.d(TAG, "Stopping camera session (reason: $reason)")

        // 1. Matikan kamera & lepaskan resource CameraX + MediaPipe
        val mgr = eyeMonitoringManager
        val rawSummary = mgr?.stopMonitoring() ?: emptyMap()

        // 2. Kembalikan notifikasi foreground ke standby
        updateForegroundNotification(
            title = "Monitoring Mata Aktif",
            content = "MIND DRIJI sedang memantau kondisi mata secara berkala."
        )

        // 3. Masukkan userId dan deviceId ke summary
        val finalSummary = HashMap<String, Any>(rawSummary).apply {
            put("userId", userId)
            put("deviceId", deviceId)
        }

        // 4. Simpan ke persistent SharedPreferences queue agar tidak hilang jika koneksi/app tertutup
        EyeMonitoringSessionQueue.enqueueSession(applicationContext, finalSummary)

        // 5. Analisis indikator mata lelah & kirim notifikasi jika terindikasi
        evaluateEyeFatigueIndication(finalSummary)

        // 6. Teruskan event session_finished ke Flutter jika sedang terhubung
        val sink = eventSink
        if (sink != null) {
            handler.post {
                try {
                    val flutterEvent = HashMap<String, Any>(finalSummary).apply {
                        put("type", "session_finished")
                        put("isMonitoring", false)
                        put("statusMessage", "Pemantauan selesai")
                    }
                    sink.success(flutterEvent)
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to dispatch session_finished: ${e.localizedMessage}")
                }
            }
        }

        // 7. Jadwalkan interval berikutnya jika service masih aktif
        if (isServiceRunning) {
            scheduleNextSession()
        }
    }

    private fun scheduleNextSession() {
        handler.removeCallbacks(sessionRunner)
        Log.d(TAG, "Scheduling next session in ${intervalMillis / 1000} seconds")
        handler.postDelayed(sessionRunner, intervalMillis)
    }

    /**
     * Menganalisis kondisi mata dari data sesi dan mengirim notifikasi jika terindikasi kelelahan/kantuk.
     * Menggunakan bahasa non-medis yang berorientasi kebiasaan / digital wellness.
     */
    private fun evaluateEyeFatigueIndication(summary: Map<String, Any>) {
        val durationMillis = (summary["durationMillis"] as? Number)?.toLong() ?: 0L
        if (durationMillis < 10000L) {
            // Sesi terlalu pendek untuk evaluasi yang reliabel
            return
        }

        val eyeClosureEvents = (summary["eyeClosureEvents"] as? Number)?.toInt() ?: 0
        val averageEar = (summary["averageEar"] as? Number)?.toDouble() ?: 0.0

        // Threshold evaluasi teknis kebiasaan mata (bukan diagnosa medis)
        val isPotentialDrowsiness = eyeClosureEvents >= 4
        val isPotentialFatigue = eyeClosureEvents in 2..3 || (averageEar < 0.22 && averageEar > 0.0)

        if (!isPotentialDrowsiness && !isPotentialFatigue) {
            return
        }

        // Periksa cooldown agar tidak spam notifikasi
        val now = System.currentTimeMillis()
        if (now - lastFatigueNotificationTime < fatigueCooldownMillis) {
            Log.d(TAG, "Fatigue notification throttled by cooldown (${(now - lastFatigueNotificationTime)/1000}s elapsed)")
            return
        }

        lastFatigueNotificationTime = now

        val title = "Indikasi Kondisi Mata"
        val message = if (isPotentialDrowsiness) {
            "Kamu mungkin mulai mengantuk. Coba istirahat sejenak untuk menyegarkan mata."
        } else {
            "Terlihat indikasi mata mulai lelah. Disarankan mengistirahatkan pandangan sejenak."
        }

        sendFatigueNotification(title, message)
    }

    private fun sendFatigueNotification(title: String, message: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/eye-monitoring")
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
            launchIntent,
            pendingIntentFlags
        )

        val notification = NotificationCompat.Builder(this, FATIGUE_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.notify(FATIGUE_NOTIFICATION_ID, notification)
        Log.d(TAG, "Sent fatigue notification: $message")
    }

    /**
     * Mematikan service secara total:
     * - Membatalkan scheduler
     * - Menghentikan kamera jika aktif
     * - Melepaskan resource CameraX & MediaPipe
     * - Menghilangkan persistent notification
     * - Menghentikan service process
     */
    private fun stopServiceTotal() {
        isServiceRunning = false
        isSchedulerRunning = false

        handler.removeCallbacksAndMessages(null)

        if (isSessionRunning) {
            stopCameraSession("service_stopped")
        }

        eyeMonitoringManager?.releaseResources()
        releaseWakeLockSafely()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(NOTIFICATION_ID)

        stopSelf()
        Log.d(TAG, "EyeMonitoringForegroundService completely stopped")
    }

    private fun releaseWakeLockSafely() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing WakeLock: ${e.localizedMessage}")
        }
    }

    override fun onDestroy() {
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_PAUSE)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_STOP)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)

        stopServiceTotal()
        super.onDestroy()
        Log.d(TAG, "EyeMonitoringForegroundService onDestroy")
    }
}

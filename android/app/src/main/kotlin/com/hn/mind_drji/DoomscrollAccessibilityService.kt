package com.hn.mind_drji

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager
import android.widget.Toast
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Konfigurasi terpusat untuk target aplikasi Doomscroll Monitoring.
 * Dirancang modular, configurable, dan mendukung berbagai varian package regional/global.
 */
object DoomscrollConfig {
    const val TAG = "MIND_DRIJI_DOOMSCROLL"
    const val INACTIVITY_TIMEOUT_MS = 60_000L // 60 detik timeout ketidakaktifan
    private const val PREFS_TARGET_APPS = "minddriji_target_apps"
    private const val KEY_CUSTOM_APPS = "custom_packages_json"

    private val defaultPackagesMap = mapOf(
        "com.ss.android.ugc.trill" to "TikTok",             // TikTok SEA / Indonesia
        "com.zhiliaoapp.musically" to "TikTok",             // TikTok Global
        "com.zhiliaoapp.musically.go" to "TikTok Lite",      // TikTok Lite
        "com.ss.android.ugc.aweme" to "TikTok",             // TikTok / Douyin
        "com.instagram.android" to "Instagram",             // Instagram
        "com.instagram.lite" to "Instagram Lite",           // Instagram Lite
        "com.google.android.youtube" to "YouTube",          // YouTube
        "com.snapchat.android" to "Snapchat",               // Snapchat
        "com.twitter.android" to "X (Twitter)",             // X / Twitter
        "com.facebook.katana" to "Facebook",               // Facebook
        "com.facebook.lite" to "Facebook Lite"              // Facebook Lite
    )

    // ConcurrentHashMap agar thread-safe dan dapat dikonfigurasi dinamis
    private val targetPackagesMap = ConcurrentHashMap<String, String>(defaultPackagesMap)

    val TARGET_PACKAGES: Map<String, String>
        get() = targetPackagesMap

    fun getAppName(packageName: String): String {
        return targetPackagesMap[packageName] ?: packageName
    }

    fun isTargetPackage(packageName: String?): Boolean {
        if (packageName == null) return false
        return targetPackagesMap.containsKey(packageName)
    }

    fun addTargetPackage(packageName: String, appName: String) {
        targetPackagesMap[packageName] = appName
        Log.d(TAG, "Added target package: $packageName ($appName)")
    }

    fun loadTargetPackages(context: Context): Map<String, String> {
        try {
            val prefs = context.getSharedPreferences(PREFS_TARGET_APPS, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString(KEY_CUSTOM_APPS, null)
            if (!jsonStr.isNullOrEmpty()) {
                val json = JSONObject(jsonStr)
                targetPackagesMap.clear()
                val keys = json.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    targetPackagesMap[key] = json.getString(key)
                }
                Log.d(TAG, "Loaded custom target packages: ${targetPackagesMap.size} apps")
            } else {
                targetPackagesMap.clear()
                targetPackagesMap.putAll(defaultPackagesMap)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Gagal memuat custom target packages: ${e.localizedMessage}")
        }
        return targetPackagesMap
    }

    fun saveTargetPackages(context: Context, packages: Map<String, String>) {
        try {
            targetPackagesMap.clear()
            targetPackagesMap.putAll(packages)
            val json = JSONObject(packages)
            context.getSharedPreferences(PREFS_TARGET_APPS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_CUSTOM_APPS, json.toString())
                .apply()
            Log.d(TAG, "Saved custom target packages: ${packages.size} apps")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menyimpan custom target packages: ${e.localizedMessage}")
        }
    }

    fun resetToDefaults(context: Context) {
        try {
            targetPackagesMap.clear()
            targetPackagesMap.putAll(defaultPackagesMap)
            context.getSharedPreferences(PREFS_TARGET_APPS, Context.MODE_PRIVATE)
                .edit()
                .remove(KEY_CUSTOM_APPS)
                .apply()
            Log.d(TAG, "Reset target packages to defaults")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal reset custom target packages: ${e.localizedMessage}")
        }
    }
}

/**
 * Pengelola antrean native persisten untuk menyimpan sesi doomscroll
 * sebelum diambil oleh Flutter via MethodChannel.
 * Menggunakan SharedPreferences secara thread-safe.
 */
object DoomscrollSessionQueue {
    private const val PREFS_NAME = "minddriji_doomscroll_queue"
    private const val KEY_SESSIONS = "pending_sessions_json"
    private val lock = Any()

    fun enqueueSession(context: Context, session: Map<String, Any>) {
        synchronized(lock) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val currentJson = prefs.getString(KEY_SESSIONS, "[]") ?: "[]"
                val jsonArray = try {
                    JSONArray(currentJson)
                } catch (e: Exception) {
                    JSONArray()
                }

                val jsonObject = JSONObject()
                for ((key, value) in session) {
                    jsonObject.put(key, value)
                }
                jsonArray.put(jsonObject)

                val saved = prefs.edit().putString(KEY_SESSIONS, jsonArray.toString()).commit()
                Log.d(
                    DoomscrollConfig.TAG,
                    "NATIVE QUEUE SAVE: id=${session["id"]} package=${session["packageName"]} totalQueued=${jsonArray.length()} saved=$saved"
                )
            } catch (e: Exception) {
                Log.e(DoomscrollConfig.TAG, "NATIVE QUEUE SAVE ERROR: ${e.localizedMessage}", e)
            }
        }
    }

    fun getPendingSessions(context: Context): List<Map<String, Any>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val currentJson = prefs.getString(KEY_SESSIONS, "[]") ?: "[]"
            val result = mutableListOf<Map<String, Any>>()

            try {
                val jsonArray = JSONArray(currentJson)
                for (i in 0 until jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val map = mutableMapOf<String, Any>()
                    val keys = obj.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        map[key] = obj.get(key)
                    }
                    result.add(map)
                }
                Log.d(DoomscrollConfig.TAG, "NATIVE QUEUE READ: retrieved ${result.size} sessions")
            } catch (e: Exception) {
                Log.e(DoomscrollConfig.TAG, "NATIVE QUEUE READ ERROR: ${e.localizedMessage}", e)
            }

            return result
        }
    }

    fun clearPendingSessions(context: Context): Boolean {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val cleared = prefs.edit().remove(KEY_SESSIONS).commit()
            Log.d(DoomscrollConfig.TAG, "NATIVE QUEUE CLEAR: status=$cleared")
            return cleared
        }
    }
}

/**
 * Model data sesi aktif di level native Android.
 */
data class ActiveDoomscrollSession(
    val id: String = UUID.randomUUID().toString(),
    val packageName: String,
    val appName: String,
    val startedAt: Long,
    var endedAt: Long = startedAt,
    var swipeCount: Int = 1,
    var downwardSwipeCount: Int = 0,
    var upwardSwipeCount: Int = 0,
    var lastScrollTime: Long = startedAt,
    var totalInterSwipeDelta: Long = 0L
) {
    fun toMap(): Map<String, Any> {
        val durationMillis = maxOf(0L, endedAt - startedAt)
        val avgInterSwipeMillis = if (swipeCount > 1) {
            totalInterSwipeDelta / (swipeCount - 1)
        } else {
            0L
        }

        return mapOf(
            "id" to id,
            "packageName" to packageName,
            "appName" to appName,
            "startedAt" to startedAt,
            "endedAt" to endedAt,
            "durationMillis" to durationMillis,
            "swipeCount" to swipeCount,
            "downwardSwipeCount" to downwardSwipeCount,
            "upwardSwipeCount" to upwardSwipeCount,
            "avgInterSwipeMillis" to avgInterSwipeMillis,
            "collectedAt" to System.currentTimeMillis()
        )
    }

    fun toLiveMap(type: String, isActive: Boolean): Map<String, Any> {
        val durationMillis = maxOf(0L, (if (isActive) System.currentTimeMillis() else endedAt) - startedAt)
        val avgInterSwipeMillis = if (swipeCount > 1) {
            totalInterSwipeDelta / (swipeCount - 1)
        } else {
            0L
        }

        return mapOf(
            "type" to type,
            "id" to id,
            "packageName" to packageName,
            "appName" to appName,
            "startedAt" to startedAt,
            "durationMillis" to durationMillis,
            "swipeCount" to swipeCount,
            "downwardSwipeCount" to downwardSwipeCount,
            "upwardSwipeCount" to upwardSwipeCount,
            "avgInterSwipeMillis" to avgInterSwipeMillis,
            "isActive" to isActive
        )
    }
}

/**
 * Android AccessibilityService untuk memantau behavioral scrolling pada target aplikasi.
 * PRIVASI: Service ini sama sekali TIDAK membaca isi teks, pesan, komentar, caption,
 * password, screenshot, atau konten pribadi apapun. Hanya menghitung frekuensi, interval,
 * dan arah scroll.
 */
class DoomscrollAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private var activeSession: ActiveDoomscrollSession? = null
    private var lastRecordedScrollY: Int = -1
    private var screenOffReceiver: BroadcastReceiver? = null
    private var lastForegroundPackage: String? = null

    private val inactivityRunnable = Runnable {
        Log.d(DoomscrollConfig.TAG, "INACTIVITY TIMEOUT (60s): finalizing active session")
        finalizeCurrentSession("inactivity_timeout")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        DoomscrollConfig.loadTargetPackages(applicationContext)
        Log.i(DoomscrollConfig.TAG, "[MIND_DRIJI_DOOMSCROLL] Accessibility connected")
        Log.d(DoomscrollConfig.TAG, "onServiceConnected: AccessibilityService connected and initialized")

        val focusActive = isFocusModeActive(applicationContext)
        Log.d(DoomscrollConfig.TAG, "[MIND_DRIJI_DOOMSCROLL] Current native Focus Mode active=$focusActive")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_SCROLLED or AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
            // Privasi: dilarang membaca isi konten jendela
            flags = AccessibilityServiceInfo.DEFAULT or AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            // JANGAN filter packageNames di sini agar TYPE_WINDOW_STATE_CHANGED
            // dapat mendeteksi saat pengguna beralih ke launcher atau aplikasi lain
            packageNames = null
        }
        serviceInfo = info

        // Daftarkan listener saat layar dimatikan/terkunci untuk segera merampungkan sesi
        try {
            screenOffReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                        Log.d(DoomscrollConfig.TAG, "ACTION_SCREEN_OFF: Layar mati/terkunci, finalizing active session")
                        finalizeCurrentSession("screen_off")
                    }
                }
            }
            val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
            registerReceiver(screenOffReceiver, filter)
        } catch (e: Exception) {
            Log.w(DoomscrollConfig.TAG, "Gagal mendaftarkan screenOffReceiver: ${e.localizedMessage}")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val pkgName = event.packageName?.toString() ?: return

        // 1. Lacak transisi package untuk reset debounce peluncuran baru aplikasi target
        val previousPackage = lastForegroundPackage
        if (pkgName != previousPackage) {
            lastForegroundPackage = pkgName
            // Transisi dari aplikasi non-target ke target app adalah NEW LAUNCH ATTEMPT
            // Reset debounce agar pembukaan ulang (kedua, ketiga, dst) selalu dicegat seketika!
            if (!DoomscrollConfig.isTargetPackage(previousPackage) && DoomscrollConfig.isTargetPackage(pkgName)) {
                lastBlockedAt = 0L
                Log.i(
                    DoomscrollConfig.TAG,
                    "[MIND_DRIJI_BLOCKING] NEW LAUNCH ATTEMPT: transition from $previousPackage to $pkgName -> reset debounce"
                )
            }
        }

        // 2. Active restriction: Jika target package dibuka saat intervensi aktif, cegat seketika!
        if (DoomscrollConfig.isTargetPackage(pkgName)) {
            val blocked = checkFocusModeBlocking(pkgName)
            if (blocked) {
                // Jangan lanjutkan memproses scroll event jika target app sedang dicegat
                return
            }
        }

        // 3. Jika ada sesi aktif dan paket event berbeda, pengguna telah berpindah aplikasi -> segera finalisasi sesi
        val currentSession = activeSession
        if (currentSession != null && currentSession.packageName != pkgName) {
            Log.d(
                DoomscrollConfig.TAG,
                "[MIND_DRIJI_DOOMSCROLL] Immediate package switch detected: leaving ${currentSession.packageName} to $pkgName -> finalizing session"
            )
            finalizeCurrentSession("package_changed")
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                val isTarget = DoomscrollConfig.isTargetPackage(pkgName)
                if (isTarget) {
                    Log.d(
                        DoomscrollConfig.TAG,
                        "[MIND_DRIJI_DOOMSCROLL] Target package detected: $pkgName"
                    )
                }
                if (!isTarget) return
                handleScrollEvent(event, pkgName)
            }
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                Log.d(
                    DoomscrollConfig.TAG,
                    "[MIND_DRIJI_DOOMSCROLL] TYPE_WINDOW_STATE_CHANGED: package=$pkgName"
                )
                handleWindowStateChanged(pkgName)
            }
        }
    }

    /**
     * Memproses event scroll nyata pada aplikasi target.
     */
    private fun handleScrollEvent(event: AccessibilityEvent, pkgName: String) {
        // Tampilkan soft warning jika Focus Mode aktif saat scroll terdeteksi pada target app
        checkFocusModeBlocking(pkgName)

        val now = System.currentTimeMillis()
        Log.d(
            DoomscrollConfig.TAG,
            "[MIND_DRIJI_DOOMSCROLL] packageName=$pkgName eventType=${event.eventType} scrollDetected=true timestamp=$now"
        )
        Log.d(DoomscrollConfig.TAG, "[MIND_DRIJI_DOOMSCROLL] SCROLL DETECTED")

        // Deteksi arah scroll berdasarkan scrollDeltaY jika didukung (Android 9+ / API 28+)
        var isDownward = false
        var isUpward = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val deltaY = event.scrollDeltaY
            if (deltaY > 0) {
                isDownward = true
            } else if (deltaY < 0) {
                isUpward = true
            }
        }

        // Fallback untuk deteksi arah via scrollY jika deltaY 0
        if (!isDownward && !isUpward) {
            val currentY = event.scrollY
            if (lastRecordedScrollY != -1 && currentY != -1 && currentY != lastRecordedScrollY) {
                if (currentY > lastRecordedScrollY) {
                    isDownward = true
                } else {
                    isUpward = true
                }
            }
            if (currentY != -1) {
                lastRecordedScrollY = currentY
            }
        }

        val session = activeSession
        if (session == null) {
            // Sesi baru dimulai dari scroll pertama pada aplikasi target
            val appName = DoomscrollConfig.getAppName(pkgName)
            val newSession = ActiveDoomscrollSession(
                packageName = pkgName,
                appName = appName,
                startedAt = now,
                endedAt = now,
                swipeCount = 1,
                downwardSwipeCount = if (isDownward) 1 else 0,
                upwardSwipeCount = if (isUpward) 1 else 0,
                lastScrollTime = now,
                totalInterSwipeDelta = 0L
            )
            activeSession = newSession
            Log.i(
                DoomscrollConfig.TAG,
                "[MIND_DRIJI_DOOMSCROLL] SESSION STARTED: id=${newSession.id} package=$pkgName app=$appName"
            )
            Log.d(
                DoomscrollConfig.TAG,
                "[MIND_DRIJI_DOOMSCROLL] sessionStarted=${newSession.id} swipeCount=1 downwardSwipeCount=${newSession.downwardSwipeCount} upwardSwipeCount=${newSession.upwardSwipeCount}"
            )
            Log.d(DoomscrollConfig.TAG, "[MIND_DRIJI_DOOMSCROLL] SWIPE COUNT = 1")
            sendLiveEvent(newSession.toLiveMap(type = "session_started", isActive = true))
        } else {
            if (session.packageName == pkgName) {
                // Scroll berikutnya dalam sesi dan paket yang sama
                val interval = now - session.lastScrollTime
                session.swipeCount++
                if (isDownward) session.downwardSwipeCount++
                if (isUpward) session.upwardSwipeCount++
                session.totalInterSwipeDelta += interval
                session.lastScrollTime = now
                session.endedAt = now
                Log.d(
                    DoomscrollConfig.TAG,
                    "[MIND_DRIJI_DOOMSCROLL] SWIPE COUNT = ${session.swipeCount} interval=${interval}ms downwardSwipeCount=${session.downwardSwipeCount} upwardSwipeCount=${session.upwardSwipeCount}"
                )
                sendLiveEvent(session.toLiveMap(type = "session_updated", isActive = true))
            } else {
                // Pengguna berpindah ke aplikasi target lain -> selesaikan sesi sebelumnya, buat sesi baru
                Log.d(
                    DoomscrollConfig.TAG,
                    "[MIND_DRIJI_DOOMSCROLL] APP SWITCH (target to target): leaving ${session.packageName} to $pkgName"
                )
                finalizeCurrentSession("switched_target_app")
                val appName = DoomscrollConfig.getAppName(pkgName)
                val newSession = ActiveDoomscrollSession(
                    packageName = pkgName,
                    appName = appName,
                    startedAt = now,
                    endedAt = now,
                    swipeCount = 1,
                    downwardSwipeCount = if (isDownward) 1 else 0,
                    upwardSwipeCount = if (isUpward) 1 else 0,
                    lastScrollTime = now,
                    totalInterSwipeDelta = 0L
                )
                activeSession = newSession
                Log.i(
                    DoomscrollConfig.TAG,
                    "[MIND_DRIJI_DOOMSCROLL] SESSION STARTED: id=${newSession.id} package=$pkgName app=$appName"
                )
                Log.d(
                    DoomscrollConfig.TAG,
                    "[MIND_DRIJI_DOOMSCROLL] sessionStarted=${newSession.id} swipeCount=1 downwardSwipeCount=${newSession.downwardSwipeCount} upwardSwipeCount=${newSession.upwardSwipeCount}"
                )
                Log.d(DoomscrollConfig.TAG, "[MIND_DRIJI_DOOMSCROLL] SWIPE COUNT = 1")
                sendLiveEvent(newSession.toLiveMap(type = "session_started", isActive = true))
            }
        }

        // Reset timer ketidakaktifan (60 detik)
        resetInactivityTimer()
    }

    private var lastBlockedAt: Long = 0L
    private var lastToastAt: Long = 0L
    private var lastWarningNotificationAt: Long = 0L

    /**
     * Menampilkan peringatan feedback (Toast) native yang aman dari background service
     * tanpa membuka Activity atau menimbulkan loop navigasi ke sistem.
     */
    fun showBlockingFeedback(appName: String) {
        val now = System.currentTimeMillis()
        if (now - lastToastAt < TOAST_THROTTLE_MS) {
            return
        }
        lastToastAt = now
        handler.post {
            try {
                Toast.makeText(
                    applicationContext,
                    "Sesi Intervensi Aktif\nAplikasi $appName dibatasi selama masa fokus / jeda.",
                    Toast.LENGTH_SHORT
                ).show()
            } catch (e: Exception) {
                Log.w(DoomscrollConfig.TAG, "Gagal menampilkan toast: ${e.localizedMessage}")
            }
        }
    }

    /**
     * Menampilkan notifikasi peringatan berprioritas tinggi (Heads-up notification)
     * dengan aksi "Lihat" yang membuka MIND DRIJI ke halaman intervensi/focus mode.
     * Aplikasi target TETAP DAPAT DIGUNAKAN jika notifikasi diabaikan.
     */
    fun showFocusWarningNotification(pkgName: String, appName: String) {
        val now = System.currentTimeMillis()
        if (now - lastWarningNotificationAt < WARNING_NOTIFICATION_THROTTLE_MS) {
            return
        }
        lastWarningNotificationAt = now

        try {
            val context = applicationContext
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    "minddriji_intervention",
                    "Intervensi MIND DRIJI",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifikasi status intervensi dan jeda digital MIND DRIJI"
                    setShowBadge(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/intervention")
            }

            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                WARNING_NOTIFICATION_ID,
                launchIntent,
                pendingIntentFlags
            )

            val notification = NotificationCompat.Builder(context, "minddriji_intervention")
                .setContentTitle("Mode Fokus Aktif")
                .setContentText("Kamu sedang menggunakan aplikasi yang dibatasi oleh sesi fokus.")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .addAction(
                    android.R.drawable.ic_menu_view,
                    "Lihat",
                    pendingIntent
                )
                .build()

            notificationManager.notify(WARNING_NOTIFICATION_ID, notification)
            Log.d(DoomscrollConfig.TAG, "FOCUS MODE: Soft warning heads-up notification sent for $pkgName ($appName)")
        } catch (e: Exception) {
            Log.w(DoomscrollConfig.TAG, "Gagal memposting notification warning: ${e.localizedMessage}")
        }
    }

    /**
     * Memeriksa apakah suatu package dikecualikan dari soft warning Focus Mode.
     * MIND DRIJI, System UI, launcher, pengaturan sistem, dan dialer tidak boleh dibatasi.
     */
    fun isExcludedPackage(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return true
        if (packageName == applicationContext.packageName) return true
        if (packageName == "com.android.systemui") return true
        if (packageName == "com.android.settings" || packageName.startsWith("com.android.settings.")) return true
        if (packageName.startsWith("com.google.android.settings")) return true
        if (packageName == "com.android.dialer" || packageName == "com.google.android.dialer" || packageName == "com.samsung.android.dialer") return true
        if (isLauncherPackage(packageName)) return true
        return false
    }

    private fun isLauncherPackage(pkgName: String): Boolean {
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
            }
            val resolveInfos = packageManager.queryIntentActivities(intent, 0)
            for (info in resolveInfos) {
                if (info.activityInfo?.packageName == pkgName) {
                    return true
                }
            }
        } catch (e: Exception) {
            // Abaikan kegagalan resolve launcher
        }
        return pkgName.contains("launcher", ignoreCase = true) || pkgName == "com.google.android.apps.nexuslauncher"
    }

    /**
     * Memeriksa dan mengeksekusi soft warning Focus Mode jika kondisi terpenuhi.
     * PENTING: Target app TETAP BOLEH TERBUKA dan TIDAK dikembalikan ke Home (GLOBAL_ACTION_HOME ditiadakan).
     */
    fun checkFocusModeBlocking(pkgName: String): Boolean {
        if (!isFocusModeActive(applicationContext)) {
            return false
        }
        if (isExcludedPackage(pkgName)) {
            if (isLauncherPackage(pkgName)) {
                lastBlockedAt = 0L
            }
            return false
        }
        if (!DoomscrollConfig.isTargetPackage(pkgName)) {
            return false
        }

        val now = System.currentTimeMillis()
        if (now - lastBlockedAt < BLOCK_DEBOUNCE_MS) {
            Log.d(DoomscrollConfig.TAG, "FOCUS MODE: Soft warning skipped by debounce (${now - lastBlockedAt}ms < ${BLOCK_DEBOUNCE_MS}ms)")
            return true
        }

        lastBlockedAt = now
        val appName = DoomscrollConfig.getAppName(pkgName)
        Log.i(DoomscrollConfig.TAG, "INTERVENTION ACTIVE: Blocking target package: $pkgName ($appName) -> Returning to Home")

        // 1. Eksekusi active restriction: Kembalikan user ke Home / hentikan akses target app
        performGlobalAction(GLOBAL_ACTION_HOME)

        // 2. Tampilkan feedback Toast
        showBlockingFeedback(appName)

        // 3. Tampilkan High-Priority Heads-up Notification dengan aksi "Lihat"
        showFocusWarningNotification(pkgName, appName)

        return true
    }

    /**
     * Memproses pergantian jendela/aplikasi. Jika pengguna keluar dari aplikasi sesi aktif,
     * selesaikan sesi tersebut. Serta periksa apakah Focus Mode aktif untuk aplikasi target.
     */
    private fun handleWindowStateChanged(pkgName: String) {
        // 1. Tampilkan soft warning jika Focus Mode sedang aktif untuk target package
        checkFocusModeBlocking(pkgName)

        // 2. Rampungkan sesi doomscrolling jika user berpindah aplikasi
        val session = activeSession ?: return
        if (session.packageName != pkgName) {
            Log.d(
                DoomscrollConfig.TAG,
                "APP SWITCH DETECTED: leaving ${session.packageName} to $pkgName -> finalizing session"
            )
            finalizeCurrentSession("left_app")
        }
    }

    private fun resetInactivityTimer() {
        handler.removeCallbacks(inactivityRunnable)
        handler.postDelayed(inactivityRunnable, DoomscrollConfig.INACTIVITY_TIMEOUT_MS)
    }

    /**
     * Menyelesaikan sesi aktif dan menyimpannya ke antrean native SharedPreferences.
     */
    @Synchronized
    fun finalizeCurrentSession(reason: String) {
        handler.removeCallbacks(inactivityRunnable)
        val session = activeSession ?: return

        // Hanya simpan sesi jika terdapat scroll nyata (swipeCount > 0)
        if (session.swipeCount > 0) {
            val sessionMap = session.toMap()
            Log.i(
                DoomscrollConfig.TAG,
                "[MIND_DRIJI_DOOMSCROLL] SESSION FINALIZED: reason=$reason id=${session.id} package=${session.packageName}"
            )
            Log.i(
                DoomscrollConfig.TAG,
                "[MIND_DRIJI_DOOMSCROLL] sessionFinished=true durationMillis=${sessionMap["durationMillis"]} swipeCount=${session.swipeCount} downwardSwipeCount=${session.downwardSwipeCount} upwardSwipeCount=${session.upwardSwipeCount} queued=true"
            )
            DoomscrollSessionQueue.enqueueSession(applicationContext, sessionMap)
            Log.i(DoomscrollConfig.TAG, "[MIND_DRIJI_DOOMSCROLL] QUEUED = true")
            sendLiveEvent(session.toLiveMap(type = "session_finished", isActive = false))
        }

        activeSession = null
        lastRecordedScrollY = -1
    }

    override fun onInterrupt() {
        Log.d(DoomscrollConfig.TAG, "onInterrupt: service interrupted")
        finalizeCurrentSession("service_interrupted")
    }

    override fun onDestroy() {
        Log.d(DoomscrollConfig.TAG, "onDestroy: service destroyed")
        finalizeCurrentSession("service_destroyed")
        try {
            if (screenOffReceiver != null) {
                unregisterReceiver(screenOffReceiver)
                screenOffReceiver = null
            }
        } catch (e: Exception) {
            Log.w(DoomscrollConfig.TAG, "Gagal melepas screenOffReceiver: ${e.localizedMessage}")
        }
        instance = null
        super.onDestroy()
    }

    companion object {
        var instance: DoomscrollAccessibilityService? = null

        @Volatile
        var eventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        fun sendLiveEvent(eventMap: Map<String, Any>) {
            val sink = eventSink ?: return
            Handler(Looper.getMainLooper()).post {
                try {
                    sink.success(eventMap)
                    Log.d(DoomscrollConfig.TAG, "LIVE EVENT DISPATCHED: type=${eventMap["type"]} swipes=${eventMap["swipeCount"]}")
                } catch (e: Exception) {
                    Log.e(DoomscrollConfig.TAG, "LIVE EVENT DISPATCH ERROR: ${e.localizedMessage}")
                }
            }
        }

        /**
         * Memeriksa apakah accessibility service MIND DRIJI sedang aktif di pengaturan Android.
         * Menggunakan AccessibilityManager resmi Android sebagai pemeriksaan primer,
         * dengan Settings.Secure sebagai fallback sekunder.
         */
        fun isServiceEnabled(context: Context): Boolean {
            // 1. Pemeriksaan primer via AccessibilityManager API resmi
            try {
                val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
                if (am != null) {
                    val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                    for (enabledService in enabledServices) {
                        val sInfo = enabledService.resolveInfo?.serviceInfo
                        if (sInfo != null && sInfo.packageName == context.packageName &&
                            (sInfo.name == DoomscrollAccessibilityService::class.java.name ||
                             sInfo.name.contains(DoomscrollAccessibilityService::class.java.simpleName))
                        ) {
                            return true
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w(DoomscrollConfig.TAG, "AccessibilityManager check error: ${e.localizedMessage}")
            }

            // 2. Pemeriksaan sekunder via Settings.Secure fallback
            val expectedComponentName = ComponentName(context, DoomscrollAccessibilityService::class.java)
            val enabledServicesSetting = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServicesSetting)

            while (colonSplitter.hasNext()) {
                val componentNameString = colonSplitter.next()
                val enabledComponent = ComponentName.unflattenFromString(componentNameString)
                if (enabledComponent != null && enabledComponent == expectedComponentName) {
                    return true
                }
                if (componentNameString.contains(context.packageName) &&
                    componentNameString.contains(DoomscrollAccessibilityService::class.java.simpleName)
                ) {
                    return true
                }
            }
            return false
        }

        const val PREFS_INTERVENTION = "minddriji_intervention_prefs"
        const val NOTIFICATION_ID = 3001
        const val WARNING_NOTIFICATION_ID = 3002
        const val BLOCK_DEBOUNCE_MS = 1500L
        const val TOAST_THROTTLE_MS = 2500L
        const val WARNING_NOTIFICATION_THROTTLE_MS = 5000L

        /**
         * Memeriksa apakah Focus Mode sedang aktif berdasarkan timestamp di SharedPreferences.
         * Jika currentTime >= endedAt, otomatis menonaktifkan state native dan membatalkan notifikasi.
         */
        fun isFocusModeActive(context: Context): Boolean {
            return try {
                val prefs = context.getSharedPreferences(PREFS_INTERVENTION, Context.MODE_PRIVATE)
                val boolActive = prefs.getBoolean("focus_mode_active", false)
                val status = prefs.getString("status", null)
                val type = prefs.getString("type", null)
                val endedAt = maxOf(
                    prefs.getLong("focus_mode_ended_at", 0L),
                    prefs.getLong("ended_at", 0L)
                )
                val now = System.currentTimeMillis()

                val isRestrictingType = (type == null || type == "focusMode" || type == "digitalBreak" || type == "pomodoro" || type == "custom")
                val isActive = boolActive || (status == "active" && isRestrictingType)

                if (isActive) {
                    if (now < endedAt) {
                        return true
                    } else {
                        // Otomatis bersihkan native state saat waktu berakhir
                        deactivateNativeFocusMode(context)
                        return false
                    }
                }
                false
            } catch (e: Exception) {
                Log.w(DoomscrollConfig.TAG, "Gagal memeriksa status Focus Mode: ${e.localizedMessage}")
                false
            }
        }

        /**
         * Membersihkan state native Focus Mode dan membatalkan notifikasi intervensi.
         */
        fun deactivateNativeFocusMode(context: Context) {
            try {
                val prefs = context.getSharedPreferences(PREFS_INTERVENTION, Context.MODE_PRIVATE)
                prefs.edit()
                    .putString("status", "inactive")
                    .putBoolean("focus_mode_active", false)
                    .putLong("focus_mode_ended_at", 0L)
                    .apply()

                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                notificationManager?.cancel(NOTIFICATION_ID)
                Log.i(DoomscrollConfig.TAG, "FOCUS MODE: Native state deactivated & notification cleared automatically")
            } catch (e: Exception) {
                Log.w(DoomscrollConfig.TAG, "Gagal deaktifasi native Focus Mode: ${e.localizedMessage}")
            }
        }

        /**
         * Meminta service aktif untuk menyelesaikan sesi saat ini (flush) ke antrean native.
         */
        fun flushActiveSession(context: Context) {
            Log.d(DoomscrollConfig.TAG, "flushActiveSession called: instance=${instance != null}")
            instance?.finalizeCurrentSession("manual_flush")
        }
    }
}

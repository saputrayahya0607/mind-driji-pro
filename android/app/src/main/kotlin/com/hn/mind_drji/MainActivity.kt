package com.hn.mind_drji

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val USAGE_STATS_CHANNEL = "com.hn.minddriji/usage_stats"
    private val DOOMSCROLL_CHANNEL = "com.hn.minddriji/doomscroll"
    private val DOOMSCROLL_EVENTS_CHANNEL = "com.hn.minddriji/doomscroll_events"
    private val EYE_MONITORING_CHANNEL = "com.hn.minddriji/eye_monitoring"
    private val EYE_MONITORING_EVENTS_CHANNEL = "com.hn.minddriji/eye_monitoring_events"
    private val DEVICE_INFO_CHANNEL = "com.hn.minddriji/device_info"
    private val INTERVENTION_CHANNEL = "com.hn.minddriji/intervention"
    private val INTERVENTION_EVENTS_CHANNEL = "com.hn.minddriji/intervention_events"
    private val INTERVENTION_PREFS = "minddriji_intervention_prefs"
    private val INTERVENTION_NOTIFICATION_CHANNEL = "minddriji_intervention"
    private val INTERVENTION_NOTIFICATION_ID = 3001
    private var interventionEventSink: EventChannel.EventSink? = null

    private var eyeMonitoringManager: EyeMonitoringManager? = null
    private val CAMERA_PERMISSION_REQUEST_CODE = 1002
    private var pendingCameraPermissionResult: MethodChannel.Result? = null
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1003
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    override fun onResume() {
        super.onResume()
        android.util.Log.d(DoomscrollConfig.TAG, "[MIND_DRIJI_DOOMSCROLL] MainActivity onResume -> flushActiveSession")
        try {
            DoomscrollAccessibilityService.flushActiveSession(this)
        } catch (e: Exception) {
            android.util.Log.w(DoomscrollConfig.TAG, "Gagal flush active doomscroll session di onResume: ${e.localizedMessage}")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_STATS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsageAccess" -> {
                    try {
                        val hasAccess = hasUsageStatsPermission()
                        result.success(hasAccess)
                    } catch (e: Exception) {
                        result.error("PERMISSION_CHECK_ERROR", e.localizedMessage, null)
                    }
                }
                "openUsageAccessSettings" -> {
                    try {
                        val opened = openUsageAccessSettings()
                        result.success(opened)
                    } catch (e: Exception) {
                        result.error("OPEN_SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                "getTodayUsage" -> {
                    try {
                        val hasAccess = hasUsageStatsPermission()
                        val startArg = (call.argument<Number>("startTime"))?.toLong()
                        val endArg = (call.argument<Number>("endTime"))?.toLong()
                        val data = getTodayUsage(startArg, endArg)
                        val totalMillis = (data["totalUsageMillis"] as? Long) ?: 0L
                        val apps = (data["apps"] as? List<*>) ?: emptyList<Any>()

                        if (totalMillis > 0 || apps.isNotEmpty() || hasAccess) {
                            result.success(data)
                        } else {
                            result.error("NO_USAGE_ACCESS", "Usage access permission has not been granted", null)
                        }
                    } catch (e: Exception) {
                        result.error("QUERY_USAGE_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOOMSCROLL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAccessibilityService" -> {
                    try {
                        val isEnabled = DoomscrollAccessibilityService.isServiceEnabled(this)
                        android.util.Log.d(DoomscrollConfig.TAG, "MethodChannel checkAccessibilityService -> $isEnabled")
                        result.success(isEnabled)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel checkAccessibilityService error: ${e.localizedMessage}")
                        result.error("CHECK_ACCESSIBILITY_ERROR", e.localizedMessage, null)
                    }
                }
                "openAccessibilitySettings" -> {
                    try {
                        android.util.Log.d(DoomscrollConfig.TAG, "MethodChannel openAccessibilitySettings")
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivity(intent)
                            result.success(true)
                        } else {
                            val fallbackIntent = Intent(Settings.ACTION_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(fallbackIntent)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel openAccessibilitySettings error: ${e.localizedMessage}")
                        result.error("OPEN_SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                "getPendingDoomscrollSessions" -> {
                    try {
                        DoomscrollAccessibilityService.flushActiveSession(this)
                        val sessions = DoomscrollSessionQueue.getPendingSessions(this)
                        android.util.Log.d(DoomscrollConfig.TAG, "MethodChannel getPendingDoomscrollSessions -> returning ${sessions.size} sessions")
                        result.success(sessions)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel getPendingDoomscrollSessions error: ${e.localizedMessage}")
                        result.error("GET_SESSIONS_ERROR", e.localizedMessage, null)
                    }
                }
                "clearPendingDoomscrollSessions" -> {
                    try {
                        val cleared = DoomscrollSessionQueue.clearPendingSessions(this)
                        android.util.Log.d(DoomscrollConfig.TAG, "MethodChannel clearPendingDoomscrollSessions -> cleared=$cleared")
                        result.success(cleared)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel clearPendingDoomscrollSessions error: ${e.localizedMessage}")
                        result.error("CLEAR_SESSIONS_ERROR", e.localizedMessage, null)
                    }
                }
                "flushCurrentDoomscrollSession" -> {
                    try {
                        DoomscrollAccessibilityService.flushActiveSession(this)
                        val sessions = DoomscrollSessionQueue.getPendingSessions(this)
                        android.util.Log.d(DoomscrollConfig.TAG, "MethodChannel flushCurrentDoomscrollSession -> returning ${sessions.size} sessions")
                        result.success(sessions)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel flushCurrentDoomscrollSession error: ${e.localizedMessage}")
                        result.error("FLUSH_SESSION_ERROR", e.localizedMessage, null)
                    }
                }
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
                        val appList = mutableListOf<Map<String, Any>>()
                        val seenPackages = mutableSetOf<String>()

                        for (info in resolveInfos) {
                            val pkg = info.activityInfo.packageName
                            if (pkg == packageName || seenPackages.contains(pkg)) continue
                            seenPackages.add(pkg)

                            val appName = try {
                                info.loadLabel(pm).toString()
                            } catch (e: Exception) {
                                pkg
                            }
                            val isMonitored = DoomscrollConfig.isTargetPackage(pkg)
                            appList.add(mapOf(
                                "packageName" to pkg,
                                "appName" to appName,
                                "isMonitored" to isMonitored
                            ))
                        }
                        appList.sortBy { (it["appName"] as String).lowercase() }
                        result.success(appList)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel getInstalledApps error: ${e.localizedMessage}")
                        result.error("GET_INSTALLED_APPS_ERROR", e.localizedMessage, null)
                    }
                }
                "getTargetPackages" -> {
                    try {
                        val targets = DoomscrollConfig.loadTargetPackages(this)
                        val list = targets.map { entry ->
                            mapOf(
                                "packageName" to entry.key,
                                "appName" to entry.value,
                                "isMonitored" to true
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel getTargetPackages error: ${e.localizedMessage}")
                        result.error("GET_TARGET_PACKAGES_ERROR", e.localizedMessage, null)
                    }
                }
                "saveTargetPackages" -> {
                    try {
                        val rawList = call.argument<List<Map<String, Any>>>("targetApps") ?: emptyList()
                        val newMap = mutableMapOf<String, String>()
                        for (item in rawList) {
                            val pkg = item["packageName"] as? String ?: continue
                            val name = item["appName"] as? String ?: pkg
                            val isMonitored = item["isMonitored"] as? Boolean ?: true
                            if (isMonitored) {
                                newMap[pkg] = name
                            }
                        }
                        DoomscrollConfig.saveTargetPackages(this, newMap)
                        android.util.Log.d(DoomscrollConfig.TAG, "MethodChannel saveTargetPackages -> saved ${newMap.size} packages")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel saveTargetPackages error: ${e.localizedMessage}")
                        result.error("SAVE_TARGET_PACKAGES_ERROR", e.localizedMessage, null)
                    }
                }
                "resetTargetPackagesToDefault" -> {
                    try {
                        DoomscrollConfig.resetToDefaults(this)
                        val targets = DoomscrollConfig.TARGET_PACKAGES
                        val list = targets.map { entry ->
                            mapOf(
                                "packageName" to entry.key,
                                "appName" to entry.value,
                                "isMonitored" to true
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        android.util.Log.e(DoomscrollConfig.TAG, "MethodChannel resetTargetPackagesToDefault error: ${e.localizedMessage}")
                        result.error("RESET_TARGET_PACKAGES_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DOOMSCROLL_EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    android.util.Log.d(DoomscrollConfig.TAG, "EventChannel doomscroll_events onListen registered")
                    DoomscrollAccessibilityService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    android.util.Log.d(DoomscrollConfig.TAG, "EventChannel doomscroll_events onCancel")
                    DoomscrollAccessibilityService.eventSink = null
                }
            })

        eyeMonitoringManager = EyeMonitoringManager(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EYE_MONITORING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkCameraPermission" -> {
                    result.success(hasCameraPermission())
                }
                "requestCameraPermission" -> {
                    requestCameraPermission(result)
                }
                "checkNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = androidx.core.content.ContextCompat.checkSelfPermission(
                            this,
                            android.Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    } else {
                        result.success(true)
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (androidx.core.content.ContextCompat.checkSelfPermission(
                                this,
                                android.Manifest.permission.POST_NOTIFICATIONS
                            ) == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        pendingNotificationPermissionResult = result
                        androidx.core.app.ActivityCompat.requestPermissions(
                            this,
                            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                            NOTIFICATION_PERMISSION_REQUEST_CODE
                        )
                    } else {
                        result.success(true)
                    }
                }
                "startForegroundService" -> {
                    if (!hasCameraPermission()) {
                        result.error("CAMERA_PERMISSION_DENIED", "Izin kamera belum diberikan", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intervalMs = (call.argument<Number>("intervalMillis"))?.toLong() ?: (30 * 60 * 1000L)
                        val sessionDurationMs = (call.argument<Number>("sessionDurationMillis"))?.toLong() ?: (60 * 1000L)
                        val userId = call.argument<String>("userId") ?: "local_user"
                        val deviceId = call.argument<String>("deviceId") ?: "unknown_device"
                        val immediate = call.argument<Boolean>("runImmediate") ?: true

                        val serviceIntent = Intent(this, EyeMonitoringForegroundService::class.java).apply {
                            action = EyeMonitoringForegroundService.ACTION_START_SERVICE
                            putExtra(EyeMonitoringForegroundService.EXTRA_INTERVAL_MS, intervalMs)
                            putExtra(EyeMonitoringForegroundService.EXTRA_SESSION_DURATION_MS, sessionDurationMs)
                            putExtra(EyeMonitoringForegroundService.EXTRA_USER_ID, userId)
                            putExtra(EyeMonitoringForegroundService.EXTRA_DEVICE_ID, deviceId)
                            putExtra(EyeMonitoringForegroundService.EXTRA_IMMEDIATE_SESSION, immediate)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_FOREGROUND_SERVICE_ERROR", e.localizedMessage, null)
                    }
                }
                "stopForegroundService" -> {
                    try {
                        val serviceIntent = Intent(this, EyeMonitoringForegroundService::class.java).apply {
                            action = EyeMonitoringForegroundService.ACTION_STOP_SERVICE
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_FOREGROUND_SERVICE_ERROR", e.localizedMessage, null)
                    }
                }
                "getPendingSessions" -> {
                    try {
                        val sessions = EyeMonitoringSessionQueue.getPendingSessions(this)
                        result.success(sessions)
                    } catch (e: Exception) {
                        result.error("GET_PENDING_SESSIONS_ERROR", e.localizedMessage, null)
                    }
                }
                "clearPendingSessions" -> {
                    try {
                        val cleared = EyeMonitoringSessionQueue.clearPendingSessions(this)
                        result.success(cleared)
                    } catch (e: Exception) {
                        result.error("CLEAR_PENDING_SESSIONS_ERROR", e.localizedMessage, null)
                    }
                }
                "isForegroundServiceRunning" -> {
                    result.success(EyeMonitoringForegroundService.isServiceRunning)
                }
                "startMonitoring" -> {
                    if (!hasCameraPermission()) {
                        result.error("CAMERA_PERMISSION_DENIED", "Izin kamera belum diberikan", null)
                        return@setMethodCallHandler
                    }
                    eyeMonitoringManager?.startMonitoring(this) { success, errorMsg ->
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("START_MONITORING_ERROR", errorMsg ?: "Gagal memulai monitoring", null)
                        }
                    }
                }
                "stopMonitoring" -> {
                    val summary = eyeMonitoringManager?.stopMonitoring() ?: emptyMap<String, Any>()
                    result.success(summary)
                }
                "getStatus" -> {
                    val isMon = eyeMonitoringManager?.isMonitoring ?: false
                    val isSvc = EyeMonitoringForegroundService.isServiceRunning
                    val isSess = EyeMonitoringForegroundService.isSessionRunning
                    result.success(mapOf(
                        "isMonitoring" to (isMon || isSess),
                        "isServiceRunning" to isSvc,
                        "isSessionRunning" to isSess
                    ))
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EYE_MONITORING_EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    android.util.Log.d(EyeMonitoringManager.TAG, "EventChannel eye_monitoring_events onListen registered")
                    eyeMonitoringManager?.eventSink = events
                    EyeMonitoringForegroundService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    android.util.Log.d(EyeMonitoringManager.TAG, "EventChannel eye_monitoring_events onCancel")
                    eyeMonitoringManager?.eventSink = null
                    EyeMonitoringForegroundService.eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_INFO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    try {
                        val packageInfo = try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, 0)
                            }
                        } catch (e: Exception) {
                            null
                        }

                        val manufacturer = Build.MANUFACTURER ?: "Unknown"
                        val model = Build.MODEL ?: "Unknown"
                        val deviceName = if (model.startsWith(manufacturer, ignoreCase = true)) {
                            model
                        } else {
                            "$manufacturer $model"
                        }

                        val info = mapOf(
                            "deviceName" to deviceName,
                            "manufacturer" to manufacturer,
                            "model" to model,
                            "androidVersion" to (Build.VERSION.RELEASE ?: "Unknown"),
                            "appVersion" to (packageInfo?.versionName ?: "1.0.0")
                        )
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("DEVICE_INFO_ERROR", e.localizedMessage, null)
                    }
                }
                "checkBatteryOptimization" -> {
                    try {
                        val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                            powerManager?.isIgnoringBatteryOptimizations(packageName) ?: true
                        } else {
                            true
                        }
                        result.success(isIgnoring)
                    } catch (e: Exception) {
                        result.error("CHECK_BATTERY_OPT_ERROR", e.localizedMessage, null)
                    }
                }
                "requestIgnoreBatteryOptimization" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(fallbackIntent)
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("REQUEST_BATTERY_OPT_ERROR", e.localizedMessage, null)
                    }
                }
                "openOemAutoStartSettings" -> {
                    try {
                        val manufacturer = Build.MANUFACTURER.lowercase()
                        val intents = mutableListOf<Intent>()

                        when {
                            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") || manufacturer.contains("poco") -> {
                                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")))
                                intents.add(Intent("miui.intent.action.OP_AUTO_START").addCategory(Intent.CATEGORY_DEFAULT))
                            }
                            manufacturer.contains("oppo") || manufacturer.contains("realme") -> {
                                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                                intents.add(Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")))
                                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")))
                            }
                            manufacturer.contains("vivo") || manufacturer.contains("iqoo") -> {
                                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                                intents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")))
                                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")))
                            }
                            manufacturer.contains("samsung") -> {
                                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")))
                                intents.add(Intent().setComponent(ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity")))
                            }
                            manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")))
                                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
                            }
                            manufacturer.contains("asus") -> {
                                intents.add(Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.entry.FunctionActivity")))
                                intents.add(Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity")))
                            }
                        }

                        intents.add(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        })

                        var launched = false
                        for (intent in intents) {
                            try {
                                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                if (intent.resolveActivity(packageManager) != null) {
                                    startActivity(intent)
                                    launched = true
                                    break
                                }
                            } catch (_: Exception) {}
                        }

                        if (!launched) {
                            val generalSettingsIntent = Intent(Settings.ACTION_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(generalSettingsIntent)
                            launched = true
                        }
                        result.success(launched)
                    } catch (e: Exception) {
                        result.error("OPEN_OEM_SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTERVENTION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startDigitalBreak" -> {
                    try {
                        val id = call.argument<String>("id") ?: ("break_" + System.currentTimeMillis())
                        val durationMinutes = (call.argument<Number>("durationMinutes"))?.toInt() ?: 15
                        val endTimestamp = (call.argument<Number>("endTimestampMillis"))?.toLong() ?: (System.currentTimeMillis() + durationMinutes * 60 * 1000L)
                        val startedAt = System.currentTimeMillis()

                        val prefs = getSharedPreferences(INTERVENTION_PREFS, Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("active_id", id)
                            .putString("type", "digitalBreak")
                            .putString("title", "Jeda Digital")
                            .putInt("duration_minutes", durationMinutes)
                            .putLong("started_at", startedAt)
                            .putLong("ended_at", endTimestamp)
                            .putString("status", "active")
                            .putBoolean("focus_mode_active", true)
                            .putLong("focus_mode_ended_at", endTimestamp)
                            .remove("cancelled_at")
                            .apply()

                        showInterventionNotification(
                            "Jeda Digital Aktif",
                            "Berikan jeda sejenak dari layar."
                        )

                        interventionEventSink?.success(mapOf(
                            "event" to "started",
                            "id" to id,
                            "type" to "digitalBreak"
                        ))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_DIGITAL_BREAK_ERROR", e.localizedMessage, null)
                    }
                }
                "stopDigitalBreak" -> {
                    try {
                        val prefs = getSharedPreferences(INTERVENTION_PREFS, Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("status", "inactive")
                            .putBoolean("focus_mode_active", false)
                            .putLong("focus_mode_ended_at", 0L)
                            .remove("cancelled_at")
                            .apply()

                        cancelInterventionNotification()

                        interventionEventSink?.success(mapOf(
                            "event" to "stopped",
                            "type" to "digitalBreak"
                        ))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_DIGITAL_BREAK_ERROR", e.localizedMessage, null)
                    }
                }
                "startFocusMode" -> {
                    try {
                        val id = call.argument<String>("id") ?: ("focus_" + System.currentTimeMillis())
                        val durationMinutes = (call.argument<Number>("durationMinutes"))?.toInt() ?: 30
                        val endTimestamp = (call.argument<Number>("endTimestampMillis"))?.toLong() ?: (System.currentTimeMillis() + durationMinutes * 60 * 1000L)
                        val startedAt = System.currentTimeMillis()

                        val prefs = getSharedPreferences(INTERVENTION_PREFS, Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("active_id", id)
                            .putString("type", "focusMode")
                            .putString("title", "Mode Fokus")
                            .putInt("duration_minutes", durationMinutes)
                            .putLong("started_at", startedAt)
                            .putLong("ended_at", endTimestamp)
                            .putString("status", "active")
                            .putBoolean("focus_mode_active", true)
                            .putLong("focus_mode_ended_at", endTimestamp)
                            .remove("cancelled_at")
                            .apply()

                        showInterventionNotification(
                            "Focus Mode Aktif",
                            "Fokus selama $durationMinutes menit."
                        )

                        interventionEventSink?.success(mapOf(
                            "event" to "started",
                            "id" to id,
                            "type" to "focusMode"
                        ))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_FOCUS_MODE_ERROR", e.localizedMessage, null)
                    }
                }
                "stopFocusMode" -> {
                    try {
                        val prefs = getSharedPreferences(INTERVENTION_PREFS, Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("status", "inactive")
                            .putBoolean("focus_mode_active", false)
                            .putLong("focus_mode_ended_at", 0L)
                            .remove("cancelled_at")
                            .apply()

                        cancelInterventionNotification()

                        interventionEventSink?.success(mapOf(
                            "event" to "stopped",
                            "type" to "focusMode"
                        ))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_FOCUS_MODE_ERROR", e.localizedMessage, null)
                    }
                }
                "getInterventionStatus" -> {
                    try {
                        val prefs = getSharedPreferences(INTERVENTION_PREFS, Context.MODE_PRIVATE)
                        val status = prefs.getString("status", null)
                        val endedAt = if (prefs.contains("focus_mode_ended_at")) {
                            prefs.getLong("focus_mode_ended_at", 0L)
                        } else {
                            prefs.getLong("ended_at", 0L)
                        }
                        val now = System.currentTimeMillis()

                        if (status == "active" && endedAt > now) {
                            val data = mapOf(
                                "id" to (prefs.getString("active_id", "") ?: ""),
                                "type" to (prefs.getString("type", "digitalBreak") ?: "digitalBreak"),
                                "title" to (prefs.getString("title", "Jeda Digital") ?: "Jeda Digital"),
                                "durationMinutes" to prefs.getInt("duration_minutes", 15),
                                "startedAt" to java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
                                    timeZone = java.util.TimeZone.getTimeZone("UTC")
                                }.format(java.util.Date(prefs.getLong("started_at", now))),
                                "endedAt" to java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
                                    timeZone = java.util.TimeZone.getTimeZone("UTC")
                                }.format(java.util.Date(endedAt)),
                                "status" to "active",
                                "createdAt" to java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
                                    timeZone = java.util.TimeZone.getTimeZone("UTC")
                                }.format(java.util.Date(prefs.getLong("started_at", now)))
                            )
                            result.success(data)
                        } else {
                            if (status == "active" && endedAt <= now) {
                                prefs.edit()
                                    .putString("status", "inactive")
                                    .putBoolean("focus_mode_active", false)
                                    .putLong("focus_mode_ended_at", 0L)
                                    .apply()
                                cancelInterventionNotification()
                            }
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("GET_STATUS_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, INTERVENTION_EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    interventionEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    interventionEventSink = null
                }
            })
    }

    private fun createInterventionNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                INTERVENTION_NOTIFICATION_CHANNEL,
                "Intervensi MIND DRIJI",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi status intervensi dan jeda digital MIND DRIJI"
                setShowBadge(true)
                enableVibration(true)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun showInterventionNotification(title: String, content: String) {
        try {
            createInterventionNotificationChannel()
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/intervention")
            }

            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getActivity(
                this,
                3001,
                launchIntent,
                pendingIntentFlags
            )

            val notification = NotificationCompat.Builder(this, INTERVENTION_NOTIFICATION_CHANNEL)
                .setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(false)
                .build()

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.notify(INTERVENTION_NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            android.util.Log.w("MIND_DRIJI_INTERVENTION", "Gagal menampilkan notifikasi intervensi: ${e.localizedMessage}")
        }
    }

    private fun cancelInterventionNotification() {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(INTERVENTION_NOTIFICATION_ID)
        } catch (e: Exception) {
            android.util.Log.w("MIND_DRIJI_INTERVENTION", "Gagal membatalkan notifikasi: ${e.localizedMessage}")
        }
    }

    private fun hasCameraPermission(): Boolean {
        return androidx.core.content.ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.CAMERA
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (hasCameraPermission()) {
            result.success(true)
            return
        }
        pendingCameraPermissionResult = result
        androidx.core.app.ActivityCompat.requestPermissions(
            this,
            arrayOf(android.Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
            pendingCameraPermissionResult?.success(granted)
            pendingCameraPermissionResult = null
        } else if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
            pendingNotificationPermissionResult?.success(granted)
            pendingNotificationPermissionResult = null
        }
    }

    companion object {
        private const val TAG_USAGE = "MIND_DRIJI_USAGE"
    }

    override fun onDestroy() {
        eyeMonitoringManager?.releaseResources()
        super.onDestroy()
    }

    /**
     * Memeriksa apakah aplikasi telah diberikan izin PACKAGE_USAGE_STATS.
     */
    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
        if (appOps == null) {
            android.util.Log.e(TAG_USAGE, "AppOpsManager tidak tersedia pada perangkat")
            return false
        }

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }

        if (mode == AppOpsManager.MODE_ALLOWED) {
            android.util.Log.d(TAG_USAGE, "hasUsageStatsPermission check: mode=MODE_ALLOWED, isAllowed=true")
            return true
        }

        if (mode == AppOpsManager.MODE_DEFAULT) {
            val permissionCheck = androidx.core.content.ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.PACKAGE_USAGE_STATS
            )
            if (permissionCheck == PackageManager.PERMISSION_GRANTED) {
                android.util.Log.d(TAG_USAGE, "hasUsageStatsPermission check: MODE_DEFAULT with PERMISSION_GRANTED -> true")
                return true
            }
        }

        // Secondary check: uji langsung apakah UsageStatsManager mengembalikan data event/interval terkini tanpa error
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            val now = System.currentTimeMillis()

            // 1. Check UsageEvents in recent hours
            val events = usageStatsManager?.queryEvents(now - (2 * 60 * 60 * 1000L), now)
            if (events != null && events.hasNextEvent()) {
                android.util.Log.d(TAG_USAGE, "hasUsageStatsPermission fallback check: queryEvents returned active events -> true")
                return true
            }

            // 2. Check queryUsageStats over last 7 days
            val stats = usageStatsManager?.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST,
                now - (1000L * 60 * 60 * 24 * 7),
                now
            )
            if (stats != null && stats.isNotEmpty()) {
                val hasUsedApps = stats.any { it.totalTimeInForeground > 0 || it.lastTimeUsed > 0 }
                if (hasUsedApps) {
                    android.util.Log.d(TAG_USAGE, "hasUsageStatsPermission fallback check: queryUsageStats returned ${stats.size} items with active usage -> true")
                    return true
                }
            }
        } catch (e: Exception) {
            android.util.Log.d(TAG_USAGE, "hasUsageStatsPermission fallback check error: ${e.localizedMessage}")
        }

        android.util.Log.d(TAG_USAGE, "hasUsageStatsPermission check: mode=$mode, isAllowed=false")
        return false
    }

    /**
     * Membuka halaman Pengaturan Akses Penggunaan (Usage Access) di sistem Android.
     * Menggunakan intent resmi Android dengan fallback bertingkat yang kompatibel secara luas.
     */
    private fun openUsageAccessSettings(): Boolean {
        return try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            } else {
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            }

            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                android.util.Log.d(TAG_USAGE, "Opened specific usage access settings for package: $packageName")
                true
            } else {
                val genericIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                if (genericIntent.resolveActivity(packageManager) != null) {
                    startActivity(genericIntent)
                    android.util.Log.d(TAG_USAGE, "Opened generic usage access settings")
                    true
                } else {
                    val settingsIntent = Intent(Settings.ACTION_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(settingsIntent)
                    android.util.Log.d(TAG_USAGE, "Opened fallback main settings")
                    true
                }
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG_USAGE, "Failed to open usage access settings: ${e.localizedMessage}", e)
            try {
                val fallbackIntent = Intent(Settings.ACTION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                true
            } catch (e2: Exception) {
                android.util.Log.e(TAG_USAGE, "Fallback settings intent also failed: ${e2.localizedMessage}", e2)
                false
            }
        }
    }

    /**
     * Mengambil statistik penggunaan aplikasi untuk hari ini (00:00:00 hingga waktu saat ini).
     * Menangani kondisi:
     * - Direct Boot / device restart sebelum user unlock
     * - UsageStatsManager kosong atau null
     * - API level backward-compatibility (API 21 sampai API 35+)
     * - Package visibility & friendly label resolution
     * - Non-overlapping event intervals and multi-bucket aggregation
     */
    private fun getTodayUsage(customStartTime: Long? = null, customEndTime: Long? = null): Map<String, Any> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        if (usageStatsManager == null) {
            android.util.Log.e(TAG_USAGE, "UsageStatsManager service tidak ditemukan pada perangkat")
            return mapOf(
                "totalUsageMillis" to 0L,
                "apps" to emptyList<Map<String, Any>>()
            )
        }

        // Direct Boot / Device Unlock Check
        val userManager = getSystemService(Context.USER_SERVICE) as? android.os.UserManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && userManager != null && !userManager.isUserUnlocked) {
            android.util.Log.w(TAG_USAGE, "Penyimpanan perangkat belum di-unlock oleh user (Direct Boot state). Mengembalikan data kosong aman.")
            return mapOf(
                "totalUsageMillis" to 0L,
                "apps" to emptyList<Map<String, Any>>(),
                "isUserLocked" to true
            )
        }

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = customStartTime ?: calendar.timeInMillis
        val endTime = customEndTime ?: System.currentTimeMillis()

        android.util.Log.d(TAG_USAGE, "Query UsageStats START: startTime=$startTime, endTime=$endTime (range=${(endTime - startTime) / 1000}s)")

        val maxTodayMillis = maxOf(0L, endTime - startTime)
        val pm = packageManager

        // 1. Deteksi dinamis seluruh launcher packages (Home screen) & system packages untuk diexclude
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val launcherPackages = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(homeIntent, PackageManager.ResolveInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(homeIntent, 0)
            }.mapNotNull { it.activityInfo?.packageName }.toSet()
        } catch (e: Exception) {
            emptySet<String>()
        }

        val defaultExcluded = setOf(
            "android",
            "com.android.systemui",
            "com.android.settings.intelligence",
            "com.google.android.permissioncontroller",
            "com.android.permissioncontroller",
            "com.google.android.packageinstaller",
            "com.android.packageinstaller",
            "com.google.android.apps.nexuslauncher",
            "com.google.android.apps.wellbeing",
            "com.miui.home",
            "com.sec.android.app.launcher",
            "com.oppo.launcher",
            "com.bbk.launcher2",
            "com.vivo.launcher",
            "com.transsion.launcher",
            "com.android.launcher3",
            "com.google.android.googlequicksearchbox"
        )

        val allExcludedPackages = launcherPackages + defaultExcluded

        // 2. Ekstraksi interval penggunaan spesifik via UsageEvents state machine (Sumber Kebenaran Utama & Presisi)
        val intervalsList = mutableListOf<Map<String, Any>>()
        val eventUsageByPackage = mutableMapOf<String, Long>()

        try {
            // Query strictly dari startTime (00:00:00 hari ini) sampai endTime (saat ini) agar tidak ada ghost session dari kemarin malam
            val eventQueryStart = startTime
            val usageEvents = usageStatsManager.queryEvents(eventQueryStart, endTime)
            val event = android.app.usage.UsageEvents.Event()

            var currentActivePkg: String? = null
            var currentActiveCls: String? = null
            var currentSessionStart: Long = 0L

            fun closeActiveSession(sessionEndTime: Long) {
                val pkg = currentActivePkg ?: return
                if (currentSessionStart <= 0L) return

                val clampedStart = maxOf(startTime, currentSessionStart)
                val clampedEnd = minOf(endTime, sessionEndTime)

                if (clampedEnd > clampedStart) {
                    val dur = clampedEnd - clampedStart
                    if (!allExcludedPackages.contains(pkg)) {
                        eventUsageByPackage[pkg] = (eventUsageByPackage[pkg] ?: 0L) + dur
                        intervalsList.add(
                            mapOf(
                                "packageName" to pkg,
                                "startTime" to clampedStart,
                                "endTime" to clampedEnd
                            )
                        )
                    }
                }
                currentActivePkg = null
                currentActiveCls = null
                currentSessionStart = 0L
            }

            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                val time = event.timeStamp
                val eventType = event.eventType
                val pkg = event.packageName
                val cls = event.className

                when (eventType) {
                    android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED,
                    android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND,
                    1 -> {
                        if (pkg.isNullOrBlank()) continue
                        if (currentActivePkg != null && currentActivePkg != pkg) {
                            // User berpindah ke aplikasi lain atau kembali ke Home Launcher
                            closeActiveSession(time)
                            currentSessionStart = time
                        } else if (currentActivePkg == null) {
                            currentSessionStart = time
                        }
                        currentActivePkg = pkg
                        currentActiveCls = cls
                    }
                    android.app.usage.UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                    android.app.usage.UsageEvents.Event.KEYGUARD_SHOWN,
                    16, 18 -> {
                        // Layar mati / terkunci: SEMUA event layar (dengan atau tanpa packageName) akan menutup sesi aktif!
                        if (currentActivePkg != null && currentSessionStart > 0L) {
                            closeActiveSession(time)
                        }
                    }
                    android.app.usage.UsageEvents.Event.DEVICE_SHUTDOWN,
                    android.app.usage.UsageEvents.Event.DEVICE_STARTUP,
                    26, 27 -> {
                        if (currentActivePkg != null && currentSessionStart > 0L) {
                            closeActiveSession(time)
                        }
                    }
                }
            }

            // Selesaikan sesi yang masih aktif saat query berakhir (endTime)
            if (currentActivePkg != null && currentSessionStart > 0L) {
                closeActiveSession(endTime)
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG_USAGE, "Gagal mengekstrak interval via UsageEvents: ${e.localizedMessage}")
        }

        // 3. Fallback HANYA jika eventUsageByPackage kosong sama sekali (misal ROM terbatas)
        val aggregatedUsageByPackage = mutableMapOf<String, Long>()
        if (eventUsageByPackage.isEmpty()) {
            try {
                val aggregated = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
                if (aggregated != null && aggregated.isNotEmpty()) {
                    for ((pkg, stats) in aggregated) {
                        if (allExcludedPackages.contains(pkg)) continue
                        if (stats.lastTimeUsed < startTime && stats.lastTimeStamp < startTime) continue
                        val rawTime = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            maxOf(stats.totalTimeInForeground, stats.totalTimeVisible)
                        } else {
                            stats.totalTimeInForeground
                        }
                        val time = minOf(maxTodayMillis, rawTime)
                        if (time > 0) {
                            aggregatedUsageByPackage[pkg] = maxOf(aggregatedUsageByPackage[pkg] ?: 0L, time)
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w(TAG_USAGE, "queryAndAggregateUsageStats fallback: ${e.localizedMessage}")
            }

            if (aggregatedUsageByPackage.isEmpty()) {
                try {
                    val statsList = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        startTime,
                        endTime
                    ) ?: emptyList()
                    for (stats in statsList) {
                        if (allExcludedPackages.contains(stats.packageName)) continue
                        if (stats.lastTimeUsed >= startTime || stats.lastTimeStamp >= startTime) {
                            val rawTime = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                maxOf(stats.totalTimeInForeground, stats.totalTimeVisible)
                            } else {
                                stats.totalTimeInForeground
                            }
                            val time = minOf(maxTodayMillis, rawTime)
                            if (time > 0) {
                                aggregatedUsageByPackage[stats.packageName] = maxOf(
                                    aggregatedUsageByPackage[stats.packageName] ?: 0L,
                                    time
                                )
                            }
                        }
                    }
                } catch (e: Exception) {
                    android.util.Log.w(TAG_USAGE, "queryUsageStats fallback: ${e.localizedMessage}")
                }
            }
        }

        // 4. Sumber kebenaran utama: eventUsageByPackage (100% presisi untuk hari ini)
        val finalUsageByPackage = if (eventUsageByPackage.isNotEmpty()) {
            eventUsageByPackage
        } else {
            aggregatedUsageByPackage
        }

        val appList = mutableListOf<Map<String, Any>>()
        val targetPackages = DoomscrollConfig.loadTargetPackages(this)

        for ((pkgName, usageMillis) in finalUsageByPackage) {
            if (usageMillis < 1000L || allExcludedPackages.contains(pkgName)) continue

            val appName = try {
                val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getApplicationInfo(pkgName, PackageManager.ApplicationInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getApplicationInfo(pkgName, 0)
                }
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                // Fallback cerdas: cek targetPackages atau format segmen
                targetPackages[pkgName] ?: run {
                    val segments = pkgName.split(".")
                    if (segments.isNotEmpty()) {
                        val candidate = segments.last().replaceFirstChar { it.uppercase() }
                        if (candidate.equals("android", ignoreCase = true) && segments.size > 1) {
                            segments[segments.size - 2].replaceFirstChar { it.uppercase() }
                        } else {
                            candidate
                        }
                    } else {
                        pkgName
                    }
                }
            }

            appList.add(
                mapOf(
                    "packageName" to pkgName,
                    "appName" to appName,
                    "usageMillis" to usageMillis
                )
            )
        }

        // Urutkan berdasarkan durasi penggunaan terbanyak (DESC)
        appList.sortByDescending { (it["usageMillis"] as? Long) ?: 0L }

        // Hitung total screen time yang sepenuhnya konsisten dengan daftar app
        val totalUsageMillis = appList.sumOf { (it["usageMillis"] as? Long) ?: 0L }

        android.util.Log.d(
            TAG_USAGE,
            "Query UsageStats END: totalUsageMillis=$totalUsageMillis (${totalUsageMillis / 60000}m), totalAppsIncluded=${appList.size}, intervalsCount=${intervalsList.size}"
        )

        return mapOf(
            "totalUsageMillis" to totalUsageMillis,
            "apps" to appList,
            "intervals" to intervalsList,
            "startTime" to startTime,
            "endTime" to endTime
        )
    }
}

package com.hn.mind_drji

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Pengelola antrean native persisten untuk menyimpan sesi Eye Monitoring
 * sebelum diambil dan disimpan ke Drift SQLite oleh Flutter via MethodChannel.
 * Menggunakan SharedPreferences secara thread-safe.
 */
object EyeMonitoringSessionQueue {
    private const val TAG = "MIND_DRIJI_EYE_QUEUE"
    private const val PREFS_NAME = "minddriji_eye_monitoring_queue"
    private const val KEY_SESSIONS = "pending_eye_sessions_json"
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

                prefs.edit().putString(KEY_SESSIONS, jsonArray.toString()).apply()
                Log.d(
                    TAG,
                    "NATIVE QUEUE SAVE: id=${session["id"]} duration=${session["durationMillis"]}ms totalQueued=${jsonArray.length()}"
                )
            } catch (e: Exception) {
                Log.e(TAG, "NATIVE QUEUE SAVE ERROR: ${e.localizedMessage}", e)
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
                Log.d(TAG, "NATIVE QUEUE READ: retrieved ${result.size} sessions")
            } catch (e: Exception) {
                Log.e(TAG, "NATIVE QUEUE READ ERROR: ${e.localizedMessage}", e)
            }

            return result
        }
    }

    fun clearPendingSessions(context: Context): Boolean {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val cleared = prefs.edit().remove(KEY_SESSIONS).commit()
            Log.d(TAG, "NATIVE QUEUE CLEAR: status=$cleared")
            return cleared
        }
    }
}

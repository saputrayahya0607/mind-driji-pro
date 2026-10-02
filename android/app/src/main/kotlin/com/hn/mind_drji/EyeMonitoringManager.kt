package com.hn.mind_drji

import android.content.Context
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import io.flutter.plugin.common.EventChannel
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.hypot
import kotlin.math.max

/**
 * Manajer Eye Monitoring menggunakan CameraX dan MediaPipe Tasks Vision Face Landmarker.
 *
 * PRIVASI & INTEGRITAS:
 * 1. Hanya memproses frame secara lokal di memori perangkat.
 * 2. Sama sekali TIDAK menyimpan, merekam, atau mengunggah frame kamera, foto, video,
 *    maupun face embeddings ke server manapun.
 * 3. Kamera hanya aktif ketika pemantauan dimulai secara eksplisit oleh pengguna dan
 *    langsung dilepas (released) saat pemantauan dihentikan.
 * 4. Nilai EAR (Eye Aspect Ratio) dan threshold digunakan murni sebagai parameter teknis
 *    indikator kebiasaan/wellness (fatigue behavioral indicator), BUKAN merupakan
 *    diagnosis, standar medis, ataupun alat deteksi penyakit.
 */
class EyeMonitoringManager(private val context: Context) {

    companion object {
        const val TAG = "MIND_DRIJI_EYE"

        // Parameter implementasi teknis untuk deteksi penutupan mata pada frame rate 5-10 FPS.
        // PENTING: Nilai ini BUKAN standar medis ataupun clinical cutoff.
        const val TECHNICAL_EAR_CLOSURE_THRESHOLD = 0.21

        // Threshold ukuran wajah minimum (rasio tinggi & lebar relatif terhadap frame)
        // Disesuaikan untuk jarak natural penggunaan HP (30-45 cm): MIN_FACE_RATIO = 0.05
        const val MIN_FACE_HEIGHT_RATIO = 0.05f
        const val MIN_FACE_WIDTH_RATIO = 0.05f

        // Toleransi orientasi kepala (Head Pose) yang wajar saat beraktivitas di depan layar HP
        // Roll: kemiringan kepala ke kiri/kanan (derajat)
        const val MAX_ROLL_DEGREES = 45.0
        // Yaw: toleransi tolehan wajah (offset hidung relatif ke jarak antar mata)
        const val MAX_YAW_OFFSET_RATIO = 0.50f
        // Pitch: rasio dahi-hidung terhadap tinggi wajah (toleransi wajar melihat layar HP ke bawah)
        const val MIN_PITCH_RATIO = 0.10f
        const val MAX_PITCH_RATIO = 0.85f

        // Throttle interval antar frame (120ms = ~8 FPS) untuk efisiensi CPU dan baterai.
        private const val FRAME_THROTTLE_INTERVAL_MS = 120L

        // MediaPipe Face Landmark Indices
        // Hidung, Dahi, Dagu, Pipi untuk Face Size & Head Pose
        private const val NOSE_TIP = 1
        private const val FOREHEAD = 10
        private const val CHIN = 152
        private const val LEFT_CHEEK = 234
        private const val RIGHT_CHEEK = 454

        // Mata Kiri
        private const val LEFT_EYE_OUTER = 33
        private const val LEFT_EYE_INNER = 133
        private const val LEFT_EYE_TOP_1 = 160
        private const val LEFT_EYE_BOTTOM_1 = 144
        private const val LEFT_EYE_TOP_2 = 158
        private const val LEFT_EYE_BOTTOM_2 = 153

        // Mata Kanan
        private const val RIGHT_EYE_INNER = 362
        private const val RIGHT_EYE_OUTER = 263
        private const val RIGHT_EYE_TOP_1 = 385
        private const val RIGHT_EYE_BOTTOM_1 = 380
        private const val RIGHT_EYE_TOP_2 = 387
        private const val RIGHT_EYE_BOTTOM_2 = 373
    }

    private var cameraProvider: ProcessCameraProvider? = null
    private var cameraExecutor: ExecutorService? = null
    private var faceLandmarker: FaceLandmarker? = null

    @Volatile
    var isMonitoring = false
        private set

    @Volatile
    var eventSink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    // State metrik sesi aktif
    private var sessionId: String = ""
    private var sessionStartTime: Long = 0L
    private var lastAnalyzedTime: Long = 0L

    private var totalEarSum: Double = 0.0
    private var earMeasurementCount: Int = 0
    private var minRecordedEar: Double = 1.0

    private var consecutiveClosureFrames: Int = 0
    private var eyeClosureEventsCount: Int = 0
    private var totalBlinkCount: Int = 0

    /**
     * Memulai pemantauan mata menggunakan kamera depan dan Face Landmarker.
     */
    fun startMonitoring(lifecycleOwner: LifecycleOwner, callback: (Boolean, String?) -> Unit) {
        if (isMonitoring) {
            callback(true, null)
            return
        }

        try {
            // 1. Inisialisasi MediaPipe FaceLandmarker dari model lokal di assets
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("face_landmarker.task")
                .build()

            val options = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setMinFaceDetectionConfidence(0.5f)
                .setMinFacePresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setNumFaces(2) // Deteksi hingga 2 wajah agar tahu jika ada multiple faces
                .setRunningMode(RunningMode.IMAGE)
                .build()

            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
            Log.d(TAG, "MediaPipe FaceLandmarker berhasil diinisialisasi dari assets/face_landmarker.task")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menginisialisasi MediaPipe FaceLandmarker: ${e.localizedMessage}", e)
            callback(false, "Inisialisasi model deteksi wajah gagal: ${e.localizedMessage}")
            return
        }

        // 2. Reset akumulator statistik sesi
        sessionId = UUID.randomUUID().toString()
        sessionStartTime = System.currentTimeMillis()
        lastAnalyzedTime = 0L
        totalEarSum = 0.0
        earMeasurementCount = 0
        minRecordedEar = 1.0
        consecutiveClosureFrames = 0
        eyeClosureEventsCount = 0
        totalBlinkCount = 0

        cameraExecutor = Executors.newSingleThreadExecutor()

        // 3. Konfigurasi CameraX Front Camera
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()

                // Capability Detection: Periksa apakah perangkat memiliki kamera depan
                val provider = cameraProvider
                if (provider == null || !provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)) {
                    Log.w(TAG, "Perangkat tidak memiliki kamera depan yang kompatibel")
                    releaseResources()
                    mainHandler.post {
                        callback(false, "Perangkat tidak memiliki kamera depan yang kompatibel")
                    }
                    return@addListener
                }

                val imageAnalysis = ImageAnalysis.Builder()
                    .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()

                imageAnalysis.setAnalyzer(cameraExecutor!!) { imageProxy ->
                    processImageProxy(imageProxy)
                }

                val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

                cameraProvider?.unbindAll()
                cameraProvider?.bindToLifecycle(lifecycleOwner, cameraSelector, imageAnalysis)

                isMonitoring = true
                Log.d(TAG, "CameraX front camera berhasil terikat dan monitoring dimulai")

                mainHandler.post {
                    dispatchStatusEvent(
                        faceDetected = false,
                        multipleFaces = false,
                        currentEar = 0.0,
                        statusMessage = "Kamera aktif, mencari wajah..."
                    )
                    callback(true, null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Gagal mengikat CameraX use cases: ${e.localizedMessage}", e)
                releaseResources()
                mainHandler.post {
                    callback(false, "Gagal mengaktifkan kamera depan: ${e.localizedMessage}")
                }
            }
        }, ContextCompat.getMainExecutor(context))
    }

    /**
     * Memproses setiap frame dari CameraX secara non-blocking dengan throttling 5-10 FPS.
     */
    private fun processImageProxy(imageProxy: ImageProxy) {
        val now = System.currentTimeMillis()
        if (now - lastAnalyzedTime < FRAME_THROTTLE_INTERVAL_MS || !isMonitoring) {
            imageProxy.close()
            return
        }
        lastAnalyzedTime = now

        try {
            val bitmap = imageProxy.toBitmap()
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = faceLandmarker?.detect(mpImage)

            if (result != null) {
                handleLandmarkResult(result)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error saat pemrosesan frame image: ${e.localizedMessage}")
        } finally {
            imageProxy.close()
        }
    }

    /**
     * Menghitung EAR dan indikator mata dari hasil facial landmark dengan validasi robust
     * terhadap ukuran wajah (jarak HP), head pose (yaw/pitch/roll), dan pengguna yang melihat layar.
     */
    private fun handleLandmarkResult(result: FaceLandmarkerResult) {
        val faces = result.faceLandmarks()

        // 1. Wajah tidak ditemukan
        if (faces.isEmpty()) {
            consecutiveClosureFrames = 0 // Face lost bukan eye closed!
            Log.d(TAG, "[MIND_DRIJI_EYE] frameReceived=true faceDetected=false landmarkCount=0")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = false,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Wajah tidak terdeteksi"
                )
            }
            return
        }

        // 2. Lebih dari satu wajah terdeteksi
        if (faces.size > 1) {
            consecutiveClosureFrames = 0
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: multiple_faces (${faces.size})")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = true,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // Tepat 1 wajah terdeteksi
        val landmarks = faces[0]
        if (landmarks.size < 400) {
            consecutiveClosureFrames = 0
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: landmark missing (count=${landmarks.size})")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 3. Validasi Ukuran Wajah (Face Visibility / Distance Validation)
        val faceHeight = kotlin.math.abs(landmarks[CHIN].y() - landmarks[FOREHEAD].y())
        val faceWidth = kotlin.math.abs(landmarks[RIGHT_CHEEK].x() - landmarks[LEFT_CHEEK].x())
        if (faceHeight < MIN_FACE_HEIGHT_RATIO || faceWidth < MIN_FACE_WIDTH_RATIO) {
            consecutiveClosureFrames = 0 // JANGAN dianggap fatigue!
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: face_distance (faceHeight=$faceHeight, faceWidth=$faceWidth)")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 4. Validasi Head Pose: Roll (Kemiringan kepala)
        val dx = (landmarks[RIGHT_EYE_OUTER].x() - landmarks[LEFT_EYE_OUTER].x()).toDouble()
        val dy = (landmarks[RIGHT_EYE_OUTER].y() - landmarks[LEFT_EYE_OUTER].y()).toDouble()
        val rollDegrees = kotlin.math.abs(Math.toDegrees(kotlin.math.atan2(dy, dx)))
        if (rollDegrees > MAX_ROLL_DEGREES) {
            consecutiveClosureFrames = 0 // Landmark miring tidak valid untuk EAR
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: pose_roll ($rollDegrees deg > $MAX_ROLL_DEGREES deg)")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 5. Validasi Head Pose: Yaw (Tolehan kepala)
        val eyeMidX = (landmarks[LEFT_EYE_OUTER].x() + landmarks[RIGHT_EYE_OUTER].x()) / 2.0
        val eyeSpan = max(0.001, kotlin.math.abs(landmarks[RIGHT_EYE_OUTER].x() - landmarks[LEFT_EYE_OUTER].x()).toDouble())
        val yawRatio = kotlin.math.abs((landmarks[NOSE_TIP].x() - eyeMidX) / eyeSpan)
        if (yawRatio > MAX_YAW_OFFSET_RATIO) {
            consecutiveClosureFrames = 0
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: pose_yaw ($yawRatio > $MAX_YAW_OFFSET_RATIO)")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 6. Validasi Head Pose: Pitch (Kemiringan kepala atas/bawah saat menatap layar HP)
        val upperFaceDist = kotlin.math.abs(landmarks[NOSE_TIP].y() - landmarks[FOREHEAD].y())
        val pitchRatio = upperFaceDist / max(0.001f, faceHeight)
        if (pitchRatio < MIN_PITCH_RATIO || pitchRatio > MAX_PITCH_RATIO) {
            consecutiveClosureFrames = 0
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: pose_pitch ($pitchRatio out of range $MIN_PITCH_RATIO..$MAX_PITCH_RATIO)")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 7. Frame valid: Hitung EAR (Mata pengguna yang melihat layar tetap terukur akurat)
        // MediaPipe Face Mesh Landmark Indices:
        // Left Eye: Outer=33, Inner=133, Top1=160, Bottom1=144, Top2=158, Bottom2=153
        // Right Eye: Inner=362, Outer=263, Top1=385, Bottom1=380, Top2=387, Bottom2=373
        val leftDistV1 = calculateDistance(landmarks[LEFT_EYE_TOP_1].x(), landmarks[LEFT_EYE_TOP_1].y(), landmarks[LEFT_EYE_BOTTOM_1].x(), landmarks[LEFT_EYE_BOTTOM_1].y())
        val leftDistV2 = calculateDistance(landmarks[LEFT_EYE_TOP_2].x(), landmarks[LEFT_EYE_TOP_2].y(), landmarks[LEFT_EYE_BOTTOM_2].x(), landmarks[LEFT_EYE_BOTTOM_2].y())
        val leftDistH = calculateDistance(landmarks[LEFT_EYE_OUTER].x(), landmarks[LEFT_EYE_OUTER].y(), landmarks[LEFT_EYE_INNER].x(), landmarks[LEFT_EYE_INNER].y())

        val rightDistV1 = calculateDistance(landmarks[RIGHT_EYE_TOP_1].x(), landmarks[RIGHT_EYE_TOP_1].y(), landmarks[RIGHT_EYE_BOTTOM_1].x(), landmarks[RIGHT_EYE_BOTTOM_1].y())
        val rightDistV2 = calculateDistance(landmarks[RIGHT_EYE_TOP_2].x(), landmarks[RIGHT_EYE_TOP_2].y(), landmarks[RIGHT_EYE_BOTTOM_2].x(), landmarks[RIGHT_EYE_BOTTOM_2].y())
        val rightDistH = calculateDistance(landmarks[RIGHT_EYE_INNER].x(), landmarks[RIGHT_EYE_INNER].y(), landmarks[RIGHT_EYE_OUTER].x(), landmarks[RIGHT_EYE_OUTER].y())

        if (leftDistH <= 0.0001 || rightDistH <= 0.0001) {
            Log.w(TAG, "[MIND_DRIJI_EYE] EAR_INVALID: horizontalDistance=0 (leftDistH=$leftDistH, rightDistH=$rightDistH)")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        val leftEar = (leftDistV1 + leftDistV2) / (2.0 * leftDistH)
        val rightEar = (rightDistV1 + rightDistV2) / (2.0 * rightDistH)

        if (leftEar.isNaN() || leftEar.isInfinite() || rightEar.isNaN() || rightEar.isInfinite()) {
            Log.w(TAG, "[MIND_DRIJI_EYE] EAR_INVALID: NaN or Infinite (leftEar=$leftEar, rightEar=$rightEar)")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = false,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        val avgEar = (leftEar + rightEar) / 2.0

        // Akumulasi metrik statistik HANYA dari frame valid
        totalEarSum += avgEar
        earMeasurementCount++
        if (avgEar < minRecordedEar) {
            minRecordedEar = avgEar
        }

        // Deteksi behavioral closure & blink berbasis stabilitas temporal
        val isClosed = avgEar < TECHNICAL_EAR_CLOSURE_THRESHOLD
        var blinkDetected = false
        if (isClosed) {
            consecutiveClosureFrames++
            if (consecutiveClosureFrames == 3) {
                // Penutupan mata berkepanjangan (indikasi eye closure event)
                eyeClosureEventsCount++
            }
        } else {
            if (consecutiveClosureFrames in 1..2) {
                // Penutupan cepat (kedipan normal)
                totalBlinkCount++
                blinkDetected = true
            }
            consecutiveClosureFrames = 0
        }

        Log.d(
            TAG,
            "[MIND_DRIJI_EYE] frameReceived=true faceDetected=true landmarkCount=${landmarks.size} leftEyeLandmarks=6 rightEyeLandmarks=6 ear=$avgEar measurementValid=true blinkDetected=$blinkDetected eyeClosed=$isClosed"
        )

        val status = if (isClosed) "Indikasi mata tertutup / berkedip" else "Mata terbuka normal"

        mainHandler.post {
            dispatchStatusEvent(
                faceDetected = true,
                multipleFaces = false,
                measurementValid = true,
                currentEar = avgEar,
                statusMessage = status
            )
        }
    }

    private fun calculateDistance(x1: Float, y1: Float, x2: Float, y2: Float): Double {
        return hypot((x1 - x2).toDouble(), (y1 - y2).toDouble())
    }

    /**
     * Mengirim status snapshot realtime ke Flutter via EventChannel.
     */
    private fun dispatchStatusEvent(
        faceDetected: Boolean,
        multipleFaces: Boolean,
        measurementValid: Boolean = false,
        currentEar: Double,
        statusMessage: String
    ) {
        val sink = eventSink ?: return
        val currentAverageEar = if (earMeasurementCount > 0) totalEarSum / earMeasurementCount else 0.0
        val durationMillis = max(0L, System.currentTimeMillis() - sessionStartTime)

        val payload = mapOf(
            "type" to "status_update",
            "isMonitoring" to isMonitoring,
            "faceDetected" to faceDetected,
            "multipleFaces" to multipleFaces,
            "measurementValid" to measurementValid,
            "currentEar" to currentEar,
            "averageEar" to currentAverageEar,
            "minEar" to (if (earMeasurementCount > 0) minRecordedEar else 0.0),
            "eyeClosureEvents" to eyeClosureEventsCount,
            "blinkCount" to totalBlinkCount,
            "durationMillis" to durationMillis,
            "statusMessage" to statusMessage
        )

        try {
            sink.success(payload)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal mengirim status_update ke Flutter EventChannel: ${e.localizedMessage}")
        }
    }

    /**
     * Menghentikan pemantauan mata, melepaskan kamera, dan mengembalikan summary sesi.
     */
    fun stopMonitoring(): Map<String, Any> {
        val endedAt = System.currentTimeMillis()
        val durationMillis = max(0L, endedAt - sessionStartTime)
        val finalAverageEar = if (earMeasurementCount > 0) totalEarSum / earMeasurementCount else 0.0
        val finalMinEar = if (earMeasurementCount > 0) minRecordedEar else 0.0

        val sessionSummary = mapOf(
            "id" to if (sessionId.isNotEmpty()) sessionId else UUID.randomUUID().toString(),
            "startedAt" to sessionStartTime,
            "endedAt" to endedAt,
            "durationMillis" to durationMillis,
            "averageEar" to finalAverageEar,
            "minEar" to finalMinEar,
            "eyeClosureEvents" to eyeClosureEventsCount,
            "blinkCount" to totalBlinkCount,
            "collectedAt" to endedAt
        )

        releaseResources()

        // Kirim event penutup ke Flutter UI
        val sink = eventSink
        if (sink != null) {
            mainHandler.post {
                try {
                    sink.success(
                        mapOf(
                            "type" to "session_finished",
                            "isMonitoring" to false,
                            "faceDetected" to false,
                            "multipleFaces" to false,
                            "currentEar" to 0.0,
                            "averageEar" to finalAverageEar,
                            "minEar" to finalMinEar,
                            "eyeClosureEvents" to eyeClosureEventsCount,
                            "blinkCount" to totalBlinkCount,
                            "durationMillis" to durationMillis,
                            "statusMessage" to "Monitoring mata selesai"
                        )
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Gagal mengirim session_finished ke EventChannel: ${e.localizedMessage}")
                }
            }
        }

        Log.d(TAG, "Eye Monitoring berhasil dihentikan. Summary: $sessionSummary")
        return sessionSummary
    }

    /**
     * Melepaskan resource CameraX dan MediaPipe.
     */
    fun releaseResources() {
        isMonitoring = false
        try {
            cameraProvider?.unbindAll()
            cameraProvider = null
        } catch (e: Exception) {
            Log.e(TAG, "Error saat unbind cameraProvider: ${e.localizedMessage}")
        }

        try {
            cameraExecutor?.shutdown()
            cameraExecutor = null
        } catch (e: Exception) {
            Log.e(TAG, "Error saat shutdown cameraExecutor: ${e.localizedMessage}")
        }

        try {
            faceLandmarker?.close()
            faceLandmarker = null
        } catch (e: Exception) {
            Log.e(TAG, "Error saat menutup FaceLandmarker: ${e.localizedMessage}")
        }
    }
}

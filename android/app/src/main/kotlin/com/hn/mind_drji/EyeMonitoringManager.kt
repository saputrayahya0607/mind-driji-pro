package com.hn.mind_drji

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Build
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
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
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

        // Ambang durasi kedipan mata manusia normal: 60ms - 450ms.
        // Penutupan melebihi 1000ms dianggap prolonged eye closure (indikasi mata terpejam lama / fatigue).
        const val MIN_BLINK_DURATION_MS = 60L
        const val MAX_BLINK_DURATION_MS = 450L
        const val PROLONGED_CLOSURE_THRESHOLD_MS = 1000L
        const val MIN_INTER_BLINK_INTERVAL_MS = 150L

        // Threshold ukuran wajah minimum (rasio bounding box relatif terhadap frame)
        // Disesuaikan untuk jarak natural penggunaan HP (30-45 cm): MIN_FACE_RATIO = 0.05
        const val MIN_FACE_HEIGHT_RATIO = 0.05f
        const val MIN_FACE_WIDTH_RATIO = 0.05f

        // Toleransi orientasi kepala (Head Pose) yang wajar saat beraktivitas di depan layar HP
        // Roll: kemiringan kepala ke kiri/kanan (derajat deviasi dari garis horizontal)
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

        // Sudut mata lateral (outer) untuk estimasi orientasi head pose roll
        // Landmark 33: Sudut luar mata kanan subjek (sisi kiri citra saat tidak mirrored)
        // Landmark 263: Sudut luar mata kiri subjek (sisi kanan citra saat tidak mirrored)
        private const val LEFT_EYE_OUTER = 33
        private const val LEFT_EYE_INNER = 133
        private const val LEFT_EYE_TOP_1 = 160
        private const val LEFT_EYE_BOTTOM_1 = 144
        private const val LEFT_EYE_TOP_2 = 158
        private const val LEFT_EYE_BOTTOM_2 = 153

        private const val RIGHT_EYE_INNER = 362
        private const val RIGHT_EYE_OUTER = 263
        private const val RIGHT_EYE_TOP_1 = 385
        private const val RIGHT_EYE_BOTTOM_1 = 380
        private const val RIGHT_EYE_TOP_2 = 387
        private const val RIGHT_EYE_BOTTOM_2 = 373
    }

    private data class FaceCandidate(
        val index: Int,
        val landmarks: List<NormalizedLandmark>,
        val minX: Float,
        val maxX: Float,
        val minY: Float,
        val maxY: Float,
        val bboxWidth: Float,
        val bboxHeight: Float,
        val anatWidth: Float,
        val anatHeight: Float,
        val faceWidth: Float,
        val faceHeight: Float,
        val faceArea: Float,
        val centerX: Float,
        val centerY: Float,
        val score: Double
    )

    private var cameraProvider: ProcessCameraProvider? = null
    private var cameraExecutor: ExecutorService? = null
    private var faceLandmarker: FaceLandmarker? = null

    @Volatile
    var isMonitoring = false
        private set

    @Volatile
    private var isAnalyzingFrame = false

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

    // Tracking wajah utama antar-frame (mencegah perpindahan wajah acak saat ada multiple faces)
    private var hasTrackedFace = false
    private var trackedFaceCenterX = 0.5f
    private var trackedFaceCenterY = 0.5f
    private var lastTrackedFaceTime = 0L

    // State machine kedipan & penutupan mata
    private var isEyeCurrentlyClosed: Boolean = false
    private var closureStartTimeMs: Long = 0L
    private var closureFrameCount: Int = 0
    private var prolongedClosureReported: Boolean = false
    private var lastBlinkTimestamp: Long = 0L
    private var eyeClosureEventsCount: Int = 0
    private var totalBlinkCount: Int = 0

    // Diagnostik terkontrol (throttled logging)
    private var processedFrameCount: Long = 0L
    private var lastDiagnosticLogTime: Long = 0L
    private var lastDispatchLogTime: Long = 0L
    private var lastFaceDetectedState: Boolean? = null

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
                .setNumFaces(2) // Deteksi hingga 2 wajah agar dapat memilih wajah utama pengguna
                .setRunningMode(RunningMode.IMAGE)
                .build()

            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
            Log.d(TAG, "MediaPipe FaceLandmarker berhasil diinisialisasi dari assets/face_landmarker.task")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menginisialisasi MediaPipe FaceLandmarker: ${e.localizedMessage}", e)
            callback(false, "Inisialisasi model deteksi wajah gagal: ${e.localizedMessage}")
            return
        }

        // 2. Reset akumulator statistik sesi & state machine
        sessionId = UUID.randomUUID().toString()
        sessionStartTime = System.currentTimeMillis()
        lastAnalyzedTime = 0L
        totalEarSum = 0.0
        earMeasurementCount = 0
        minRecordedEar = 1.0

        resetTrackedFace()
        resetClosureState()
        lastBlinkTimestamp = 0L
        eyeClosureEventsCount = 0
        totalBlinkCount = 0

        processedFrameCount = 0L
        lastDiagnosticLogTime = 0L
        lastDispatchLogTime = 0L
        lastFaceDetectedState = null
        isAnalyzingFrame = false

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

                // Dapatkan rotasi display layar aktif
                val displayRotation = try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        context.display?.rotation ?: android.view.Surface.ROTATION_0
                    } else {
                        @Suppress("DEPRECATION")
                        (context.getSystemService(Context.WINDOW_SERVICE) as? android.view.WindowManager)?.defaultDisplay?.rotation ?: android.view.Surface.ROTATION_0
                    }
                } catch (e: Exception) {
                    android.view.Surface.ROTATION_0
                }

                val imageAnalysis = ImageAnalysis.Builder()
                    .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .setTargetRotation(displayRotation)
                    .build()

                imageAnalysis.setAnalyzer(cameraExecutor!!) { imageProxy ->
                    processImageProxy(imageProxy)
                }

                val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

                cameraProvider?.unbindAll()
                cameraProvider?.bindToLifecycle(lifecycleOwner, cameraSelector, imageAnalysis)

                isMonitoring = true
                Log.d(TAG, "CameraX front camera berhasil terikat dan monitoring dimulai (displayRotation=$displayRotation)")

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
     * Mengoreksi rotasi sensor (portrait 270°/90°) sebelum diteruskan ke MediaPipe.
     */
    private fun processImageProxy(imageProxy: ImageProxy) {
        val now = System.currentTimeMillis()
        if (isAnalyzingFrame || now - lastAnalyzedTime < FRAME_THROTTLE_INTERVAL_MS || !isMonitoring) {
            imageProxy.close()
            return
        }
        isAnalyzingFrame = true
        lastAnalyzedTime = now
        processedFrameCount++

        try {
            val rotationDegrees = imageProxy.imageInfo.rotationDegrees
            val rawBitmap = imageProxy.toBitmap()

            if (processedFrameCount <= 5L || processedFrameCount % 50L == 0L) {
                Log.d(TAG, "[MIND_DRIJI_EYE] Frame #${processedFrameCount}: raw=${rawBitmap.width}x${rawBitmap.height}, rotationDegrees=$rotationDegrees")
            }

            // Rotasi bitmap sesuai orientasi sensor kamera depan agar wajah tegak lurus
            // PENTING: Jangan panggil rawBitmap.recycle() karena pada perangkat GPU Mali,
            // buffer grafis dibagi bersama dengan ImageProxy. Memanggil recycle() menyebabkan mali_gralloc invalid write locks!
            val bitmap = if (rotationDegrees != 0) {
                val matrix = Matrix().apply {
                    postRotate(rotationDegrees.toFloat())
                }
                Bitmap.createBitmap(rawBitmap, 0, 0, rawBitmap.width, rawBitmap.height, matrix, true)
            } else {
                rawBitmap
            }

            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = faceLandmarker?.detect(mpImage)

            if (result != null) {
                handleLandmarkResult(result, bitmap.width, bitmap.height, now)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error saat pemrosesan frame image: ${e.localizedMessage}")
        } finally {
            imageProxy.close()
            isAnalyzingFrame = false
        }
    }

    /**
     * Menghitung EAR dan indikator mata dari hasil facial landmark dengan validasi robust
     * terhadap pemilihan wajah utama, ukuran wajah (jarak HP), head pose, dan pengguna yang melihat layar.
     */
    private fun handleLandmarkResult(
        result: FaceLandmarkerResult,
        frameWidth: Int,
        frameHeight: Int,
        frameTimestamp: Long
    ) {
        val faces = result.faceLandmarks()

        // 1. Wajah tidak ditemukan
        if (faces.isEmpty()) {
            resetClosureState()
            resetTrackedFace()
            if (lastFaceDetectedState != false) {
                lastFaceDetectedState = false
                Log.d(TAG, "[MIND_DRIJI_EYE] STATUS_CHANGE: Wajah tidak terdeteksi (frames=$processedFrameCount)")
            }
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

        // 2. Pemilihan Wajah Utama (Primary Face Selection)
        // Hitung bounding box sejati dari seluruh landmark untuk memperoleh ukuran fisik wajah yang akurat
        val candidateFaces = mutableListOf<FaceCandidate>()

        for ((index, landmarkList) in faces.withIndex()) {
            if (landmarkList.size < 400) continue

            var minX = Float.MAX_VALUE
            var maxX = -Float.MAX_VALUE
            var minY = Float.MAX_VALUE
            var maxY = -Float.MAX_VALUE

            for (lm in landmarkList) {
                val x = lm.x()
                val y = lm.y()
                if (x < minX) minX = x
                if (x > maxX) maxX = x
                if (y < minY) minY = y
                if (y > maxY) maxY = y
            }

            val bboxWidth = maxX - minX
            val bboxHeight = maxY - minY
            val centerX = (minX + maxX) / 2.0f
            val centerY = (minY + maxY) / 2.0f

            // Jarak Euclidean anatomis dahi-dagu dan pipi-pipi (kebal terhadap orientasi sensor landscape/portrait)
            val anatHeight = hypot(
                (landmarkList[CHIN].x() - landmarkList[FOREHEAD].x()).toDouble(),
                (landmarkList[CHIN].y() - landmarkList[FOREHEAD].y()).toDouble()
            ).toFloat()
            val anatWidth = hypot(
                (landmarkList[RIGHT_CHEEK].x() - landmarkList[LEFT_CHEEK].x()).toDouble(),
                (landmarkList[RIGHT_CHEEK].y() - landmarkList[LEFT_CHEEK].y()).toDouble()
            ).toFloat()

            // Ukuran wajah efektif adalah nilai maksimum dari bounding box terluar dan rentang anatomis
            val faceWidth = max(bboxWidth, anatWidth)
            val faceHeight = max(bboxHeight, anatHeight)
            val faceArea = faceWidth * faceHeight

            // Jarak ke tengah frame (0.5, 0.5)
            val distFromScreenCenter = hypot((centerX - 0.5f).toDouble(), (centerY - 0.5f).toDouble())

            // Jarak ke posisi wajah utama yang ditracking pada frame sebelumnya (temporal hysteresis)
            val distFromPreviousTrack = if (hasTrackedFace && frameTimestamp - lastTrackedFaceTime < 1500L) {
                hypot((centerX - trackedFaceCenterX).toDouble(), (centerY - trackedFaceCenterY).toDouble())
            } else {
                0.0
            }

            // Skor kandidat:
            // - Wajah lebih besar (lebih dekat ke kamera / pengguna HP 30-45 cm) -> bobot tinggi (+3.0)
            // - Wajah lebih dekat ke tengah frame -> bobot (+0.4)
            // - Konsistensi tracking frame sebelumnya -> bobot stabilitas (+1.5)
            val score = (faceArea * 3.0) - (distFromScreenCenter * 0.4) - (distFromPreviousTrack * 1.5)

            candidateFaces.add(
                FaceCandidate(
                    index = index,
                    landmarks = landmarkList,
                    minX = minX,
                    maxX = maxX,
                    minY = minY,
                    maxY = maxY,
                    bboxWidth = bboxWidth,
                    bboxHeight = bboxHeight,
                    anatWidth = anatWidth,
                    anatHeight = anatHeight,
                    faceWidth = faceWidth,
                    faceHeight = faceHeight,
                    faceArea = faceArea,
                    centerX = centerX,
                    centerY = centerY,
                    score = score
                )
            )
        }

        if (candidateFaces.isEmpty()) {
            resetClosureState()
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: landmark missing pada semua wajah (count=${faces.size})")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = faces.size > 1,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // Urutkan kandidat berdasarkan skor tertinggi dan pilih kandidat terunggul sebagai wajah pengguna utama
        candidateFaces.sortByDescending { it.score }
        val primaryCandidate = candidateFaces.first()
        val landmarks = primaryCandidate.landmarks
        val isMultipleFacesPresent = faces.size > 1

        // Update tracking state wajah utama
        trackedFaceCenterX = primaryCandidate.centerX
        trackedFaceCenterY = primaryCandidate.centerY
        lastTrackedFaceTime = frameTimestamp
        hasTrackedFace = true

        if (processedFrameCount <= 10L || processedFrameCount % 30L == 0L) {
            Log.d(
                TAG,
                "[MIND_DRIJI_EYE] FACE_SIZE_DIAG: frame=${frameWidth}x${frameHeight} bbox=[minX=%.3f, maxX=%.3f, minY=%.3f, maxY=%.3f] bboxW=%.3f bboxH=%.3f anatW=%.3f anatH=%.3f finalW=%.3f finalH=%.3f (min=%.2f) multi=${isMultipleFacesPresent}".format(
                    primaryCandidate.minX, primaryCandidate.maxX, primaryCandidate.minY, primaryCandidate.maxY,
                    primaryCandidate.bboxWidth, primaryCandidate.bboxHeight,
                    primaryCandidate.anatWidth, primaryCandidate.anatHeight,
                    primaryCandidate.faceWidth, primaryCandidate.faceHeight,
                    MIN_FACE_HEIGHT_RATIO
                )
            )
        }

        if (lastFaceDetectedState != true) {
            lastFaceDetectedState = true
            Log.d(TAG, "[MIND_DRIJI_EYE] STATUS_CHANGE: Wajah terdeteksi (landmarks=${landmarks.size})")
        }

        // 3. Validasi Ukuran Wajah (Face Visibility / Distance Validation untuk jarak 30-45 cm)
        if (primaryCandidate.faceHeight < MIN_FACE_HEIGHT_RATIO || primaryCandidate.faceWidth < MIN_FACE_WIDTH_RATIO) {
            resetClosureState()
            Log.w(
                TAG,
                "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: face_distance (height=%.4f, width=%.4f, min=%.2f) - wajah terlalu jauh".format(
                    primaryCandidate.faceHeight, primaryCandidate.faceWidth, MIN_FACE_HEIGHT_RATIO
                )
            )
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = isMultipleFacesPresent,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 4. Validasi Head Pose: Roll (Kemiringan garis mata terhadap horizontal)
        val pLeft = landmarks[LEFT_EYE_OUTER]
        val pRight = landmarks[RIGHT_EYE_OUTER]
        val eyeDx = (pRight.x() - pLeft.x()).toDouble() * frameWidth
        val eyeDy = (pRight.y() - pLeft.y()).toDouble() * frameHeight
        val absDx = kotlin.math.abs(eyeDx)
        val absDy = kotlin.math.abs(eyeDy)
        // Hitung sudut kemiringan absolut garis mata terhadap garis horizontal layar
        val rollDegrees = Math.toDegrees(kotlin.math.atan2(absDy, max(0.0001, absDx)))

        if (processedFrameCount <= 10L || processedFrameCount % 30L == 0L || rollDegrees > MAX_ROLL_DEGREES) {
            Log.d(
                TAG,
                "[MIND_DRIJI_EYE] POSE_ROLL_DIAG: pLeft=(${pLeft.x()}, ${pLeft.y()}) pRight=(${pRight.x()}, ${pRight.y()}) dx=$eyeDx dy=$eyeDy absDx=$absDx absDy=$absDy roll=%.2f deg (max=%.1f deg)".format(
                    rollDegrees, MAX_ROLL_DEGREES
                )
            )
        }

        if (rollDegrees > MAX_ROLL_DEGREES) {
            resetClosureState()
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: pose_roll (roll=%.2f deg > %.1f deg)".format(rollDegrees, MAX_ROLL_DEGREES))
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = isMultipleFacesPresent,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 5. Validasi Head Pose: Yaw (Tolehan kepala kiri/kanan)
        val eyeMidX = (pLeft.x() + pRight.x()) / 2.0
        val eyeSpan = max(0.001, kotlin.math.abs(pRight.x() - pLeft.x()).toDouble())
        val yawRatio = kotlin.math.abs((landmarks[NOSE_TIP].x() - eyeMidX) / eyeSpan)
        if (yawRatio > MAX_YAW_OFFSET_RATIO) {
            resetClosureState()
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: pose_yaw (yawRatio=%.3f > %.2f)".format(yawRatio, MAX_YAW_OFFSET_RATIO))
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = isMultipleFacesPresent,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 6. Validasi Head Pose: Pitch (Kemiringan kepala atas/bawah saat menatap layar HP)
        val upperFaceDist = kotlin.math.abs(landmarks[NOSE_TIP].y() - landmarks[FOREHEAD].y())
        val pitchRatio = upperFaceDist / max(0.001f, primaryCandidate.faceHeight)
        if (pitchRatio < MIN_PITCH_RATIO || pitchRatio > MAX_PITCH_RATIO) {
            resetClosureState()
            Log.d(TAG, "[MIND_DRIJI_EYE] MEASUREMENT_INVALID: pose_pitch (pitchRatio=%.3f out of [%.2f..%.2f])".format(pitchRatio, MIN_PITCH_RATIO, MAX_PITCH_RATIO))
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = isMultipleFacesPresent,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // 7. Hitung EAR berbasis Euclidean pixel distance (Soukupová & Čech formula)
        // Menjamin rasio aspek citra tidak mendistorsi jarak vertikal kelopak mata
        val leftDistV1 = calculateDistance(landmarks[LEFT_EYE_TOP_1].x(), landmarks[LEFT_EYE_TOP_1].y(), landmarks[LEFT_EYE_BOTTOM_1].x(), landmarks[LEFT_EYE_BOTTOM_1].y(), frameWidth, frameHeight)
        val leftDistV2 = calculateDistance(landmarks[LEFT_EYE_TOP_2].x(), landmarks[LEFT_EYE_TOP_2].y(), landmarks[LEFT_EYE_BOTTOM_2].x(), landmarks[LEFT_EYE_BOTTOM_2].y(), frameWidth, frameHeight)
        val leftDistH = calculateDistance(landmarks[LEFT_EYE_OUTER].x(), landmarks[LEFT_EYE_OUTER].y(), landmarks[LEFT_EYE_INNER].x(), landmarks[LEFT_EYE_INNER].y(), frameWidth, frameHeight)

        val rightDistV1 = calculateDistance(landmarks[RIGHT_EYE_TOP_1].x(), landmarks[RIGHT_EYE_TOP_1].y(), landmarks[RIGHT_EYE_BOTTOM_1].x(), landmarks[RIGHT_EYE_BOTTOM_1].y(), frameWidth, frameHeight)
        val rightDistV2 = calculateDistance(landmarks[RIGHT_EYE_TOP_2].x(), landmarks[RIGHT_EYE_TOP_2].y(), landmarks[RIGHT_EYE_BOTTOM_2].x(), landmarks[RIGHT_EYE_BOTTOM_2].y(), frameWidth, frameHeight)
        val rightDistH = calculateDistance(landmarks[RIGHT_EYE_INNER].x(), landmarks[RIGHT_EYE_INNER].y(), landmarks[RIGHT_EYE_OUTER].x(), landmarks[RIGHT_EYE_OUTER].y(), frameWidth, frameHeight)

        val leftEar = if (leftDistH > 0.001) (leftDistV1 + leftDistV2) / (2.0 * leftDistH) else -1.0
        val rightEar = if (rightDistH > 0.001) (rightDistV1 + rightDistV2) / (2.0 * rightDistH) else -1.0

        // Validasi fisik nilai EAR wajar (0.05..0.60)
        val leftValid = !leftEar.isNaN() && !leftEar.isInfinite() && leftEar in 0.05..0.60
        val rightValid = !rightEar.isNaN() && !rightEar.isInfinite() && rightEar in 0.05..0.60

        if (!leftValid && !rightValid) {
            resetClosureState()
            Log.w(TAG, "[MIND_DRIJI_EYE] EAR_INVALID: leftEar=$leftEar rightEar=$rightEar")
            mainHandler.post {
                dispatchStatusEvent(
                    faceDetected = true,
                    multipleFaces = isMultipleFacesPresent,
                    measurementValid = false,
                    currentEar = 0.0,
                    statusMessage = "Menyesuaikan posisi wajah"
                )
            }
            return
        }

        // Pengukuran kedua mata dengan toleransi jika salah satu mata terhalang sebagian
        val avgEar = when {
            leftValid && rightValid -> (leftEar + rightEar) / 2.0
            leftValid -> leftEar
            else -> rightEar
        }

        // Akumulasi metrik statistik sesi
        totalEarSum += avgEar
        earMeasurementCount++
        if (avgEar < minRecordedEar) {
            minRecordedEar = avgEar
        }

        // Log koordinat landmark kedua mata dan hasil EAR
        if (processedFrameCount <= 10L || processedFrameCount % 30L == 0L) {
            Log.d(
                TAG,
                "[MIND_DRIJI_EYE] EYE_METRICS_DIAG: L_Ear=%.3f R_Ear=%.3f avgEar=%.3f L_V=(%.1f, %.1f) L_H=%.1f R_V=(%.1f, %.1f) R_H=%.1f".format(
                    leftEar, rightEar, avgEar, leftDistV1, leftDistV2, leftDistH, rightDistV1, rightDistV2, rightDistH
                )
            )
        }

        // 8. State Machine Deteksi Kedipan & Prolonged Closure
        val isClosed = avgEar < TECHNICAL_EAR_CLOSURE_THRESHOLD
        var blinkDetected = false

        if (isClosed) {
            if (!isEyeCurrentlyClosed) {
                // Transisi: TERBUKA -> TERTUTUP (Mata mulai menutup)
                isEyeCurrentlyClosed = true
                closureStartTimeMs = frameTimestamp
                closureFrameCount = 1
                prolongedClosureReported = false
                Log.d(TAG, "[MIND_DRIJI_EYE] TRANSISI: Mata menutup (EAR=%.3f, threshold=%.2f)".format(avgEar, TECHNICAL_EAR_CLOSURE_THRESHOLD))
            } else {
                // Keadaan berkelanjutan: Mata masih tertutup
                closureFrameCount++
                val closedDuration = frameTimestamp - closureStartTimeMs
                if (closedDuration >= PROLONGED_CLOSURE_THRESHOLD_MS && !prolongedClosureReported) {
                    eyeClosureEventsCount++
                    prolongedClosureReported = true
                    Log.d(
                        TAG,
                        "[MIND_DRIJI_EYE] PROLONGED_CLOSURE: durasi=${closedDuration}ms frames=$closureFrameCount total=$eyeClosureEventsCount"
                    )
                }
            }
        } else {
            if (isEyeCurrentlyClosed) {
                // Transisi: TERTUTUP -> TERBUKA (Mata membuka kembali)
                val closedDuration = frameTimestamp - closureStartTimeMs
                val timeSinceLastBlink = frameTimestamp - lastBlinkTimestamp

                // Kedipan valid: durasi wajar (60-450ms atau 1-4 frame) dan bukan penutupan berkepanjangan
                val isValidDuration = (closedDuration in MIN_BLINK_DURATION_MS..MAX_BLINK_DURATION_MS) ||
                        (closureFrameCount in 1..4 && closedDuration <= MAX_BLINK_DURATION_MS + 100L)

                if (!prolongedClosureReported && isValidDuration && timeSinceLastBlink >= MIN_INTER_BLINK_INTERVAL_MS) {
                    totalBlinkCount++
                    lastBlinkTimestamp = frameTimestamp
                    blinkDetected = true
                    Log.d(
                        TAG,
                        "[MIND_DRIJI_EYE] BLINK_DETECTED: durasi=${closedDuration}ms frames=$closureFrameCount totalBlinks=$totalBlinkCount EAR=%.3f".format(avgEar)
                    )
                } else if (prolongedClosureReported) {
                    Log.d(
                        TAG,
                        "[MIND_DRIJI_EYE] REOPEN_AFTER_PROLONGED: durasi=${closedDuration}ms (bukan kedipan tunggal)"
                    )
                }

                // Kembalikan ke baseline terbuka
                isEyeCurrentlyClosed = false
                closureFrameCount = 0
                prolongedClosureReported = false
            }
        }

        // 9. Log diagnostik periodik berkala (setiap 2 detik agar logcat tidak terbebani)
        if (frameTimestamp - lastDiagnosticLogTime >= 2000L) {
            lastDiagnosticLogTime = frameTimestamp
            Log.i(
                TAG,
                "[MIND_DRIJI_EYE_DIAG] frame=$processedFrameCount ear=%.3f (L=%.3f, R=%.3f) eyeClosed=$isClosed blinks=$totalBlinkCount closures=$eyeClosureEventsCount landmarks=${landmarks.size} multiFace=$isMultipleFacesPresent".format(
                    avgEar, leftEar, rightEar
                )
            )
        }

        val status = if (isClosed) "Indikasi mata tertutup / berkedip" else "Mata terbuka normal"

        mainHandler.post {
            dispatchStatusEvent(
                faceDetected = true,
                multipleFaces = isMultipleFacesPresent,
                measurementValid = true,
                currentEar = avgEar,
                statusMessage = status,
                forceLog = blinkDetected
            )
        }
    }

    /**
     * Mengatur ulang status penutupan mata saat wajah hilang atau landmark tidak valid,
     * sehingga kehilangan wajah tidak pernah menghasilkan kedipan palsu.
     */
    private fun resetClosureState() {
        if (isEyeCurrentlyClosed) {
            Log.d(TAG, "[MIND_DRIJI_EYE] State reset: wajah hilang / landmark tidak valid saat mata tertutup")
        }
        isEyeCurrentlyClosed = false
        closureFrameCount = 0
        prolongedClosureReported = false
    }

    /**
     * Mengatur ulang tracking wajah pengguna utama.
     */
    private fun resetTrackedFace() {
        hasTrackedFace = false
        trackedFaceCenterX = 0.5f
        trackedFaceCenterY = 0.5f
        lastTrackedFaceTime = 0L
    }

    /**
     * Menghitung jarak Euclidean antar dua titik dalam koordinat piksel gambar.
     */
    private fun calculateDistance(
        x1: Float,
        y1: Float,
        x2: Float,
        y2: Float,
        width: Int = 1,
        height: Int = 1
    ): Double {
        val dx = (x1 - x2).toDouble() * width
        val dy = (y1 - y2).toDouble() * height
        return hypot(dx, dy)
    }

    /**
     * Mengirim status snapshot realtime ke Flutter via EventChannel.
     * Menggunakan throttled logging untuk meminimalkan beban I/O log.
     */
    private fun dispatchStatusEvent(
        faceDetected: Boolean,
        multipleFaces: Boolean,
        measurementValid: Boolean = false,
        currentEar: Double,
        statusMessage: String,
        forceLog: Boolean = false
    ) {
        val sink = eventSink ?: return
        val now = System.currentTimeMillis()
        val currentAverageEar = if (earMeasurementCount > 0) totalEarSum / earMeasurementCount else 0.0
        val durationMillis = max(0L, now - sessionStartTime)

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
            if (forceLog || now - lastDispatchLogTime >= 2000L) {
                lastDispatchLogTime = now
                Log.d(
                    TAG,
                    "[MIND_DRIJI_EYE] EventChannel dispatched: ear=%.3f blinks=%d closures=%d valid=%b multi=%b msg=%s".format(
                        currentEar, totalBlinkCount, eyeClosureEventsCount, measurementValid, multipleFaces, statusMessage
                    )
                )
            }
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

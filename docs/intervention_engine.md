# Intervention Engine — MIND DRIJI

## 1. Architecture

Intervention Engine bertindak sebagai eksekutor hilir (*downstream executor*) dari pipeline Digital Wellness MIND DRIJI:

```
[Native Data: UsageStats + Accessibility + CameraX]
                       ↓
              [Drift SQLite DB]
                       ↓
               [Detection Engine]
                       ↓
                [Insight Engine]
                       ↓
            [Recommendation Engine]
                       ↓
              (USER CHOICE / OPSI)
                       ↓
             [Intervention Engine]
             /                   \
    [Digital Break]        [Eye Relaxation]
           ↓                      ↓
 [Timestamp Countdown]   [Step-by-step Calm Guide]
           ↓                      ↓
[Android Notification]   [Comfortable Activity]
```

### Prinsip Utama:
- **User-Initiated Execution**: Intervensi tidak pernah dimulai secara paksa atau otomatis oleh Detection Engine. Pengguna memegang kendali penuh atas kapan memulai dan membatalkan intervensi.
- **Pure Timestamp Derivation**: Durasi dihitung berdasarkan selisih mutlak `endedAt - DateTime.now()`. Tidak ada ketergantungan pada jumlah akumulasi tick timer lokal.
- **Zero Medical Claims**: Seluruh narasi UI berfokus pada jeda santai dan kenyamanan mata tanpa janji penyembuhan penyakit atau diagnosis medis.
- **No Addiction Claims**: Tidak ada pelabelan negatif, judgement, atau skor kecanduan.

---

## 2. Digital Break

Digital Break dirancang untuk memberikan jeda terencana dari interaksi layar smartphone.

- **Pilihan Durasi**: 5 menit, 15 menit, dan 30 menit (diambil dari rekomendasi atau preferensi pengguna).
- **Perilaku Sistem**:
  - Aplikasi menampilkan countdown sisa waktu (`mm:ss`).
  - Menampilkan saran relaksasi santai (minum air putih, menatap area hijau, peregangan ringan).
  - Tidak memblokir paksa perangkat.
  - Pengguna memiliki tombol "Batalkan" (dengan dialog konfirmasi) dan tombol "Selesai Sekarang".

---

## 3. Eye Relaxation

Fitur panduan relaksasi mata terstruktur untuk mengalihkan pandangan dari paparan layar dekat secara berkala:

- **Alur Panduan**:
  1. *Alihkan pandangan dari layar*: Arahkan pandanganmu ke luar jendela atau sudut ruangan terjauh.
  2. *Fokus pada objek jauh*: Amati detail objek berjarak minimal 6 meter selama 20 detik.
  3. *Kedip perlahan*: Tutup dan buka mata secara lembut beberapa kali agar kelembapan terjaga.
  4. *Tarik napas rileks*: Tarik napas dalam, hembuskan perlahan, lepaskan ketegangan leher dan bahu.
  5. *Selesai*: Istirahat mata tuntas, pengguna dapat melanjutkan aktivitas dengan nyaman.
- **Bahasa Non-Medis**:
  - Diizinkan: *"Istirahat sejenak dari layar"*, *"Alihkan pandangan"*, *"Berikan jeda pada mata"*.
  - Dilarang: *"Menyembuhkan mata minus"*, *"Mengobati penyakit mata"*, *"Mencegah katarak/glaukoma"*.

---

## 4. Timer Architecture

Kelemahan umum timer aplikasi mobile adalah timer terhenti saat OS menidurkan proses di latar belakang (*Doze mode* atau *battery optimization*).

Intervention Engine menyelesaikan masalah ini dengan **Absolute Timestamp Math**:
1. Saat intervensi dimulai:
   $$\text{startedAt} = \text{DateTime.now()}$$
   $$\text{endedAt} = \text{startedAt} + \text{duration}$$
2. Sisa detik dihitung dinamis:
   $$\text{remainingSeconds} = \max(0, \text{endedAt.difference(DateTime.now()).inSeconds})$$
3. Timer `Timer.periodic(1 sec)` di Flutter hanya berfungsi memicu pembaruan UI (repainting). Nilai sisa waktu selalu dievaluasi langsung dari jam sistem, menjamin tidak ada desinkronisasi waktu.

---

## 5. Lifecycle Handling

`InterventionService` mengimplementasikan `WidgetsBindingObserver`:
- **`AppLifecycleState.paused` / `inactive` / `detached`**: Timer tidak di-reset dan objek intervensi tidak dihapus. Timestamp target tetap tersimpan.
- **`AppLifecycleState.resumed`**: `handleAppResume()` seketika mengevaluasi kembali `endedAt - now`. Jika waktu masih tersisa, ticker berjalan melanjutkan sisa detik yang tepat. Jika waktu telah habis selama di background, intervensi otomatis diselesaikan secara elegan (`completeIntervention()`).

---

## 6. Notification Integration

- **Channel ID**: `minddriji_intervention`
- **Channel Name**: "Intervensi MIND DRIJI" (Importance: Default)
- **Status Notifikasi**:
  - Saat Digital Break dimulai: Menampilkan notifikasi persisten *"Jeda Digital Aktif — Berikan jeda sejenak dari layar."* yang mengarahkan kembali ke route `/intervention`.
  - Saat dibatalkan atau selesai: Notifikasi ditarik dari status bar (`cancel(3001)`).
- **Graceful Fallback**: Jika pengguna menolak izin `POST_NOTIFICATIONS` (Android 13+), intervensi tetap berjalan sempurna di layar foreground tanpa crash.

---

## 7. User Control & Exit Paths

1. Setiap intervensi memiliki jalur keluar yang jelas (*clear exit path*).
2. Tombol *"Batalkan"* meminta konfirmasi singkat agar pengguna tidak terjebak tanpa jalan keluar.
3. Tombol *"Selesai"* memungkinkan pengguna mengakhiri sesi lebih awal jika situasi mendesak.

---

## 8. Privacy & Data Protection

- Tidak ada pembacaan teks layar, pesan chat, video, riwayat pencarian, atau tangkapan layar.
- Data sesi intervensi aktif disimpan secara lokal di perangkat (`SharedPreferences` dan state memori).
- Tidak mengirim telemetri ke server atau Supabase pada tahap ini.

---

## 9. Focus Mode Android Architecture Audit

Audit mendalam terhadap arsitektur native Android untuk persiapan Focus Mode di masa mendatang:

### A. Deteksi Foreground Package oleh AccessibilityService
- **Temuan**: `DoomscrollAccessibilityService` mendengarkan event `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED`.
- **Hasil**: Properti `event.packageName` berhasil memberikan nama package aplikasi yang sedang aktif di layar secara *real-time*.

### B. Kemampuan Navigasi Kembali
- **Temuan**: Android `AccessibilityService` menyediakan API bawaan `performGlobalAction(GLOBAL_ACTION_BACK)` dan `performGlobalAction(GLOBAL_ACTION_HOME)`.
- **Hasil**: Secara teknis memungkinkan untuk membalikkan pengguna ke layar sebelumnya atau ke Home ketika aplikasi terlarang dibuka.

### C. Pengecualian MIND DRIJI (Whitelist)
- **Temuan**: Package `com.hn.mind_drji` dapat dikecualikan dengan mudah melalui pengecekan:
  ```kotlin
  if (pkgName == applicationContext.packageName) return
  ```

### D. Analisis Event Sistem Kritis
- **Home Button**: Menghasilkan event package launcher bawaan (misal `com.google.android.apps.nexuslauncher`, `com.sec.android.app.launcher`).
- **Settings (`com.android.settings`)**: Harus dikecualikan agar pengguna tidak terkunci dari pengaturan sistem.
- **Notification Shade / System UI (`com.android.systemui`)**: Menghasilkan event `systemui`. Memblokir event ini akan merusak fungsi drawer notifikasi dan status bar sistem.
- **Recent Apps (`com.android.systemui` / Launcher)**: Bergantung pada implementasi OEM Android.
- **Play Store (`com.android.vending`) & Browser (`com.android.chrome`)**: Memerlukan kebijakan whitelist/blacklist yang jelas agar aplikasi esensial tetap dapat diakses.

### E. Mekanisme Penghentian Focus Mode
- Sesi Focus Mode harus memiliki mekanisme penghentian darurat:
  1. Habisnya waktu hitung mundur (*timeout*).
  2. Notifikasi persisten dengan tombol tindakan *"Akhiri Sesi"*.
  3. Membuka aplikasi MIND DRIJI secara langsung.

### F. Dukungan Versi Android
- Min SDK project saat ini adalah **24** (Android 7.0) dan Target SDK **34** (Android 14).
- `performGlobalAction` didukung sejak API level 16. Mekanisme Accessibility kompatibel dengan seluruh target perangkat project.

### G. Kebutuhan Device Owner / Lock Task Mode
- **Lock Task Mode** (Kiosk Mode) memberikan pemblokiran anti-bypass paling kuat, namun **membutuhkan hak Device Owner** yang hanya dapat diatur saat provisioning pabrik atau via ADB enterprise.
- Mode ini **tidak cocok** untuk aplikasi konsumer reguler di Google Play Store.

### H. Skenario Kiosk vs Consumer
- Lock Task Mode hanya relevan untuk perangkat inventaris perusahaan / sekolah.
- Untuk aplikasi konsumer, pendekatan ramah (*soft intervention* seperti pengingat, overlay non-intrusif, atau accessibility back-navigation dengan whitelist) adalah pendekatan yang paling etis dan stabil.

### I. Batasan Android Consumer Device
1. **OEM Battery Killers**: Vendor seperti Xiaomi (MIUI/HyperOS), Samsung, dan Huawei sering mematikan background Accessibility Service jika tidak diatur *"No Restrictions"*.
2. **Kebijakan Google Play**: Google Play melarang keras penyalahgunaan Accessibility Service di luar tujuan aksesibilitas dan digital wellness yang dideklarasikan secara eksplisit.
3. **Pengguna Dapat Mematikan Kapan Saja**: Pengguna dapat masuk ke Settings > Accessibility dan mematikan service dalam 5 detik.

### J. Kelayakan AccessibilityService untuk Prototype MIND DRIJI
- AccessibilityService **layak** digunakan untuk riset dan prototype intervensi perilaku scrolling, namun **tidak boleh** diimplementasikan sebagai pemblokir agresif (*fake blocker*) tanpa pengujian device fisik secara langsung.
- Oleh karena itu, pada tahap ini disiapkan kontrak `FocusModeExecutor` dan stub `AuditedFocusModeExecutor` yang transparan dan aman tanpa risiko merusak fungsi `DoomscrollAccessibilityService` existing.

---

## 10. Android Limitations Summary

| Parameter | Kapabilitas | Batasan |
|---|---|---|
| Background Timer | Sangat Akurat via Timestamp | Flutter Timer loop dapat tertunda oleh CPU sleep jika tidak menggunakan timestamp math |
| Notifikasi | Didukung Penuh (Android 8+ O/P/Q/R/S/T/U) | Memerlukan izin `POST_NOTIFICATIONS` pada Android 13+ |
| Accessibility Monitoring | Real-time scroll & window state | Rentan dimatikan oleh OEM battery management |
| Hard App Blocker | Memerlukan Device Owner / Kiosk Mode | Berisiko tinggi melanggar kebijakan Play Store jika dieksekusi secara keras |

---

## 11. Future Implementation (Next Stage)

1. **Intervention History Persistence**: Menambahkan tabel Drift khusus untuk merekam riwayat kepatuhan intervensi pengguna (tanggal, durasi, status selesai/batal).
2. **Interactive Audio/Haptic Feedback**: Getaran lembut atau lonceng santai saat Digital Break berakhir.
3. **Focus Mode Soft Overlay**: Menampilkan dialog pengingat santai ketika aplikasi target dibuka selama sesi fokus.

---

## 12. Testing Coverage

Pengujian otomatis mencakup 27 skenario pengujian komprehensif pada [intervention_test.dart](file:///e:/LOMBA/mind_drji/test/intervention_test.dart):
- Skenario Digital Break (durasi 5m, 15m, 30m, background recovery, resume recalculation, cancel, complete, restart recovery).
- Skenario Eye Relaxation (start, step progression, cancel, timestamp recovery).
- Skenario Integritas Intervensi (user-initiated only, no automatic trigger, single active lock, lifecycle persistence).
- Skenario Audit Focus Mode (dokumentasi kesiapan native, tidak ada regresi pada accessibility existing, no fake blocker).

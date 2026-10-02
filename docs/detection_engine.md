# Detection Engine - MIND DRIJI

## 1. Tujuan
Detection Engine berfungsi sebagai lapisan deteksi perilaku (*behavioral detection layer*) untuk mengidentifikasi kecenderungan dan pola penggunaan aplikasi/scrolling secara objektif.

> **Pernyataan Batasan & Privasi:**
> Detection Engine mendeteksi pola perilaku scrolling berdasarkan metadata penggunaan aplikasi. Sistem tidak membaca isi konten sehingga hasil deteksi tidak dapat dianggap sebagai diagnosis atau bukti definitif doomscrolling.

## 2. Sumber Data
Detection Engine hanya menggunakan metadata perilaku yang sudah dikumpulkan secara transparan dan berizin:
1. **Accessibility Service**: Durasi sesi, waktu mulai/selesai, jumlah swipe, arah swipe (downward vs upward), rata-rata interval antar-swipe.
2. **Android UsageStatsManager**: Total waktu layar (Screen Time) dan durasi penggunaan aplikasi per paket.
3. **CameraX + MediaPipe Face Landmarker (Konteks)**: Frekuensi kedipan dan penutupan mata hanya sebagai sinyal kontekstual tambahan (BUKAN bukti kausal/medis).
4. **Drift Database (Offline First)**: Tabel `doomscroll_sessions`, `screen_time`, dan `eye_monitoring_sessions`.

### Batasan Privasi
Sistem **TIDAK PERNAH** membaca:
- Isi video / konten feed
- Caption, teks postingan, atau komentar
- Pesan pribadi / chatting
- Password / data formulir
- Screenshot / tangkapan layar
- Raw frame kamera

## 3. Definisi Fitur Perilaku (Behavioral Features)
1. **Total Scrolling Sessions (`totalScrollingSessions`)**: Jumlah sesi interaksi scrolling terdeteksi.
2. **Total Scrolling Duration (`totalScrollingDurationMillis`)**: Akumulasi durasi seluruh sesi scrolling dalam milidetik.
3. **Total Swipes (`totalSwipeCount`)**: Total navigasi geser layar.
4. **Downward Swipe Ratio (`downwardSwipeRatio`)**:
   $$\text{downwardSwipeRatio} = \frac{\text{totalDownwardSwipeCount}}{\text{totalSwipeCount}}$$
   Jika total swipe = 0, rasio = 0.0.
5. **Average Session Duration (`averageSessionDurationMillis`)**:
   $$\text{avgDuration} = \frac{\text{totalScrollingDurationMillis}}{\text{totalScrollingSessions}}$$
6. **Average Swipes Per Session (`averageSwipesPerSession`)**:
   $$\text{avgSwipes} = \frac{\text{totalSwipeCount}}{\text{totalScrollingSessions}}$$
7. **Repeated Session Count (`repeatedSessionCount`)**: Jumlah pasangan sesi berurutan dengan jeda waktu $\le 15\text{ menit}$.
8. **Time Segmentation**:
   - Dini Hari: 00:00–04:59
   - Pagi: 05:00–10:59
   - Siang: 11:00–14:59
   - Sore: 15:00–17:59
   - Malam: 18:00–23:59
9. **Top Scrolling App (`topScrollingApp`)**: Aplikasi dengan durasi scrolling terlama pada periode pemantauan.

## 4. Definisi & Ambang Batas Aturan (Detection Rules)
Semua ambang batas dikonfigurasi secara terpusat pada `DetectionThresholds`:
1. **Sesi Panjang (`LONG_SCROLL_SESSION`)**:
   - Kondisi: `longestSessionDurationMillis >= 20 menit (1.200.000 ms)`.
   - Rasional: Penggunaan feed berkelanjutan lebih dari 20 menit tanpa jeda menunjukkan potensi inersia scrolling.
2. **Aktivitas Tinggi (`HIGH_SCROLL_ACTIVITY`)**:
   - Kondisi: `totalSwipeCount >= 300 swipe`.
   - Rasional: Frekuensi perpindahan konten yang sangat cepat mencerminkan konsumsi cepat tanpa henti.
3. **Sesi Berulang (`REPEATED_SCROLLING`)**:
   - Kondisi: `repeatedSessionCount >= 3 kali` dengan jeda $\le 15\text{ menit}$.
   - Rasional: Pola membuka aplikasi kembali segera setelah menutupnya.
4. **Scrolling Satu Arah Kontinu (`DOWNWARD_PATTERN`)**:
   - Kondisi: `downwardSwipeRatio >= 0.75 (75%)` dan `totalSwipeCount >= 50`.
   - Rasional: Pola eksplorasi feed tak terbatas umumnya didominasi gesekan ke bawah secara berulang.
5. **Pola Malam Hari (`NIGHT_SCROLLING_PATTERN`)**:
   - Kondisi: `(nightSessionCount + diniHariSessionCount) >= 3 sesi`.
   - Rasional: Observasi perilaku scrolling yang terkonsentrasi pada waktu istirahat malam.
6. **Pola Multi-Sinyal (`MULTI_SIGNAL_SCROLLING_PATTERN`)**:
   - Kondisi: Muncul minimal 2 sinyal perilaku sekaligus dan total sesi $\ge 3$.
   - Rasional: Konfirmasi dari beberapa indikator simultan memberikan keyakinan deteksi yang lebih kokoh.
7. **Sinyal Kontekstual Pemantauan Mata (`contextualEyeFatigue`)**:
   - Kondisi: Penutupan mata berkepanjangan $\ge 5$ kejadian atau $\text{EAR} < 0.22$.
   - **PENTING**: Hanya disajikan sebagai catatan observasi ("tercatat indikasi mata lelah"), bukan bukti kausalitas.

## 5. Non-Arbitrary / Tanpa Skor Kecanduan
Sistem MIND DRIJI **TIDAK MENGGUNAKAN**:
- Skor kecanduan 0–100 (*Addiction Score*)
- Digital Health Score
- Label tingkat kecanduan (Low / Medium / High Addiction)
- Diagnosis medis klinis

Penilaian disajikan murni dalam bentuk bukti terukur (*DetectionEvidence*) dan narasi faktual.

## 6. Alasan Belum Menggunakan Machine Learning & Rencana Integrasi
- **Alasan**: Model ML seperti Random Forest membutuhkan dataset berlabel (*ground truth*) yang telah divalidasi oleh pakar ergonomi/psikologi digital pada ribuan pengguna nyata. Memasukkan model tanpa data terlatih yang valid akan menghasilkan prediksi acak (*pseudoscience*).
- **Kesiapan Arsitektur (ML Ready)**: Interface `abstract class DetectionStrategy` telah diimplementasikan. Di masa mendatang, `RandomForestDetectionStrategy` dapat langsung disematkan menggantikan atau mendampingi `RuleBasedDetectionStrategy` tanpa mengubah controller, service, atau antarmuka aplikasi.

## 7. Alur Intervensi
Sistem tidak pernah mengaktifkan intervensi secara sepihak:
$$\text{Detection} \rightarrow \text{Insight} \rightarrow \text{Suggested Intervention} \rightarrow \text{User Choice} \rightarrow \text{Focus Mode / Jeda}$$
Pengguna selalu memegang kendali penuh.

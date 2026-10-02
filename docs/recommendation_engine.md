# Recommendation Engine — MIND DRIJI

## 1. Tujuan & Filosofi
Recommendation Engine bertugas menerjemahkan hasil pemantauan perilaku ([DetectionResult](file:///e:/LOMBA/mind_drji/lib/app/data/models/detection_result.dart)), [InsightModel](file:///e:/LOMBA/mind_drji/lib/app/data/models/insight_model.dart), dan [BehavioralFeatures](file:///e:/LOMBA/mind_drji/lib/app/data/models/behavioral_features.dart) menjadi pilihan opsi intervensi sadar bagi pengguna.

### Prinsip Utama:
1. **User Autonomy (Kontrol Penuh Pengguna):**
   Recommendation Engine **TIDAK** menjalankan intervensi, memblokir layar, atau mengaktifkan Focus Mode secara sepihak. Seluruh rekomendasi hanya menyajikan opsi yang bebas dipilih pengguna (*User Choice*).
2. **Bebas Diagnosa & Skor Kecanduan:**
   Dilarang keras menyematkan label klinis seperti *"Kamu kecanduan"*, *"Gangguan layar"*, atau skor medis semu.
3. **Bahasa Netral & Konstruktif:**
   Mengedepankan refleksi sadar dan opsi yang realistis untuk dicapai.
4. **Offline First:**
   Diproses 100% secara lokal pada memori perangkat tanpa dependensi jaringan internet.

---

## 2. Arsitektur Alur Kerja

```
   ┌────────────────────────────────────────────────────────┐
   │                    DETECTION TIER                      │
   │ DetectionResult (RuleBasedDetectionStrategy / Drift)   │
   └───────────────────────────┬────────────────────────────┘
                               │
                               ▼
   ┌────────────────────────────────────────────────────────┐
   │                     INSIGHT TIER                       │
   │ InsightModel (InsightEngine / MonitoringVisualization) │
   └───────────────────────────┬────────────────────────────┘
                               │
                               ▼
   ┌────────────────────────────────────────────────────────┐
   │                 RECOMMENDATION ENGINE                  │
   │ Pure Engine: Mapping Rules + Merging + Durations       │
   └───────────────────────────┬────────────────────────────┘
                               │
                               ▼
   ┌────────────────────────────────────────────────────────┐
   │                 RECOMMENDATION OPTIONS                 │
   │ List<RecommendationModel>                              │
   │ (Title, Description, Reason, Durations: 5/15/30m, CTA) │
   └───────────────────────────┬────────────────────────────┘
                               │
                               ▼
   ┌────────────────────────────────────────────────────────┐
   │                      USER CHOICE                       │
   │ Pengguna memilih durasi dan menekan tombol konfirmasi  │
   └───────────────────────────┬────────────────────────────┘
                               │
                               ▼
   ┌────────────────────────────────────────────────────────┐
   │                   INTERVENTION TIER                    │
   │ (Tahap Berikutnya: Jeda Digital, Mode Fokus, Reminder) │
   └────────────────────────────────────────────────────────┘
```

---

## 3. Model Data Rekomendasi

### `RecommendationModel`
- `id`: Pengenal unik berbasis timestamp.
- `type`: Enum `RecommendationType`.
- `title`: Judul tindakan (misal: *"Jeda Digital"*).
- `description`: Penjelasan manfaat tindakan bagi pengguna.
- `reason`: Penjelasan kontekstual mengapa opsi ini disarankan berdasarkan data pemantauan.
- `actionLabel`: Label tombol CTA (misal: *"Mulai Jeda"*, *"Aktifkan Fokus"*).
- `durationOptions`: Daftar integer durasi dalam menit (misal: `[5, 15, 30]`).
- `icon`: Nama ikon representasi visual.
- `relatedDetection`: Pola deteksi yang memicu rekomendasi.
- `generatedAt`: Waktu pembuatan rekomendasi.

### `RecommendationType`
1. `digitalBreak`: Jeda singkat dari pemakaian aplikasi untuk menyegarkan fokus.
2. `focusMode`: Pembatasan gangguan dan godaan membuka aplikasi secara impulsif.
3. `eyeRest`: Mengistirahatkan pandangan mata sesuai kaidah 20-20-20.
4. `nightReminder`: Penjadwalan istirahat malam dan pengurangan cahaya layar.
5. `usageReflection`: Momen hening sejenak untuk meninjau tujuan berselancar.

---

## 4. Pemetaan Deteksi ke Rekomendasi (Rule Mapping)

| Sinyal Deteksi / Bukti | Tipe Rekomendasi | Judul Opsi | Pilihan Durasi | Alasan Transparan |
| :--- | :--- | :--- | :--- | :--- |
| `longScrollSession` / `longSession` | `digitalBreak` | Jeda Digital | 5m, 15m, 30m | Sesi scrolling berlangsung cukup lama. |
| `highScrollActivity` / `highSwipeActivity` | `digitalBreak` | Jeda Digital | 5m, 15m, 30m | Aktivitas swipe dan intensitas scrolling terpantau meningkat. |
| `repeatedScrolling` | `focusMode` | Mode Fokus | 15m, 30m, 60m | Sesi dibuka kembali dalam jeda waktu relatif singkat. |
| `downwardPattern` | `usageReflection` | Refleksi Penggunaan | 5m, 10m, 15m | Pola gulir satu arah secara kontinu teridentifikasi. |
| `nightScrollingPattern` / `nightPattern` | `nightReminder` | Pengingat Malam | 15m, 30m, 45m | Aktivitas scrolling terkonsentrasi pada malam hari. |
| `contextualEyeFatigue` | `eyeRest` | Istirahat Mata | 5m, 10m, 20m | Parameter monitoring menunjukkan indikasi penutupan mata. |
| `multiSignalScrollingPattern` | `digitalBreak` + `focusMode` | Jeda Digital & Mode Fokus | Sesuai konfigurasi | Beberapa pola penggunaan muncul bersamaan secara simultan. |
| **Tidak ada deteksi** | *(Kosong)* | *(Tidak ada)* | - | Tidak memaksa rekomendasi jika penggunaan wajar. |

---

## 5. Penggabungan Duplikasi (Duplicate Merging)
Jika terdapat beberapa bukti perilaku yang memicu jenis rekomendasi yang sama (contoh: `longSession` + `highSwipeActivity` keduanya mengarah pada `digitalBreak`), engine tidak akan menampilkan kartu `digitalBreak` ganda. 

Engine menggabungkannya menjadi **satu kartu rekomendasi kohesif** dengan alasan komprehensif:
> *"Beberapa pola penggunaan menunjukkan sesi scrolling yang panjang dan berulang."*

---

## 6. Konfigurasi Durasi Terpusat (`RecommendationDurations`)
Durasi intervensi dikonfigurasikan secara terpusat pada `RecommendationDurations`:
```dart
class RecommendationDurations {
  static const List<int> digitalBreak = [5, 15, 30]; // menit
  static const List<int> focusMode = [15, 30, 60];    // menit
  static const List<int> eyeRest = [5, 10, 20];       // menit
  static const List<int> nightReminder = [15, 30, 45]; // menit
  static const List<int> usageReflection = [5, 10, 15]; // menit
}
```

---

## 7. Kontrak Intervensi & User Choice
- Tombol aksi pada kartu rekomendasi (`actionLabel`) memicu dialog konfirmasi pilihan.
- Ketika pengguna menekan **"Konfirmasi Pilihan"**, sistem mencatat preferensi pengguna ke dalam observable `selectedRecommendation` dan `userAppliedAction`.
- Intervensi otomatis (Focus Mode / Lock screen / App blocker) **TIDAK** dieksekusi secara sepihak di tahap ini, melainkan menunggu tahap *Intervention Engine*.

---

## 8. Privasi & Isolasi Pengguna
- Recommendation Engine hanya beroperasi pada data `userId` milik pengguna aktif (diambil melalui Supabase Auth UUID dengan fallback `local_user`).
- Tidak ada data yang dibagikan antar pengguna maupun dikirim ke analitik pihak ketiga tanpa izin.
- Tanpa perubahan tabel database (`No DB Schema Change`); rekomendasi dihitung dinamis secara in-memory.

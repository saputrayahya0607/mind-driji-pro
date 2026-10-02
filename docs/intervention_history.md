# DOKUMENTASI INTERVENTION HISTORY & LOCAL PERSISTENCE MIND DRIJI

## 1. Schema Database (Drift SQLite)

Tabel `intervention_history` didefinisikan menggunakan Drift ORM pada `lib/app/data/local/tables/intervention_histories.dart` dan diregistrasikan ke dalam database aplikasi `AppDatabase` (schemaVersion: 6).

### Definisi Tabel:
```sql
CREATE TABLE intervention_history (
    id TEXT NOT NULL PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    started_at INTEGER NOT NULL,
    ended_at INTEGER,
    status TEXT NOT NULL,
    cancelled_at INTEGER,
    source_recommendation_id TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### Rincian Kolom:
- **`id` (TEXT)**: Primary key berbasis UUID v4 (`UuidGenerator.v4()`).
- **`user_id` (TEXT)**: Identifier unik pengguna yang terautentikasi (Supabase Auth UUID) atau `'local_user'` saat unauthenticated. Menjamin isolasi data antar pengguna.
- **`type` (TEXT)**: Jenis intervensi (`digitalBreak`, `eyeRelaxation`, `focusMode`).
- **`title` (TEXT)**: Judul ramah intervensi (contoh: "Jeda Digital", "Istirahat Mata").
- **`duration_minutes` (INTEGER)**: Durasi target dalam menit (misal: 5, 15, 30).
- **`started_at` (INTEGER / DateTime)**: Timestamp saat intervensi dimulai oleh pengguna.
- **`ended_at` (INTEGER / DateTime, Nullable)**: Timestamp saat intervensi selesai atau dibatalkan.
- **`status` (TEXT)**: Status intervensi (`active`, `completed`, `cancelled`).
- **`cancelled_at` (INTEGER / DateTime, Nullable)**: Timestamp saat pengguna membatalkan intervensi secara manual.
- **`source_recommendation_id` (TEXT, Nullable)**: ID rekomendasi asal yang memicu user memulai intervensi ini.
- **`created_at` (INTEGER / DateTime)**: Timestamp pembuatan rekaman lokal.
- **`updated_at` (INTEGER / DateTime)**: Timestamp modifikasi rekaman lokal terakhir.

---

## 2. Lifecycle Intervensi

Alur state intervensi mencerminkan tindakan nyata pengguna (*user choice & control*):

```text
Rekomendasi / Pilihan Pengguna
              ↓
  startIntervention()
  [Status: active]
  [Drift: INSERT record baru dengan ID unik]
              │
      ┌───────┴───────┐
      ▼               ▼
completeIntervention() cancelIntervention()
[Status: completed]    [Status: cancelled]
[endedAt = now]        [cancelledAt = now, endedAt = now]
[Drift: UPDATE record] [Drift: UPDATE record]
```

### Penanganan Lifecycle Restart & Recovery:
- Jika aplikasi ditutup atau mengalami crash saat intervensi sedang berstatus `active`, sistem pemulihan (`_restoreActiveIntervention()`) memeriksa sisa waktu berdasarkan timestamp `endedAt`.
- Jika waktu telah kedaluwarsa saat aplikasi dibuka kembali: intervensi langsung ditandai `completed` dan di-*update* di database.
- Jika waktu masih tersisa: intervensi dilanjutkan dengan sisa waktu yang tepat tanpa membuat record baru di database (`tidak ada duplikasi record`).

---

## 3. Repository Architecture (`InterventionHistoryLocalRepository`)

Repository lokal ini mengelola semua transaksi database SQLite lokal secara asynchronous dan aman:

- **`insert(InterventionModel model)`**: Menyimpan rekaman awal saat intervensi berstatus `active`.
- **`update(InterventionModel model)`**: Memperbarui status intervensi menjadi `completed` atau `cancelled`, mencatat waktu `endedAt` dan `cancelledAt`.
- **`getById(String id, {String? userId})`**: Mengambil satu rekaman spesifik berdasarkan ID dan ID pengguna.
- **`getRecent({String? userId, int limit = 10, int offset = 0, InterventionType? type, DateTime? startDate, DateTime? endDate})`**: Mengambil daftar riwayat intervensi terurut dari yang terbaru (*descending* berdasarkan `started_at`), mendukung filter jenis intervensi, rentang tanggal, dan pagination.
- **`getBetween(DateTime start, DateTime end, {String? userId, InterventionType? type})`**: Mengambil riwayat dalam rentang waktu kalender tertentu.
- **`getByStatus(InterventionStatus status, {String? userId, int limit = 20})`**: Mengambil riwayat berdasarkan status tertentu (misal mencari sesi aktif atau sesi selesai).
- **`getStatistics({String? userId, DateTime? startDate, DateTime? endDate})`**: Menghasilkan agregasi statistik riwayat tanpa klaim medis.

---

## 4. User Isolation & Multi-User Support

Isolasi data pengguna diterapkan secara ketat di layer Repository:
1. Setiap query baca dan tulis secara default mengambil user ID aktif dari sesi Supabase Auth (`supabase.auth.currentUser?.id ?? 'local_user'`).
2. Data antara `user_A` dan `user_B` terpisah secara mutlak melalui klausul `WHERE user_id = :userId`.
3. Pergantian akun (*switch account* / *logout*) tidak akan membocorkan riwayat intervensi pengguna sebelumnya.

---

## 5. Local-First Architecture

Prinsip *Local-First* diimplementasikan secara murni:
- Semua pembacaan dan penyimpanan riwayat dilakukan langsung ke SQLite lokal via Drift.
- Operasi intervensi dapat dimulai, dijalankan, dan diselesaikan dalam kondisi perangkat sepenuhnya *offline* tanpa ketergantungan koneksi jaringan.
- Tidak ada tabel atau migration Supabase jarak jauh yang dibuat pada tahap ini, menjaga database cloud tetap bersih hingga mekanisme sinkronisasi riwayat disiapkan di tahap mendatang.

---

## 6. History States & Non-Judgmental Language

Status yang dicatat hanya menggunakan enumerasi standar:
- `pending`: Menunggu eksekusi (internal contract).
- `active`: Intervensi sedang berlangsung.
- `completed`: Intervensi diselesaikan hingga akhir durasi.
- `cancelled`: Intervensi dihentikan lebih awal atas inisiatif pengguna.

### Kebijakan Bahasa Non-Judgmental:
- Label UI hanya menggunakan: **"Selesai"** dan **"Dibatalkan"**.
- DILARANG menggunakan kata "Berhasil", "Gagal", "Kalah", atau "Kambuh".
- Penghentian intervensi oleh pengguna adalah keputusan sadar pengguna (*user autonomy*) dan bukan sebuah kegagalan.

---

## 7. Filtering & Navigation

Modul riwayat (`/intervention-history`) menyediakan kemampuan filter multidimensi:
1. **Filter Jenis Intervensi (Type Filter)**:
   - `Semua`: Menampilkan seluruh aktivitas.
   - `Jeda Digital`: Khusus aktivitas `InterventionType.digitalBreak`.
   - `Istirahat Mata`: Khusus aktivitas `InterventionType.eyeRelaxation`.
2. **Filter Rentang Waktu (Date Range Filter)**:
   - `Semua`: Seluruh waktu riwayat tercatat.
   - `Hari Ini`: Rentang jam 00:00:00 hingga 23:59:59 hari ini.
   - `Minggu Ini`: Dari hari Senin minggu berjalan hingga Minggu malam.
   - `Bulan Ini`: Dari tanggal 1 bulan berjalan hingga akhir bulan.
3. **Pagination**:
   - Secara default memuat 10 item terbaru.
   - Tombol **"Muat Lebih Banyak"** memuat 10 item berikutnya secara bertahap tanpa membebani memori (*lazy batch loading*).

---

## 8. Statistics Aggregation

Data agregasi dihitung secara objektif:
- `totalCount`: Jumlah total intervensi yang pernah dimulai.
- `completedCount`: Jumlah intervensi yang diselesaikan hingga tuntas.
- `cancelledCount`: Jumlah intervensi yang dibatalkan oleh pengguna.
- `totalDurationMinutes`: Total menit intervensi yang berhasil diselesaikan.
- `digitalBreakCount`: Jumlah sesi Jeda Digital.
- `eyeRelaxationCount`: Jumlah sesi Istirahat Mata.
- `focusModeCount`: Jumlah sesi Mode Fokus (disiapkan untuk tahap mendatang, saat ini bernilai 0).

### Kebijakan Etika Data:
- **TIDAK ADA** "Health Score", "Addiction Score", atau kalkulasi "Tingkat Keberhasilan Medis".
- Metrik hanya merepresentasikan catatan durasi dan frekuensi penggunaan fitur aplikasi.

---

## 9. Privacy & Security

- **Data Sensitif**: Tidak ada konten layar, teks ketikan, pesan pribadi, rekaman kamera, atau riwayat penjelajahan web yang disimpan dalam tabel riwayat.
- **Kamera**: Data relaksasi mata hanya mencatat durasi menit sesi, tidak pernah menyimpan rekaman video atau foto wajah pengguna.
- **Penyimpanan Lokal**: Database SQLite tersimpan di direktori privat aplikasi terlindung oleh sandboxing sistem operasi Android.

---

## 10. Limitations & Future Stage

- **Focus Mode**: Tetap berada dalam status *Audit / Contract Only*. Tidak ada record palsu atau manipulasi riwayat untuk fitur yang belum diaktifkan.
- **Cloud Sync**: Sinkronisasi riwayat ke Supabase akan diintegrasikan pada tahap selanjutnya melalui `SyncQueue` dan tabel `user_interventions`.
- **Analisis Lanjutan**: Visualisasi korelasi mendalam antara riwayat intervensi dan penurunan screen time akan disajikan pada tahap pelaporan komprehensif.

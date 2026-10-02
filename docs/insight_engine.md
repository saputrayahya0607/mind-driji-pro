# Insight Engine - MIND DRIJI

## 1. Tujuan
Insight Engine berfungsi untuk menerjemahkan data mentah pemantauan (*Screen Time*, *Doomscrolling*, dan *Eye Monitoring*) serta hasil deteksi (*DetectionResult*) menjadi ringkasan reflektif yang:
- **Faktual**: Berdasarkan angka dan catatan riil penggunaan.
- **Mudah Dipahami**: Menggunakan kartu ringkas dengan metrik angka dan ikon yang jelas.
- **Non-Judgmental & Non-Diagnostic**: Tidak pernah menghakimi pengguna, tidak memberi label kecanduan, dan tidak mendiagnosis penyakit medis.
- **Action-Oriented (User Choice)**: Memberikan saran langkah mandiri (*suggested action*) yang keputusannya berada 100% di tangan pengguna.

---

## 2. Arsitektur & Alur Data
Insight Engine beroperasi di atas lapisan Detection Engine:

$$\text{Raw Data (Drift / UsageStats)} \longrightarrow \text{Detection Engine} \longrightarrow \text{DetectionResult} \longrightarrow \textbf{Insight Engine} \longrightarrow \textbf{InsightModel List} \longrightarrow \text{Insight UI}$$

```
┌───────────────────────────────────────────────┐
│ Raw Monitoring Data (Drift DB, UsageStats)    │
└───────────────────────┬───────────────────────┘
                        ▼
┌───────────────────────────────────────────────┐
│ Detection Engine (Behavioral Detection Layer) │
└───────────────────────┬───────────────────────┘
                        ▼
┌───────────────────────────────────────────────┐
│ DetectionResult + Visualization Aggregation   │
└───────────────────────┬───────────────────────┘
                        ▼
┌───────────────────────────────────────────────┐
│ InsightEngine                                 │
│ - Scrolling Insight Generation                │
│ - Screen Time & Distribution Insight          │
│ - Eye Monitoring Context Insight              │
│ - Suggested Action Generator                  │
└───────────────────────┬───────────────────────┘
                        ▼
┌───────────────────────────────────────────────┐
│ List<InsightModel>                            │
│ - Sorted by display priority (High->Med->Low) │
└───────────────────────┬───────────────────────┘
                        ▼
┌───────────────────────────────────────────────┐
│ InsightController + InsightView               │
│ (Period Tabs: Hari / Minggu / Bulan)          │
└───────────────────────────────────────────────┘
```

---

## 3. Input & Output
### Input
1. **`DetectionResult`**: Hasil deteksi perilaku dari `DetectionService`.
2. **`BehavioralFeatures`**: Parameter kuantitatif (durasi, jumlah swipe, rasio downward, sesi malam, dsb).
3. **`EyeMonitoringSummary`**: Ringkasan mata (durasi, rata-rata EAR, kedipan, kejadian penutupan mata).
4. **`MonitoringVisualizationData`**: Breakdown segmen harian (Dini Hari, Pagi, Siang, Sore, Malam), harian mingguan (Senin–Minggu), dan mingguan bulanan (Week 1–5).

### Output
Koleksi objek `InsightModel` dengan atribut:
- `id`: Pengenal unik insight.
- `type`: Kategori insight (`scrolling`, `screenTime`, `eyeMonitoring`, `usagePattern`, `recommendation`).
- `title`: Judul ringkas faktual.
- `summary`: Ringkasan 1–2 kalimat.
- `details`: Penjelasan data lebih lengkap.
- `evidences`: Daftar bukti terukur (`InsightEvidenceItem`: label + value + icon).
- `relatedApps`: Daftar nama aplikasi yang terlibat.
- `period`: Rentang periode ('daily', 'weekly', 'monthly').
- `generatedAt`: Waktu pembuatan insight.
- `suggestedAction`: Saran tindakan reflektif (opsional).
- `priority`: Urutan presentasi tampilan (`high`, `medium`, `low`).

---

## 4. Insight Types & Aturan Pembentukan
### A. Scrolling Insight (`InsightType.scrolling`)
- **Long Session**: Muncul jika ada sesi $\ge 20$ menit.
  - *Title*: "Sesi scrolling panjang terdeteksi"
  - *Evidence*: Sesi terpanjang, total sesi, total swipe.
  - *Suggested Action*: "Jeda Digital"
- **Repeated Scrolling**: Muncul jika ada $\ge 3$ sesi berulang dengan jeda $\le 15$ menit.
  - *Title*: "Sesi scrolling berulang"
  - *Evidence*: Jumlah sesi, sesi berulang, rata-rata jeda.
  - *Suggested Action*: "Jeda Digital"
- **High Scroll Activity**: Muncul jika swipe $\ge 300$.
  - *Title*: "Aktivitas scrolling meningkat"
  - *Evidence*: Total swipe, rata-rata swipe/sesi, total durasi.
  - *Suggested Action*: "Mode Fokus"
- **Night Scrolling Pattern**: Muncul jika $\ge 3$ sesi terjadi pada malam/dini hari.
  - *Title*: "Aktivitas scrolling pada malam hari"
  - *Evidence*: Sesi malam, sesi dini hari, aplikasi utama.
  - *Suggested Action*: "Pengingat Istirahat"
- **Multi-Signal Scrolling**: Muncul jika terdapat kombinasi $\ge 2$ sinyal perilaku utama.
  - *Title*: "Beberapa pola scrolling terdeteksi"
  - *Evidence*: Sesi terpanjang, total swipe, sesi berulang.
  - *Suggested Action*: "Mode Fokus"
- **No Detection / Normal**:
  - *Title*: "Belum ada pola scrolling khusus yang terdeteksi"
  - *Summary*: "Pola penggunaan aplikasi berada dalam rentang normal berdasarkan data pemantauan."

### B. Screen Time & Distribution Insight (`InsightType.screenTime` & `usagePattern`)
- **Daily**: Menghitung segmen paling dominan (Dini Hari, Pagi, Siang, Sore, Malam).
  - Contoh: *"Aktivitas scrolling paling banyak tercatat pada malam hari."*
- **Weekly**: Menemukan hari puncak (Senin–Minggu).
  - Contoh: *"Pada minggu ini, sesi scrolling paling banyak tercatat pada hari Rabu."*
- **Monthly**: Menemukan minggu puncak (Week 1–Week 5).
  - Contoh: *"Akumulasi aktivitas penggunaan tertinggi tercatat pada Week 2."*

### C. Eye Monitoring Insight (`InsightType.eyeMonitoring`)
- Jika penutupan mata $\ge 5$ atau $\text{EAR} < 0.22$:
  - *Title*: "Indikasi Mata Lelah"
  - *Summary*: "Terdapat indikasi mata mulai lelah berdasarkan parameter monitoring aplikasi."
  - *Evidence*: Penutupan mata (kali), kedipan mata, rata-rata EAR.
  - *Suggested Action*: "Istirahatkan Mata (Aturan 20-20-20)"
- Jika parameter normal:
  - *Title*: "Pemantauan Kondisi Mata"
  - *Summary*: "Parameter kedipan dan keterbukaan mata terpantau dalam rentang terukur."

---

## 5. Pedoman Bahasa & Wording
1. **DILARANG MENGGUNAKAN**:
   - "Kamu kecanduan", "Kamu mengalami adiksi", "Kamu tidak bisa mengontrol diri"
   - "Skor kesehatan digital", "Tingkat kecanduan Rendah/Tinggi"
   - "Mata kamu rusak/sakit" atau diagnosis klinis lainnya.
2. **GUNAKAN SELALU**:
   - Frasa observasional: *"Pola scrolling terdeteksi"*, *"Aktivitas meningkat"*, *"Indikasi mata lelah berdasarkan parameter monitoring aplikasi"*.
   - Frasa saat tidak ada deteksi: *"Belum ada pola scrolling khusus yang terdeteksi"*, bukan mengklaim "Penggunaanmu sehat".

---

## 6. Kontrak Intervensi (*Intervention Contract*)
Sistem menerapkan alur:
$$\text{Insight} \longrightarrow \text{Suggested Action} \longrightarrow \textbf{Pilihan Pengguna} \longrightarrow \text{Intervensi (Jeda/Fokus)}$$
- Insight **TIDAK PERNAH** secara sepihak memblokir aplikasi atau mengaktifkan Focus Mode tanpa izin.
- Tombol tindakan berlabel *"Lihat Pilihan"* atau *"Mulai Jeda"*, yang menampilkan konfirmasi dialog atau mencatat pilihan pengguna secara mandiri.

---

## 7. Batasan & Privasi
- **Privasi**: Hanya membaca durasi, arah gesekan, timestamp sesi, dan agregat kedipan mata. Tidak pernah menyentuh isi feed, video, teks postingan, chat, screenshot, atau foto kamera.
- **Keterbatasan**: Insight adalah ringkasan metadata perilaku, bukan evaluasi psikologis atau diagnosis medis.
- **Offline-First**: Semua perhitungan insight diproses secara lokal dari database Drift dan memori perangkat tanpa memerlukan koneksi internet aktif.
- **Isolasi Pengguna**: Data dipisahkan secara ketat menggunakan Supabase Auth User UUID.

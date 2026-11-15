# Performance Findings

## Informasi pemeriksaan

- Project: Campus Notify (`campus_notify/`).
- Tanggal pengerjaan: 12 November 2026.
- Lingkungan: Windows, Flutter 3.47.5, Dart 3.13.4, DevTools 2.60.0.
- Perangkat yang terdeteksi: Windows, Chrome, Edge; Android/iOS belum tersambung.
- Mode DevTools: **belum dijalankan**. Temuan di bawah berasal dari inspeksi kode dan tes, bukan Flame Chart.
- Skenario target: daftar → scroll cepat → detail → kembali → pull-to-refresh.

## Baseline sebelum optimasi

| Metrik | Hasil |
|---|---|
| Rata-rata frame time UI/raster | Belum diukur |
| Frame merah / kuning | Belum diukur |
| Used heap / external memory | Belum diukur |
| Fungsi dominan Flame Chart | Belum direkam |
| Screenshot baseline | Belum tersedia; target `../screenshots/before-profile.png` |

## Temuan inspeksi kode yang perlu dikonfirmasi dengan profiling

### 1. Pembacaan dan pemetaan seluruh catatan berulang

- Lokasi awal: `campus_notify/lib/features/notes/data/repositories/note_repository_impl.dart`, `fetchNotes`.
- Bukti kode: setiap pemanggilan membuka akses database, menjalankan query terurut, lalu memetakan semua baris menjadi entity. Tidak ada cache hasil atau penggabungan pemanggilan yang berjalan bersamaan.
- Pemanggil: provider daftar dan dialog catatan offline pada chat. Riverpod sudah menyimpan hasil provider daftar; manfaat cache repository terutama berlaku pada pembacaan langsung dan invalidasi/provider baru.
- Perbaikan: decorator `CachedNoteRepository`, cache 30 detik dan penggabungan future. Penulisan berhasil serta pull-to-refresh membatalkan cache; error tidak disimpan.
- Verifikasi: tes menghitung pembacaan sumber, kedaluwarsa, immutable snapshot, invalidasi, konkurensi, dan hasil lama setelah refresh. Dampak CPU/frame/memory masih harus diukur.
- Bukti DevTools yang diperlukan: CPU query/map pada pembacaan dingin/hangat. Ini akses SQLite lokal, **bukan request HTTP**.

### 2. Isi penuh catatan dibangun pada setiap item daftar

- Lokasi awal: `campus_notify/lib/features/notes/presentation/widgets/notes_list.dart`.
- Bukti kode: `Text(note.body)` tanpa `maxLines`; item panjang dapat memerlukan layout teks besar serta membuat tinggi item tidak terkendali. Daftar **sudah memakai ListView.builder** sebelum perubahan.
- Perbaikan: `NoteTile` terpisah dengan const constructor, key, judul satu baris, preview dua baris, dan detail berisi teks lengkap. Lazy builder dipertahankan.
- Verifikasi: widget test dengan 500 catatan panjang memastikan jumlah widget awal kurang dari jumlah dataset, navigasi detail menampilkan isi lengkap, dan item terakhir dapat dicapai.
- Batas klaim: `const` constructor pada widget berparameter runtime tidak otomatis membuat setiap instance const atau mencegah seluruh rebuild. Profiling layout/build masih diperlukan.

### 3. Decode gambar lokal tanpa batas ukuran tampilan

- Lokasi awal: `campus_notify/lib/features/chat_screen.dart`, `_MessageBubble.build`.
- Bukti kode: gambar ditampilkan 220 × 160 logical pixel melalui `Image.file`, tanpa `cacheWidth`. Image picker membatasi ukuran 1600 × 1600 tetapi itu masih lebih besar daripada kebutuhan thumbnail pada banyak DPR.
- Perbaikan: `cacheWidth = ceil(220 × devicePixelRatio)`. Hanya lebar ditentukan agar decode mempertahankan rasio gambar. `BoxFit.cover` tetap mengatur pemotongan tampilan.
- Verifikasi yang diperlukan: rekam gambar identik sebelum/sesudah, periksa image decode, external memory, ketajaman gambar, serta clipping. Tidak ada klaim penghematan terukur saat ini.
- Batas: untuk foto sangat tinggi, sisi tinggi masih bisa besar; cacheWidth bukan batas total byte gambar. File lokal tidak memerlukan CachedNetworkImage.

## Memory dan pemeriksaan lain

Inspeksi menunjukkan chat sudah membuang TextEditingController, ScrollController, timer rekaman, dan AudioRecorder pada `dispose`; router juga dibuang. Ini **tidak membuktikan tidak ada leak**. Stream AI dan objek lain tetap perlu diperiksa melalui retaining path. Cache menyimpan satu snapshot daftar, bukan seluruh riwayat pembacaan, tetapi daftar itu tetap memuat semua catatan; pagination belum diterapkan.

- [x] Pembuatan daftar dan akses repository diperiksa pada kode.
- [x] Konfigurasi decode gambar diperiksa pada kode.
- [x] Lifecycle controller/timer ditinjau pada kode.
- [ ] Rebuild berulang dikonfirmasi melalui Flame Chart.
- [ ] Image decode diperiksa pada timeline/raster dan Memory.
- [ ] HTTP event diperiksa; jangan menganggap query SQLite sebagai HTTP.
- [ ] Heap snapshot sebelum/sesudah lima kali navigasi dibandingkan.

## Kesimpulan

Tiga kandidat optimasi ditemukan melalui inspeksi: pembacaan sumber berulang, layout preview tanpa batas, dan decode gambar tanpa target ukuran. Perbaikannya sudah ada pada source, tetapi status bottleneck serta besarnya manfaat belum dapat disimpulkan sebelum pengukuran DevTools. Ikuti prosedur yang sama pada [README](../README.md) dan catat hasil pada [laporan](performance-report.md).

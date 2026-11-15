# Week 11 — Performance Optimization

## Project dan status

Project: **Campus Notify**, hasil lanjutan Minggu 7–10. Source Flutter berada di `campus_notify/lib/` beserta konfigurasi platform di `campus_notify/`. Dokumen ini mengikuti [praktikum](https://jti-polinema.github.io/flutter-codelab/11-minggu-11-performance-optimization/index.html#6) dan [tugas](https://jti-polinema.github.io/flutter-codelab/11-minggu-11-performance-optimization/index.html#7).

**Implementasi optimasi tersedia; pengumpulan belum lengkap karena pengukuran DevTools mobile belum dilakukan.** Jangan menganggap temuan inspeksi kode sebagai hasil profiling. Tidak ada screenshot atau angka performa buatan.

```text
11-week-11-performance-optimization/
├── campus_notify/       # project Flutter; lib/, test/, pubspec.yaml, android/, ios/, ...
├── docs/
│   ├── performance-findings.md
│   └── performance-report.md
├── screenshots/         # lokasi bukti DevTools yang masih harus direkam
└── README.md
```

## Menjalankan dan memeriksa

```powershell
cd 11-week-11-performance-optimization/campus_notify
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter devices
flutter run -d <id-android-atau-ios> --profile
```

Aplikasi utama tetap menggunakan Firebase dan autentikasi dari project sebelumnya. Setelah login, pilih **Catatan offline**, ketuk item untuk membuka detail, kembali, lalu tarik daftar untuk refresh. Daftar kosong juga mendukung refresh. Catatan berasal dari database lokal; pada instalasi baru daftar bisa kosong. Gunakan dataset identik berisi cukup banyak catatan untuk kedua pengukuran, bukan daftar kosong. Gambar diuji terpisah di halaman chat dengan gambar lokal yang sama.

Lingkungan pemeriksaan: Flutter 3.47.5, Dart 3.13.4, DevTools 2.60.0, Windows. `flutter devices` mendeteksi Windows, Chrome, dan Edge; tidak ada Android/iOS tersambung. SQLite `sqflite` dan Firebase project ini ditujukan untuk mobile; perangkat web/desktop yang terdeteksi bukan pengganti pengukuran mobile.

**Hasil aktual:** `flutter analyze --no-pub` → **No issues found**; `flutter test --reporter expanded --concurrency=1` → **17 tests passed**. Tes dijalankan dengan TEMP/TMP di workspace karena drive C: penuh. Rincian pada [laporan](docs/performance-report.md).

## Optimasi

1. **Repository cache:** snapshot immutable, TTL 30 detik, penggabungan pembacaan paralel, invalidasi setelah penulisan berhasil dan pull-to-refresh. Hasil error tidak di-cache; hasil query lama tidak boleh mengisi ulang cache setelah invalidasi.
2. **Ekstraksi widget:** `NoteTile` dengan const constructor dan key stabil. Isi daftar dibatasi dua baris; isi lengkap tetap tersedia di detail. `ListView.builder` yang sudah ada dipertahankan.
3. **Optimasi gambar:** `Image.file.cacheWidth` mengikuti lebar 220 logical pixel dikali device pixel ratio. Satu dimensi decode ditentukan agar rasio aspek asli tetap dipertahankan sebelum `BoxFit.cover`.

## Prosedur praktikum

1. Siapkan checkout baseline dari versi sebelum optimasi di lokasi terpisah. Project Minggu 10 menjadi referensi sumber awal; jangan menimpa working tree ini. Jalankan baseline dan versi optimasi dengan perangkat, dataset, build mode, dan durasi rekaman sama. Baseline belum memiliki tombol daftar/detail/refresh: tambahkan alur pengujian setara pada salinan baseline, tanpa cache, batas preview, atau batas decode gambar, agar hasil dapat dibandingkan.
2. Jalankan mode profile, buka URL DevTools dari terminal. Di Performance, rekam skenario: buka daftar → scroll cepat → buka detail → kembali → pull-to-refresh. Samakan jumlah scroll, jumlah item, serta durasi; lakukan pemanasan dahulu dan ulangi rekaman sedikitnya tiga kali. Pisahkan pengukuran cache dingin dan hangat.
3. Catat rata-rata durasi UI/raster dari frame yang direkam dan definisi agregasi yang dipakai, jumlah frame melewati budget perangkat, frame merah/kuning sesuai chart, serta fungsi dominan Flame Chart. Catat refresh rate; budget 60 Hz = 16,67 ms, 120 Hz = 8,33 ms. Jangan menyamakan warna chart dengan budget semua perangkat.
4. Simpan screenshot Flame Chart baseline ke `screenshots/before-profile.png` dan versi optimasi ke `screenshots/after-profile.png`. Simpan juga ekspor timeline agar angka dapat diperiksa kembali. Uji decode gambar di rekaman terpisah dengan file dan DPR identik.
5. Di Memory, ambil heap snapshot pada daftar setelah GC; buka detail dan kembali **lima kali**, GC lagi, lalu ambil snapshot kedua. Bandingkan retained instances dan retaining path. Heap meningkat saja belum membuktikan leak.
6. Lengkapi metrik dan bukti pada dua dokumen laporan. Jalankan analyze/test, tinjau perubahan, lalu commit/push sesuai tujuan remote pengumpulan.

## Refleksi

**Optimasi paling berdampak?** Belum dapat ditentukan tanpa profiling. Cache terbukti dapat mengurangi pembacaan repository lewat tes penghitung; itu belum membuktikan frame time turun. Batas decode berpotensi mengurangi external memory gambar dan preview membatasi layout teks, dengan dampak tergantung dataset.

**Bagaimana menghindari placebo?** Bandingkan profile build pada perangkat dan skenario sama, gunakan rekaman berulang, periksa Flame Chart dan heap, serta pisahkan cache dingin/hangat. Tes memastikan fungsi tetap benar; tes bukan pengganti DevTools.

**Trade-off?** Cache menambah aturan freshness dan kemungkinan data kedaluwarsa maksimal 30 detik bila SQLite diubah dari luar repository; pull-to-refresh memaksa pembacaan baru. Preview mengharuskan pengguna membuka detail untuk membaca isi lengkap. Decode lebih kecil menghemat memori tetapi perlu diperiksa ketajamannya. Ekstraksi widget membantu pemisahan kode, tetapi tidak otomatis menghilangkan semua rebuild.

**Kapan menghindari premature optimization?** Saat belum ada bukti bottleneck atau perubahan hanya menambah kompleksitas. Pagination dan RepaintBoundary tambahan belum diterapkan: daftar sudah lazy dan belum ada bukti bahwa keduanya diperlukan. ListView.builder sendiri sudah menambahkan repaint boundary pada anak secara default.

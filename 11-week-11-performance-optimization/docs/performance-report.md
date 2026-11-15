# Performance Optimization Report

## 1. Informasi project

- Project: **Campus Notify**, lanjutan Minggu 7–10.
- Framework/SDK: Flutter 3.47.5, Dart 3.13.4; DevTools 2.60.0.
- Tanggal pengerjaan: 12 November 2026.
- Lingkungan pemeriksaan otomatis: Windows.
- Perangkat profile mobile: belum tersedia; hasil `flutter devices` hanya Windows, Chrome, Edge.
- Status: implementasi dan pemeriksaan otomatis dikerjakan; baseline, profiling sesudah, dan heap snapshot **belum diukur**.

## 2. Tujuan dan metode

Mengurangi pekerjaan berulang saat membaca catatan lokal, membatasi layout preview, dan menyesuaikan ukuran decode gambar. Skenario utama: buka daftar, scroll cepat, buka detail, kembali, pull-to-refresh. Pengujian gambar dilakukan terpisah pada chat dengan gambar lokal identik. Prosedur lengkap dan kontrol perangkat/dataset tersedia pada [README](../README.md).

Baseline harus memakai source sebelum optimasi. Project Minggu 10 dapat menjadi referensi; alur pengujian daftar/detail/refresh perlu disetarakan terlebih dahulu. Tanpa itu, membandingkan halaman chat lama dengan halaman catatan baru tidak menghasilkan eksperimen yang adil. Belum ada pengukuran baseline yang tersimpan sebelum perubahan ini; jangan menyebut rekaman versi optimasi sebagai baseline.

## 3. Baseline metrics dan hasil setelah optimasi

| Metrik | Sebelum | Sesudah | Perubahan |
|---|---|---|---|
| Rata-rata frame time UI | Belum diukur | Belum diukur | Belum dapat dihitung |
| Rata-rata frame time raster | Belum diukur | Belum diukur | Belum dapat dihitung |
| Jumlah frame merah | Belum diukur | Belum diukur | Belum dapat dihitung |
| Jumlah frame kuning | Belum diukur | Belum diukur | Belum dapat dihitung |
| Used Dart heap setelah GC | Belum diukur | Belum diukur | Belum dapat dihitung |
| External memory | Belum diukur | Belum diukur | Belum dapat dihitung |
| Fungsi dominan Flame Chart | Belum direkam | Belum direkam | Belum dapat dibandingkan |

Screenshot yang masih harus diambil dari DevTools:

- `screenshots/before-profile.png` untuk baseline.
- `screenshots/after-profile.png` untuk versi optimasi.

Tidak ada screenshot contoh atau angka perkiraan yang dijadikan bukti. Screenshot saja tidak cukup untuk menghitung rata-rata; simpan juga ekspor timeline, durasi rekaman, jumlah frame, refresh rate, dan definisi perhitungan yang dipakai. Penurunan metrik dapat dihitung `(sebelum - sesudah) / sebelum × 100%` bila baseline bukan nol.

## 4. Temuan

Ketiganya adalah **temuan inspeksi kode**, belum menjadi bottleneck yang dikonfirmasi lewat DevTools:

1. `NoteRepositoryImpl.fetchNotes` selalu membaca dan memetakan seluruh hasil SQLite pada setiap panggilan langsung. Provider daftar sendiri sudah menyimpan hasil; jangan menghitung setiap rebuild sebagai query baru.
2. `NotesList` menampilkan seluruh body dalam item daftar tanpa batas baris. Catatan panjang dapat memperbesar pekerjaan layout; builder lazy sudah ada sebelumnya.
3. `Image.file` pada bubble chat mengatur ukuran tampilan 220 × 160 tetapi belum mengatur ukuran decode. Picker membatasi ukuran sumber 1600 × 1600; itu masih berbeda dari target decode thumbnail.

Bukti kode, batas klaim, dan rencana verifikasi rinci: [performance-findings.md](performance-findings.md).

## 5. Optimasi yang diterapkan

### A. Cache repository dengan TTL dan penggabungan pembacaan

File: `campus_notify/lib/features/notes/data/repositories/cached_note_repository.dart` serta `data/providers/note_data_providers.dart`.

Decorator tetap mengikuti kontrak domain `NoteRepository`. Hasil sukses disalin menjadi daftar immutable dan disimpan selama 30 detik. Pemanggilan saat query berjalan berbagi future yang sama. Error tidak disimpan. Penulisan sukses membatalkan cache; pull-to-refresh juga membatalkan cache sebelum memuat provider. Nomor generasi mencegah hasil query lama mengisi ulang cache setelah invalidasi.

Alasan: membatasi query dan pemetaan berulang dari konsumen berbeda, termasuk dialog offline chat. Ini cache-first untuk database lokal; bukan stale-while-revalidate atau cache HTTP. SQLite tetap menjadi penyimpanan persisten dan sumber data offline.

Trade-off: snapshot tetap menyimpan seluruh daftar di memori, tidak menyelesaikan skala dataset tak terbatas. Perubahan database di luar decorator baru terbaca setelah TTL atau refresh. Masa berlaku diperiksa saat ada pembacaan, tanpa timer background. Provider FutureProvider dapat menyimpan hasil lebih lama dari TTL sampai diinvalidasi; TTL repository bukan mekanisme refresh UI berkala.

### B. Ekstraksi widget dan pembatasan preview

File: `campus_notify/lib/features/notes/presentation/widgets/notes_list.dart`.

`NoteTile` memiliki const constructor dan key berdasarkan ID (fallback index bila ID tidak ada). Judul dibatasi satu baris dan body dua baris. Navigasi detail tetap menampilkan body lengkap. `ListView.builder` dipertahankan, termasuk repaint boundary bawaan delegate. Tidak ada klaim bahwa constructor const saja menghilangkan rebuild karena objek note tetap merupakan parameter runtime.

Alasan: menghindari menampilkan body panjang seluruhnya di daftar sambil mempertahankan akses ke isi lengkap. Jumlah widget awal tetap mengikuti viewport; jumlah entity dalam repository masih mengikuti seluruh data.

### C. Ukuran decode gambar mengikuti layar

File: `campus_notify/lib/features/chat_screen.dart`, `_MessageBubble`.

`Image.file` kini memakai `cacheWidth = ceil(220 × DPR)`. Tinggi decode tidak dipaksa sehingga rasio aspek sumber dipertahankan, sedangkan `BoxFit.cover` tetap melakukan cropping visual. Error placeholder tetap tersedia. File lokal tidak memerlukan package cache jaringan tambahan.

Alasan: ukuran decode sumber dapat melebihi kebutuhan thumbnail. Penghematan external memory dan kualitas gambar tetap harus diperiksa pada perangkat nyata, terutama untuk foto tinggi/panorama dan DPR tinggi.

### Alur pendukung profiling

`HomePage` menyediakan tombol Catatan offline; `NotesList` membuka detail; `NotesPage` mendukung pull-to-refresh termasuk ketika daftar kosong. Perubahan ini memungkinkan skenario codelab dijalankan. Baseline perlu alur setara untuk perbandingan yang adil.

## 6. Pemeriksaan memory

| Pemeriksaan | Hasil |
|---|---|
| Heap snapshot awal pada daftar setelah GC | Belum diambil |
| Heap snapshot setelah detail–kembali lima kali dan GC | Belum diambil |
| Objek tertahan / retaining path | Belum diperiksa di DevTools |
| Memory leak terkonfirmasi | Belum dapat disimpulkan |

Inspeksi kode menunjukkan disposal controller, timer, recorder, dan router sudah ada. Tidak ditambahkan perbaikan leak tanpa bukti. Pemeriksaan berikutnya harus mencakup State/detail, controller, stream AI, dan retensi snapshot cache. Bandingkan retained instances setelah GC; kenaikan heap sementara atau aktivitas image cache bukan bukti tunggal leak.

## 7. Verifikasi otomatis

- **`flutter analyze --no-pub`: PASS — No issues found! (41,0 detik).**
- **`flutter test --reporter expanded --concurrency=1`: PASS — 17 tests passed (6 menit 20 detik).**

Tes regresi baru:

- `test/cached_note_repository_test.dart`: cache hit, TTL 30 detik, immutable snapshot, invalidasi manual, penulisan, kegagalan yang tidak di-cache, pembacaan paralel, dan hasil lama yang tidak menimpa refresh.
- `test/notes_list_test.dart`: 500 catatan panjang, pembangunan lazy, preview dua baris, detail lengkap, kembali, dan scroll ke item terakhir.

Tes existing auth/push, AI service, use case catatan, dan widget login tetap dijalankan. Penghitung query pada fake repository membuktikan perilaku cache, bukan percepatan SQLite atau penurunan frame time.

Percobaan awal `flutter test` gagal karena drive C: tidak cukup ruang untuk berkas compiler sementara (OS error 112). Pengujian diulang dengan TEMP/TMP pada `campus_notify/.tmp-week11/` di E: dan concurrency 1. Folder sementara diabaikan oleh Git. Ini penyesuaian lingkungan tes, bukan perubahan perilaku aplikasi.

## 8. Kesimpulan dan pekerjaan tersisa

Tiga teknik optimasi tersedia pada source dengan alasan yang dapat ditinjau. Belum ada dasar untuk mengklaim FPS naik, jank berkurang, memory turun, atau memilih optimasi paling berdampak. Penyelesaian empiris membutuhkan perangkat mobile mode profile, baseline sebanding, rekaman before/after, serta heap snapshot lima kali navigasi. Checklist pada README membedakan pekerjaan implementasi dan bukti pengukuran yang belum tersedia.

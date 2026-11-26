# Campus Notify · Week 12

Buka **Catatan offline** dari beranda, lalu tekan **Tambah catatan**. Judul wajib diisi dan spasi di awal serta akhir judul dibuang sebelum penyimpanan. Isi catatan boleh kosong. Setelah catatan disimpan, pengguna kembali ke daftar dan bisa membuka detailnya.

## Skenario pengujian

| Skenario | Perilaku yang diharapkan | Pengujian |
| --- | --- | --- |
| Daftar awal kosong | Halaman menampilkan pesan “Belum ada catatan.” dan tombol tambah. | Widget |
| Judul kosong atau hanya whitespace | Formulir menampilkan pesan validasi. Operasi penyimpanan tidak dipanggil. | Unit dan widget |
| Judul satu karakter dan isi kosong (kasus tepi) | Judul diterima setelah dirapikan dan isi tersimpan sebagai string kosong. | Unit |
| Judul valid dengan spasi di awal dan akhir | Judul disimpan setelah dirapikan, isi tetap utuh, dan catatan langsung muncul di daftar. | Unit, widget, dan integrasi |
| Repository gagal menyimpan | Pesan kegagalan tampil, masukan tetap ada, dan pengguna bisa mencoba lagi. Daftar tidak bertambah selama penyimpanan gagal. | Unit dan widget |
| Repository gagal membaca | Use case meneruskan kegagalan; UI menampilkan pesan dan tombol Coba Lagi. Setelah repository pulih, tombol tersebut memuat ulang daftar. | Unit dan widget |
| Buat dan buka catatan dari beranda | Navigasi beranda → daftar → formulir → daftar → detail berjalan. Judul dan isi dapat dibaca melalui repository baru, tampil di detail, lalu tombol kembali membuka daftar. | Widget alur aplikasi dan integrasi |

## Susunan test suite

- [Unit test penambahan catatan](test/add_note_test.dart) dan [unit test pembacaan daftar](test/get_notes_test.dart) dikelompokkan berdasarkan use case. Keduanya memakai [fake repository](test/support/fake_note_repository.dart) dengan hasil sukses dan kegagalan yang bisa ditentukan oleh setiap test.
- [Widget test](test/notes_screen_test.dart) membuat fake dan cache baru untuk setiap skenario agar data dan kegagalan tidak terbawa ke test berikutnya.
- [Integration test](integration_test/app_test.dart) memakai widget aplikasi, navigasi, Riverpod, cache, use case, dan repository JSON asli. Sesi login dan media penyimpanan JSON disediakan dari memori agar pengujian tidak bergantung pada jaringan atau data perangkat. Pengujian ini tidak mencakup inisialisasi Firebase, login ke server, atau plugin SQLite perangkat.
- [Widget test alur aplikasi](test/app_flow_test.dart) menjalankan [skenario yang sama](test/support/notes_app_flow.dart) tanpa emulator. Pemeriksaan ini masuk dalam `flutter test`; eksekusinya tidak menggantikan verifikasi integrasi pada perangkat.

## Menjalankan pemeriksaan

Jalankan dari folder ini. Unit test, widget test, dan alur aplikasi dapat diperiksa tanpa emulator:

```powershell
flutter pub get
flutter test
flutter analyze
```

Untuk menjalankan alur aplikasi saja tanpa emulator:

```powershell
flutter test test/app_flow_test.dart
```

Untuk verifikasi integrasi pada perangkat, sambungkan HP Android dan gunakan ID dari `flutter devices`. Tidak perlu menyalakan emulator:

```powershell
flutter devices
flutter test integration_test/app_test.dart -d <device_id>
```

Jika sebuah test gagal, baca nama test dan kondisi yang gagal di keluarannya. Jalankan kembali test terkait secara terpisah, lalu jalankan suite lengkap dengan urutan acak untuk memeriksa ketergantungan pada urutan atau data bersama:

```powershell
flutter test --test-randomize-ordering-seed=20261126
```

Setiap pengujian fitur catatan memakai repository, cache, dan data memori baru. Suite catatan tidak mengakses jaringan. Test autentikasi bawaan memakai server loopback lokal dengan port dinamis, sedangkan test AI memakai HTTP mock sehingga keduanya tidak memerlukan internet.

## Hasil pemeriksaan 26 November 2026

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter test --reporter expanded` sebelum pelengkapan | 27 test lulus. |
| `flutter test --reporter expanded --test-randomize-ordering-seed=20261126` setelah pelengkapan | 32 test lulus, termasuk alur aplikasi tanpa emulator. |
| `flutter analyze` | Lulus: `No issues found!`. |
| `flutter test integration_test/app_test.dart -d <device_id>` | Belum dijalankan pada perangkat. Emulator tidak dinyalakan sesuai permintaan; tidak ada HP Android terhubung. Skenario yang sama sudah lulus melalui `test/app_flow_test.dart`. |

Verifikasi perangkat tetap diperlukan untuk menuntaskan langkah eksekusi integrasi praktikum. Hasil widget test di atas memeriksa alur aplikasi dalam test runner Flutter, bukan perilaku plugin pada perangkat.

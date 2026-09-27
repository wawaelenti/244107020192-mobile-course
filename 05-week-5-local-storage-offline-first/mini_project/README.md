# Lembar Offline Notes

Aplikasi catatan Flutter offline-first untuk tugas Week 5. Catatan dan cache bacaan disimpan di SQLite; preferensi tema dan waktu terakhir dibuka disimpan lewat SharedPreferences. Riverpod menghubungkan UI dengan repository.

## Fitur

- CRUD catatan persisten, pencarian lokal, dan urutan `updated_at` terbaru.
- Tema gelap/terang tersimpan dan waktu terakhir aplikasi dibuka.
- Cache-first untuk tab Bacaan: cache SQLite ditampilkan lebih dulu; tarik ke bawah untuk mengambil bacaan terbaru dari JSONPlaceholder. Cache lama tetap tersedia jika request gagal.
- Catatan baru, edit, dan hapus ditulis lokal dengan `dirty = 1`. Hapus memakai tombstone `deleted_at`, sehingga antrean penghapusan tidak hilang sebelum sync.
- Tombol Sync mengirim perubahan ke endpoint demo JSONPlaceholder. Badge `Belum sync` dan `Tersinkron` memperlihatkan status lokal.
- Test mencakup round-trip model Note dan provider dengan fake repository.

## Aturan Konflik

Kontrak sinkronisasi yang dipakai adalah **last-write-wins** berdasarkan `updated_at` UTC: saat kelak server mengembalikan perubahan, timestamp yang lebih baru menjadi versi aktif; jika timestamp sama, versi server menang agar hasil deterministik. Hapus adalah tombstone dan ikut antrean sync, bukan hard-delete. Implementasi mini project ini hanya mengirim perubahan keluar; endpoint JSONPlaceholder adalah layanan demo yang tidak menyimpan perubahan permanen dan tidak melakukan pull catatan server, sehingga resolusi konflik lintas perangkat belum diuji.

## Menjalankan

```sh
flutter pub get
flutter run
flutter test
```

## Bukti Uji Mode Pesawat

Ambil screenshot pada perangkat/emulator yang benar-benar mengaktifkan mode pesawat:

1. Buat catatan saat online. Pastikan badge `Belum sync` dan tombol `Sync N` terlihat; simpan sebagai `screenshots/dirty-before-sync.png`.
2. Aktifkan mode pesawat. Pastikan daftar catatan tetap terlihat; simpan sebagai `screenshots/airplane-notes.png`.
3. Saat masih offline, tekan Sync. Pastikan status dirty tidak hilang karena request gagal.
4. Matikan mode pesawat, tekan Sync lagi, lalu pastikan badge berubah menjadi `Tersinkron`; simpan sebagai `screenshots/dirty-after-sync.png`.

Screenshot tersebut belum tersedia dari lingkungan pengembangan ini karena tidak ada perangkat/emulator Android yang terhubung. Endpoint sync saat ini hanya demo; respons sukses mengosongkan antrean lokal, tetapi bukan bukti bahwa perubahan tersimpan permanen di cloud.

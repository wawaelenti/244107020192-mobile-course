# Campus Notify — Week 11

Project Flutter untuk praktikum dan tugas optimasi performa. Dokumentasi pengerjaan, perintah, refleksi, serta status bukti profiling tersedia pada [README Week 11](../README.md), [temuan](../docs/performance-findings.md), dan [laporan](../docs/performance-report.md).

```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter run -d <id-perangkat-mobile> --profile
```

Setelah login pilih **Catatan offline** untuk skenario daftar–detail–kembali–pull-to-refresh. Pengujian gambar dilakukan di halaman chat. Hasil DevTools masih memerlukan perangkat mobile dan dataset yang sama sebelum/sesudah optimasi.

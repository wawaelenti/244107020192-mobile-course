# campus_notify

A new Flutter project.

## Chat dengan Gemini

Fitur chat menggunakan endpoint streaming Gemini `gemini-3.6-flash`. Untuk
mencobanya:

1. Buat API key di [Google AI Studio](https://aistudio.google.com/apikey).
2. Jalankan aplikasi, masuk ke halaman utama, lalu pilih **Chat dengan AI**.
3. Ketuk ikon kunci, tempel API key, dan simpan.
4. Kirim pertanyaan; jawaban akan muncul bertahap selama Gemini merespons.

Penggunaan gratis memiliki batas kuota dan rate limit yang ditentukan Google;
lihat [pricing Gemini API](https://ai.google.dev/gemini-api/docs/pricing).
API key disimpan menggunakan `flutter_secure_storage` dan tidak perlu ditulis
ke source code. Untuk aplikasi yang didistribusikan ke publik, jangan menaruh
API key pribadi langsung di aplikasi klien; gunakan backend sendiri untuk
menjaga kredensial dan membatasi penggunaan.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

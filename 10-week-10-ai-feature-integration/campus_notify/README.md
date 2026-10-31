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

### OCR, pemahaman gambar, dan transkripsi suara

- Ketuk ikon gambar di layar chat, lalu ambil foto dengan kamera atau pilih dari
  galeri. Pilih **Ekstrak teks (OCR)** untuk membaca teks pada gambar atau
  **Deskripsikan gambar** untuk mendapatkan penjelasan objek dan detailnya.
- Ketuk ikon mikrofon untuk mulai merekam, lalu ketuk ikon stop untuk
  mengirimkan rekaman dan menampilkan transkripsinya. Rekaman otomatis berhenti
  setelah 60 detik.
- Gambar dan rekaman dikirim ke Gemini untuk dianalisis; file inline dibatasi
  hingga 15 MB. Izin kamera, galeri, dan mikrofon diperlukan sesuai fitur yang
  dipakai.

### Privasi, kuota, dan fallback

| Risiko | Mitigasi |
|---|---|
| Data sensitif terkirim ke Gemini | Konfirmasi privasi sebelum setiap pengiriman; UI mengingatkan agar tidak mengirim password, data kesehatan, nomor kartu, dan dokumen identitas. |
| Biaya/kuota melonjak | Maksimal 20 percobaan request baru per hari per perangkat (berlaku bersama untuk semua API key di perangkat). Penghitung tersimpan di secure storage dan reset berdasarkan tanggal UTC. Maksimal 30 respons di-cache sementara di memori; cache hilang saat aplikasi ditutup dan tidak memakai request baru. |
| API gagal atau offline | Pesan error ramah, tombol **Coba lagi**, dan akses **Catatan offline**. Rekaman sementara dihapus setelah diproses. |
| Respons tidak relevan | Respons kosong ditolak dan catatan SQLite lokal dapat dibuka kapan saja sebagai sumber alternatif. AI tetap bisa keliru, jadi verifikasi informasi penting. |

Batas 20 request ini hanya pengaman sisi klien, bukan penegakan per-user yang
aman terhadap penghapusan data atau modifikasi aplikasi. Aplikasi produksi
harus menegakkan kuota per akun di backend.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

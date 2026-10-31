# AI Log — Campus Notify

## Konteks

- **Fitur:** chat Gemini dengan streaming, OCR/deskripsi gambar, dan transkripsi
  suara.
- **Model pada implementasi:** `gemini-3.6-flash`.
- **API:** Gemini API `generateContent` dan `streamGenerateContent`.
- **Privasi:** jangan kirim data pribadi atau sensitif. Log ini tidak berisi API
  key atau konten pengguna.

## Prompt Sistem (rancangan perilaku assistant)

> Anda adalah asisten AI di aplikasi Campus Notify. Jawab dengan bahasa yang
> digunakan pengguna, ringkas, jelas, dan relevan. Jangan mengarang fakta;
> nyatakan jika informasi tidak cukup atau tidak pasti. Jangan meminta atau
> mengulang password, nomor kartu, data kesehatan, atau informasi sensitif
> lainnya. Untuk teks pada gambar, pertahankan isi yang terbaca tanpa
> menambahkan detail. Untuk gambar, deskripsikan hanya hal yang terlihat.
> Untuk audio, transkripsikan ucapan tanpa menambahkan isi baru. Ingatkan
> pengguna untuk memverifikasi informasi penting.

Prompt sistem ini merupakan prompt perilaku untuk praktikum dan dokumentasi.
Request chat saat ini mengirim teks pengguna, sedangkan OCR/deskripsi/transkripsi
mengirim instruksi tugas yang spesifik; prompt sistem di atas belum dikirim
sebagai `systemInstruction` terpisah pada request API.

## User Prompt

Contoh prompt chat untuk pengujian:

> Tolong ringkas informasi berikut untuk mahasiswa: Perpustakaan tutup pukul
> 15.00 hari ini karena pemeliharaan listrik. Layanan kembali normal besok.

Prompt tugas multimodal yang digunakan service:

- **OCR:** “Ekstrak semua teks yang terlihat pada gambar. Pertahankan urutan
  baris dan tata letaknya sebisa mungkin.”
- **Image understanding:** “Deskripsikan gambar ini dengan jelas dan ringkas.
  Sebutkan objek dan detail penting yang terlihat tanpa menebak informasi yang
  tidak dapat dipastikan dari gambar.”
- **Speech-to-text:** “Transkripsikan seluruh ucapan dalam audio ini dengan
  akurat. Gunakan bahasa yang sama dengan pembicara dan keluarkan hanya teks
  transkripsinya.”

## Output Awal AI

Contoh format output yang diharapkan untuk user prompt di atas:

> **Ringkasan:** Perpustakaan tutup pukul 15.00 hari ini karena pemeliharaan
> listrik. Layanan dibuka normal kembali besok.

**Catatan:** Ini contoh output untuk dokumentasi, bukan salinan respons dari
request Gemini live. Respons live bergantung pada API key, model, dan kondisi
layanan. Jangan mencatat API key atau data pribadi ke log.

## Hasil Implementasi dan Verifikasi

- Chat menampilkan teks bertahap dari streaming Gemini.
- OCR, deskripsi gambar, dan transkripsi audio menggunakan instruksi tugas
  spesifik seperti di atas.
- `flutter analyze`: lulus, tidak ada issue.
- `flutter test`: lulus, seluruh 13 test berhasil.

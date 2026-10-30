# Week 9 - Praktikum 1: Prompt dan Context Engineering

Praktikum ini menggunakan project Flutter `week5_offline_notes` dari Week 5.
Fokusnya hanya merancang prompt dan memilih konteks yang relevan untuk tugas
search judul catatan, sesuai [Codelab Week 9 bagian Praktikum 1](https://jti-polinema.github.io/flutter-codelab/09-minggu-9-ai-assisted-development-vibe-coding/index.html#2).

## Lima slot prompt

| Slot | Isi |
| --- | --- |
| Peran | Senior Flutter developer |
| Konteks | Flutter, Riverpod, SQLite; catatan dibaca melalui `NoteRepository` dan model `Note` memiliki judul |
| Tugas | Rancang pencarian judul catatan beserta empty state |
| Batas | Pertahankan arsitektur dan dukungan offline; jangan panggil SQLite dari widget; jangan ubah fitur lain |
| Output | Usulan perubahan kecil, test, dan langkah verifikasi |

Prompt mentah dan konteks terpilih dicatat di [docs/ai-log.md](./docs/ai-log.md).
Prompt meminta pencarian judul sebagai tugas yang akan dikerjakan pada praktikum
berikutnya; praktikum ini belum mengimplementasikan fitur tersebut.

## Stack yang menjadi konteks

- Flutter dan Dart sesuai SDK project.
- Riverpod `^3.4.3`.
- SQLite melalui `sqflite ^2.4.4`.
- Repository: `lib/data/repositories/note_repository.dart`.
- Model catatan: `lib/data/local/note.dart`.

## Batas praktikum

Praktikum 1 menghasilkan prompt dan konteks yang terarah. Kode search, test
fitur, dan verifikasi implementasi ditunda ke Praktikum 2; tidak ada secret,
token, password, atau seluruh isi repository yang dikirim sebagai konteks.

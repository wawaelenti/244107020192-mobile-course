# Checklist Review Tengah Semester

Project yang direview: `07-week-7-clean-architecture/campus_notify`

## Praktikum 1 — Audit dan simulasi perbaikan commit

Tabel ini hanya simulasi penulisan ulang pesan commit; riwayat Git tidak diubah.

| Sebelum                                           | Sesudah                                                         | Alasan                                                                         |
| ------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `feat(week 6): add refactoring and testing`       | `feat(auth): improve push routing and add error-handling tests` | Scope lebih spesifik; menjelaskan perubahan dan menyebut bukti pengujian.      |
| `feat(week6): add AI Challenge`                   | `feat(auth): add notification routing and AI verification`      | Menyebut hasil perubahan, bukan hanya nama aktivitas.                          |
| `feat(week6): add tugas, refleksi, dan referensi` | `feat(week6): add mini project and course documentation`        | Lebih jelas tentang isi commit; pastikan cocok dengan perubahan yang tercatat. |

## Praktikum 2 — PR dan peer review

| Langkah / kriteria                                                 | Status       | Hasil dan bukti                                                                                                                                                    |
| ------------------------------------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Buat issue untuk pekerjaan                                         | ✅ Terpenuhi | Issue #1: validasi judul kosong — [bukti issue](../screenshots/Prak2/create_github_issue.png).                                                                     |
| Buka PR kecil dari feature ke `develop`                            | ✅ Terpenuhi | PR #2 `feat(notes): validasi judul kosong + test`, dari `feat/notes-validation` ke `develop` — [bukti pembuatan PR](../screenshots/Prak2/create_pull_request.png). |
| Deskripsi PR memuat masalah, solusi, cara uji, dan menautkan issue | ✅ Terpenuhi | Deskripsi menjelaskan masalah catatan tanpa judul, solusi validasi, cara uji, dan `Closes #1` — [bukti PR](../screenshots/Prak2/review_pull_request.png).          |

### Format komentar review yang diharapkan

Gunakan pola berikut pada komentar review:

> Observasi: [bagian kode dan kondisi yang ditemukan].
>
> Dampak: [risiko atau perilaku yang terjadi].
>
> Usulan: [perubahan konkret yang dapat dilakukan].

Reviewer memilih **Approve** jika tidak ada masalah yang menghalangi merge, atau **Request changes** jika author perlu memperbaiki masalah. Setelah perubahan diminta, author memperbaiki lalu meminta re-review; merge dilakukan setelah approve.

## Praktikum 3 — Static analysis dan mid review

| Kriteria codelab                     | Status                 | Hasil dan bukti                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------------------ | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Struktur feature-first notes         | ✅ Terbukti sebagian   | Notes berada di `lib/features/notes/` dengan layer data, domain, dan presentation. Pemeriksaan repository menemukan kontrak `NoteRepository` di domain serta implementasi `NoteRepositoryImpl` di data.                                                                                                                                                                                                                                   |
| Tiga pemeriksaan arsitektur Minggu 7 | ⚠️ Perlu tindak lanjut | **1. Repository:** kontrak dan implementasi ditemukan pada layer yang sesuai. **2. Domain:** tidak ada import Flutter/Dio/SQLite/Firebase (hasil `rg` kosong, exit code 1 seperti yang diharapkan). **3. Provider:** wiring repository berada di provider data, tetapi `presentation/providers/note_providers.dart` mengimpor/menggunakan `noteRepositoryProvider` dari data; batas dependency presentation → data masih perlu dirapikan. |
| `flutter analyze` bersih             | ✅ Lulus               | Screenshot menunjukkan `No issues found!` — [bukti analyze](../screenshots/Prak3/flutter_analyze.png).                                                                                                                                                                                                                                                                                                                                    |
| `flutter test` hijau                 | ✅ Lulus               | Screenshot menunjukkan 11 test berhasil (`All tests passed!`) — [bukti test](../screenshots/Prak3/flutter_test.png).                                                                                                                                                                                                                                                                                                                      |
| PR kecil dan commit jelas            | ✅ Terpenuhi           | PR #2 berjudul `feat(notes): validasi judul kosong + test`, berisi satu commit, dan sudah di-merge ke `develop` — [bukti PR](../screenshots/Prak2/merge_pull_request.png).                                                                                                                                                                                                                                                                |

### Perintah verifikasi arsitektur

Jalankan dari folder `07-week-7-clean-architecture/campus_notify`:

```powershell
rg -n --glob '*.dart' 'abstract class NoteRepository|class NoteRepositoryImpl implements NoteRepository' lib\features\notes
rg -n --glob '*.dart' 'package:(flutter|dio|sqflite|firebase)' lib\features\notes\domain
rg -n --glob '*.dart' 'NoteRepositoryImpl|noteRepositoryProvider|ref\.watch\((getNotesProvider|notesProvider)\)' lib\features\notes
```

## Kesimpulan mid-review

Fondasi project sudah memiliki struktur notes berbasis feature, `flutter analyze` bersih, test hijau, serta PR kecil dengan commit yang jelas telah di-merge ke `develop`. Mid-review **belum dinyatakan selesai**: rapikan/verifikasi batas dependency provider, pastikan format bersih, lengkapi README Minggu 8, dan lakukan serta dokumentasikan peer review sampai seluruh komentar ditindaklanjuti dan mendapat approve.

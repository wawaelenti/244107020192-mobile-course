# AI Challenge: Penyimpanan Offline Notes di Flutter

## Tujuan

Aplikasi Offline Notes membutuhkan CRUD catatan lokal dan preferensi tema. Pemilihan penyimpanan perlu mempertimbangkan pertumbuhan data, kebutuhan query, sinkronisasi saat online, dan kemudahan pengujian. Catatan adalah koleksi terstruktur, sedangkan tema hanya satu nilai preferensi.

## Perbandingan

| Kriteria                | SharedPreferences                                                               | Hive                                                                                                            | sqflite (SQLite)                                                                                           | Drift                                                                                                                           |
| ----------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Kompleksitas query      | Tidak dirancang untuk query koleksi; hanya baca/tulis pasangan key-value.       | Query dasar dapat dilakukan pada box, tetapi filter dan pengurutan kompleks umumnya dilakukan di kode aplikasi. | Mendukung SQL, filter, urut, agregasi, transaksi, dan indeks.                                              | SQL dan query terstruktur dengan API Dart; query kompleks tetap dapat ditulis sebagai SQL.                                      |
| Kebutuhan relasi        | Tidak cocok.                                                                    | Relasi biasanya dikelola manual melalui ID dan beberapa box.                                                    | Relasi dan constraint dapat dibuat dengan foreign key dan JOIN.                                            | Mendukung relasi SQLite serta pemetaan hasil query.                                                                             |
| Reaktivitas (stream)    | Tidak menyediakan stream perubahan nilai yang setara dengan query database.     | Box menyediakan event perubahan; stream untuk hasil filter biasanya dirangkai sendiri.                          | Tidak menyediakan stream query bawaan; perlu pemuatan ulang, event, atau lapisan stream tersendiri.        | `watch()` menghasilkan stream yang diperbarui saat tabel terkait berubah.                                                       |
| Type-safety             | Tipe nilai terbatas dan tidak ada model/query bertipe.                          | Dapat memakai adapter/model bertipe, tetapi filter tetap tidak setara query SQL bertipe.                        | API memakai map dan SQL string sehingga banyak kesalahan baru diketahui saat runtime.                      | Query dan row dipetakan ke tipe Dart; code generation memberi pemeriksaan tipe saat compile time.                               |
| Ukuran boilerplate      | Sangat kecil untuk nilai sederhana.                                             | Rendah-menengah; perlu inisialisasi dan adapter untuk model.                                                    | Menengah; perlu SQL, mapping model, repository, serta strategi migrasi.                                    | Menengah-tinggi di awal; perlu definisi tabel, generator, dan konfigurasi build. Penggunaan query berikutnya lebih terstruktur. |
| Kemudahan testing       | Mudah untuk nilai sederhana, tetapi perlu mengisolasi plugin atau memakai mock. | Box dapat diuji dengan penyimpanan sementara/in-memory; adapter dan inisialisasi perlu disiapkan.               | Repository dapat diisolasi; pengujian integrasi plugin lebih mudah dengan database SQLite FFI.             | Executor in-memory membuat pengujian database dan stream relatif mudah; generated code perlu tetap dibuat.                      |
| Kecocokan untuk tema    | Sangat cocok untuk satu nilai seperti `isDarkMode`.                             | Bisa, tetapi umumnya berlebihan untuk satu boolean.                                                             | Bisa, tetapi menambah tabel dan akses database untuk nilai sederhana.                                      | Bisa, tetapi kompleksitas awalnya tidak sebanding untuk satu preferensi.                                                        |
| Kecocokan untuk catatan | Tidak cocok sebagai penyimpanan daftar catatan.                                 | Cocok untuk catatan offline sederhana yang tidak membutuhkan query relasional kompleks.                         | Cocok untuk CRUD terstruktur, query SQL, transaksi, dan kebutuhan sinkronisasi yang dikendalikan aplikasi. | Cocok ketika catatan memerlukan query bertipe, stream reaktif, dan evolusi skema yang terkelola.                                |

## Trade-off

- **SharedPreferences:** paling ringan untuk preferensi sederhana, tetapi tidak menyediakan query, relasi, atau transaksi untuk koleksi. Menyimpan seluruh daftar catatan sebagai JSON dalam satu nilai membuat pembaruan dan pencarian semakin rapuh seiring data tumbuh, serta tidak semestinya dijadikan database catatan.
- **Hive:** ringan dan praktis untuk penyimpanan objek lokal tanpa banyak SQL. Trade-off-nya, query dan relasi lebih banyak dikelola di lapisan aplikasi; ini dapat menyulitkan kebutuhan pencarian, pengurutan, dan sinkronisasi yang bertambah.
- **sqflite:** memberi kendali langsung atas SQLite, SQL, indeks, dan transaksi dengan ketergantungan runtime yang relatif kecil. Trade-off-nya adalah SQL string dan konversi map/model lebih rentan kesalahan runtime, dan query tidak otomatis menjadi stream.
- **Drift:** dibangun di atas SQLite, bukan pengganti mesin database yang berbeda. Menambah code generation dan boilerplate awal, tetapi memberi query terstruktur/bertipe, migrasi terorganisasi, dan stream `watch()` yang cocok untuk UI reaktif.

## Skema yang Disarankan untuk 1000+ Catatan

SQLite mampu menangani 1000+ baris catatan dengan wajar; desain indeks dan pola query lebih penting daripada jumlah tersebut. Skema berikut adalah rancangan sinkronisasi yang disarankan, bukan klaim bahwa semua kolom sudah ada di implementasi saat ini. `deleted_at` menyimpan tombstone agar penghapusan offline dapat dikirim ke server; hard-delete langsung akan menghilangkan informasi yang perlu disinkronkan.

```sql
CREATE TABLE notes (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	remote_id TEXT UNIQUE,
	title TEXT NOT NULL,
	body TEXT NOT NULL DEFAULT '',
	created_at TEXT NOT NULL,
	updated_at TEXT NOT NULL,
	deleted_at TEXT,
	dirty INTEGER NOT NULL DEFAULT 1 CHECK (dirty IN (0, 1))
);

CREATE INDEX idx_notes_updated_at
	ON notes(updated_at DESC);

CREATE INDEX idx_notes_dirty_updated_at
	ON notes(dirty, updated_at);
```

```text
+----------------+------------------+------------------+------------------+----------+
| id (PK)        | title            | body             | updated_at       | dirty    |
+----------------+------------------+------------------+------------------+----------+
| 1              | Belanja          | Beli kopi        | 2026-09-26T...   | 1        |
| 2              | Ide tugas        | Draft bab 1      | 2026-09-25T...   | 0        |
| ...            | ...              | ...              | ...              | ...      |
| 1000+          | Catatan lainnya  | ...              | ...              | 1        |
+----------------+------------------+------------------+------------------+----------+
```

`dirty = 1` menandai perubahan lokal yang belum tersinkron; setelah server mengonfirmasi, baris dapat ditandai `dirty = 0`. Gunakan `updated_at` untuk urutan dan resolusi perubahan, serta `deleted_at` untuk antrean penghapusan. Untuk tabel kecil, indeks `updated_at` membantu daftar yang diurutkan; indeks gabungan berguna bila aplikasi sering mengambil antrean dirty berdasarkan waktu. Indeks perlu dievaluasi terhadap query nyata karena setiap indeks menambah biaya saat menulis.

## Rekomendasi Final

| Kebutuhan            | Pilihan                                                                                                             | Alasan                                                                                                                                                                                                                                                         |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Preferensi tema      | SharedPreferences                                                                                                   | Nilai tema adalah preferensi kecil dan sederhana; tidak memerlukan query, relasi, atau skema database.                                                                                                                                                         |
| Catatan CRUD offline | sqflite untuk implementasi praktikum ini; pilih Drift bila stream reaktif dan query bertipe menjadi kebutuhan utama | sqflite sudah digunakan pada proyek dan cukup untuk CRUD, indeks, serta metadata antrean sinkronisasi. Drift memberi `watch()` dan type-safety lebih kuat dengan biaya code generation/boilerplate awal. Jangan menyimpan daftar catatan di SharedPreferences. |

## Verifikasi Implementasi Proyek

- Proyek saat ini memakai SharedPreferences untuk preferensi tema dan sqflite untuk tabel catatan.
- Skema `notes` yang ada memiliki `updated_at` dan `dirty`, jadi kebutuhan dasar penandaan perubahan lokal sudah diakomodasi.
- Penghapusan saat ini melakukan hard-delete; untuk sinkronisasi penghapusan yang andal, tambahkan `deleted_at`/tombstone dan tandai baris dirty sampai server mengonfirmasi.
- Daftar catatan saat ini diambil sebagai `Future`, bukan query stream. Pembaruan UI bergantung pada pemuatan ulang/invalidation; jangan menyebutnya real-time berbasis database.
- Drift dan Hive belum dipasang atau diuji pada proyek ini. Ukuran boilerplate keduanya dalam tabel adalah perbandingan desain, bukan hasil pengukuran instalasi proyek.

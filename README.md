# CBT SMKN 1 Parittiga — ExamCore

**Sistem Ujian Online (Computer Based Test)** untuk SMKN 1 Parittiga.
Aplikasi ini memungkinkan guru membuat dan mengelola ujian berbasis komputer,
siswa mengerjakan ujian secara digital dengan pengawasan anti-kecurangan,
dan admin memantau seluruh sistem.

---

## Daftar Isi

- [Teknologi yang Digunakan](#teknologi-yang-digunakan)
- [Fitur Utama](#fitur-utama)
- [Struktur Proyek](#struktur-proyek)
- [Persyaratan Sistem](#persyaratan-sistem)
- [Instalasi & Setup](#instalasi--setup)
- [Akun Demo](#akun-demo)
- [Panduan Penggunaan](#panduan-penggunaan)
- [Alur Kerja Sistem](#alur-kerja-sistem)
- [Fitur Keamanan](#fitur-keamanan)
- [API Endpoints](#api-endpoints)
- [Troubleshooting](#troubleshooting)

---

## Teknologi yang Digunakan

| Komponen | Teknologi |
|----------|-----------|
| **Backend API** | Laravel 12 + PHP 8.2 |
| **Frontend** | Flutter (Dart) — Windows, Android, Web |
| **Database** | MySQL |
| **Auth API** | Laravel Sanctum (token-based) |
| **Spreadsheet** | PhpSpreadsheet (import soal dari Excel) |
| **State Management** | Riverpod |
| **HTTP Client** | Dio |
| **Router** | GoRouter |

---

## Fitur Utama

### Manajemen Pengguna (Admin)
- CRUD pengguna (Admin, Guru, Siswa)
- Atur status aktif/nonaktif
- Ganti password pengguna
- Kelola kelas & enroll siswa
- Lihat semua ujian & aktivasi
- Log aktivitas & pelanggaran

### Manajemen Soal & Ujian (Guru)
- Buat mata pelajaran (subjects)
- Input soal manual (pilihan ganda, true/false, essay)
- Import soal massal dari Excel/CSV
- Paket soal (kumpulan soal reusable)
- Buat & jadwalkan ujian
- Atur durasi, passing grade, randomisasi
- Lihat rekap nilai per kelas
- Analisis butir soal (item analysis)
- Perpanjang waktu siswa tertentu
- Jeda/lanjutkan/akhiri ujian

### Pelaksanaan Ujian (Siswa)
- Lihat daftar ujian tersedia
- Isi biodata sebelum ujian
- Sistem timer mundur
- Tandai soal yang ragu (flag)
- Navigasi nomor soal
- Auto-save jawaban tiap 30 detik
- Lihat hasil setelah ujian
- Riwayat ujian

### Anti-Cheat
- Deteksi tab switch / blur
- Fullscreen paksa (kiosk mode)
- FLAG_SECURE (blok screenshot)
- Randomisasi soal pakai LCG (Linear Congruential Generator)
- Batas maksimal pelanggaran (otomatis submit jika terlampaui)
- Alarm berbunyi saat dicurigai curang

---

## Struktur Proyek

```
ProjekAkhir/
+-- app/                          # Frontend Flutter
|   +-- lib/
|   |   +-- core/
|   |   |   +-- constants/        # Warna, teks, konstanta
|   |   |   +-- network/          # ApiClient (Dio), error handling
|   |   |   +-- providers/        # Riverpod providers
|   |   |   +-- router/           # GoRouter (splash -> login -> dashboard)
|   |   |   +-- security/         # Anti-cheat, LCG, alarm
|   |   |   +-- storage/          # Secure storage
|   |   |   +-- theme/            # Tema terang/gelap
|   |   |   +-- utils/            # Date formatter, connectivity
|   |   |   +-- widgets/          # Widgets reusable
|   |   +-- features/
|   |   |   +-- auth/             # Login screen & data
|   |   |   +-- admin/            # Dashboard admin, users, kelas
|   |   |   +-- guru/             # Dashboard guru, soal, ujian
|   |   |   +-- siswa/            # Dashboard siswa, ujian, hasil
|   |   |   +-- shared/           # Notifikasi, profil
|   |   +-- main.dart             # Entry point
|   +-- android/                  # Konfigurasi Android
|   +-- ios/                      # Konfigurasi iOS
|   +-- pubspec.yaml              # Dependencies Flutter
|
+-- backend/                      # Backend Laravel
|   +-- app/
|   |   +-- Http/Controllers/
|   |   |   +-- Api/              # REST API controllers
|   |   |   +-- Web/              # Web controllers (Blade)
|   |   +-- Models/               # Eloquent models
|   |   +-- Services/             # LCG, grading, scheduler, dll
|   +-- database/
|   |   +-- migrations/           # Skema database
|   |   +-- seeders/              # Data awal
|   +-- routes/
|   |   +-- api.php               # REST API routes
|   |   +-- web.php               # Web routes (Blade)
|   +-- resources/views/          # Blade templates
|
+-- README.md                     # Dokumentasi ini
```

---

## Persyaratan Sistem

### Backend
- PHP 8.2+
- Composer 2.x
- MySQL 8.0+
- Web server (Apache/Nginx) atau Laravel built-in server
- Ekstensi PHP: `mbstring`, `pdo_mysql`, `xml`, `gd`, `zip`

### Frontend (Flutter)
- Flutter SDK 3.12+
- Dart 3.12+
- **Platform target:**
  - **Windows 10/11** (Desktop)
  - **Android 8+** (Mobile/Tablet)
  - **iOS 12+** (iPhone/iPad)
  - **Web browser** (Chrome/Edge modern)

Atau akses via **Web (Blade)** cukup dengan browser modern.

---

## Instalasi & Setup

### 1. Backend (Laravel)

```bash
# Masuk ke direktori backend
cd backend

# Install dependencies PHP
composer install

# Copy file environment
cp .env.example .env
```

**Edit `.env`** — sesuaikan konfigurasi database:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=examcore_db
DB_USERNAME=root
DB_PASSWORD=
```

```bash
# Generate app key
php artisan key:generate

# Jalankan migrasi (buat tabel-tabel)
php artisan migrate

# Seed data awal (admin, guru, siswa, dummy soal)
php artisan db:seed

# Buat storage link (untuk upload gambar)
php artisan storage:link

# Jalankan server development
php artisan serve --host=0.0.0.0 --port=8000
```

Backend akan berjalan di `http://localhost:8000`.

### 2. Frontend (Flutter)

#### Aplikasi Desktop Windows

```bash
cd app

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run -d windows
```

#### Aplikasi Android

```bash
cd app

# Install dependencies
flutter pub get

# Jalankan di emulator/device
flutter run -d android
```

#### Aplikasi iOS (iPhone/iPad)

**Prasyarat:**
- macOS dengan Xcode 15+
- CocoaPods (`sudo gem install cocoapods`)
- Apple Developer account (free atau paid)
- Flutter SDK dengan iOS toolchain terinstall

**Langkah-langkah:**

```bash
cd app

# Install dependencies
flutter pub get

# Install Pod dependencies
cd ios
pod install
cd ..
```

> **Penting:** Buka `Runner.xcworkspace` (bukan `Runner.xcodeproj`) setelah `pod install`.

**Konfigurasi Xcode (sekali):**
1. Buka `ios/Runner.xcworkspace` di Xcode
2. Pilih target **Runner** → tab **Signing & Capabilities**
3. Pilih **Team** (Apple ID atau Developer Account)
4. Ubah **Bundle Identifier** jika perlu (contoh: `com.smkn1parittiga.examcore`)
5. Pastikan minimum deployment target: **iOS 12.0** atau sesuai Podfile

**Build & Jalankan:**

```bash
# Di device/simulator via Flutter
flutter run -d ios

# Build archive untuk App Store / TestFlight
flutter build ios --release --no-codesign

# Build dengan signing untuk deployment
flutter build ipa --release
```

**Simulator vs Device Nyata:**

| Target | Command | Catatan |
|--------|---------|--------|
| Simulator | `flutter run -d ios` | Tidak butuh Apple Developer account |
| Device fisik (debug) | `flutter run -d ios` | Butuh Team di Signing & Capabilities |
| App Store | `flutter build ipa --release` | Butuh Apple Developer ($99/thn) |
| Ad-hoc / TestFlight | `flutter build ipa --release --export-method ad-hoc` | Butuh Apple Developer |

**Troubleshooting iOS:**

| Masalah | Solusi |
|---------|--------|
| `pod install` gagal | `pod install --repo-update` atau `pod update` |
| CocoaPods not found | `sudo gem install cocoapods` (ataupakai `brew install cocoapods`) |
| Signing error | Xcode → Signing & Capabilities → pilih Team |
| `Provisioning profile doesn't include...` | Pastikan device terdaftar di Apple Developer |
| Flutter build ios error Swift | Cek `ios/Podfile` — uncomment `platform :ios, '12.0'` |
| Build gagal di M1/M2 Mac | `arch -arm64 pod install` untuk Rosetta-free |
| Error `Sandbox: rsync.samba` | Build Settings → `ENABLE_USER_SCRIPT_SANDBOXING` → `No` |

> **Catatan URL:** Di file `app/lib/core/constants/app_constants.dart`, URL API bisa disesuaikan:
> - `baseUrlWeb`: `http://localhost:8000/api` (untuk Windows/Web)
> - `baseUrlAndroidEmu`: `http://10.0.2.2:8000/api` (untuk Android emulator)
> - `baseUrlLocalNetwork`: Ganti dengan IP lokal untuk device fisik

#### Akses via Web (Blade)

Backend Laravel juga menyediakan antarmuka web (Tailwind CSS) yang bisa diakses langsung browser tanpa Flutter:

```
http://localhost:8000/splash
```

---

## Akun Demo

Setelah `php artisan db:seed`, akun berikut tersedia:

| Role | Nama | Email | Password |
|------|------|-------|----------|
| **Admin** | Administrator | admin@examcore.id | password123 |
| **Guru** | Budi Santoso | guru@examcore.id | password123 |
| **Guru 2** | Siti Rahayu | siti@examcore.id | password123 |
| **Siswa** | Ahmad Naufal | ahmadnaufal@siswa.id | password123 |
| **Siswa** | Siti Rahayu | sitirahayu@siswa.id | password123 |
| **Siswa** | Dita Kusuma | ditakusuma@siswa.id | password123 |
| **Siswa** | ...dan 7 siswa lain | ...@siswa.id | password123 |

Semua password: `password123`

### Data Demo yang Tersedia
- **10 soal Matematika** (pilihan ganda) — dibuat oleh guru Budi Santoso
- **1 ujian** (draft): "UH 1 — Aljabar Dasar" — 10 soal, 30 menit
- **2 kelas**: "X IPA 1" (Matematika, 10 siswa) & "XI IPS 1" (Ekonomi, 5 siswa)

---

## Panduan Penggunaan

### Untuk Admin

Admin memiliki akses penuh ke seluruh sistem. Dashboard admin menampilkan ringkasan.

#### Menu Utama Admin

| Menu | Fungsi |
|------|--------|
| **Beranda** | Ringkasan: total guru, siswa, kelas, ujian aktif |
| **Pengguna** | Kelola semua user (Admin/Guru/Siswa) |
| **Kelas** | Buat/edit/hapus kelas |
| **Ujian** | Lihat semua ujian, aktivasi & akhiri ujian |
| **Pelanggaran** | Lihat laporan pelanggaran siswa |
| **Log Aktivitas** | Riwayat aktivitas sistem |
| **Export Data** | Download data users |

#### Langkah-langkah Admin

1. **Login** sebagai admin (`admin@examcore.id` / `password123`)
2. **Kelola Pengguna**: Tambah guru & siswa, atur status aktif/nonaktif
3. **Kelola Kelas**: Buat kelas, assign guru wali, enroll siswa
4. **Pantau Ujian**: Lihat daftar semua ujian, aktivasi ujian yang sudah siap
5. **Cek Pelanggaran**: Lihat & tangani pelanggaran siswa
6. **Lihat Log**: Pantau aktivitas sistem

---

### Untuk Guru

Guru mengelola soal dan ujian untuk kelasnya.

#### Menu Utama Guru

| Menu | Fungsi |
|------|--------|
| **Beranda** | Ringkasan: total soal, ujian, kelas, pelanggaran |
| **Input Soal** | Buat soal manual & import Excel |
| **Bank Soal** | Lihat, cari, edit, hapus semua soal |
| **Paket Soal** | Kelola kumpulan soal reusable |
| **Jadwal Ujian** | Buat & kelola ujian |
| **Rekap Nilai** | Lihat nilai siswa per kelas |

#### Langkah-langkah Guru

**A. Kelola Mata Pelajaran**
1. Buka menu **Input Soal**
2. Tap ikon **+** untuk tambah mata pelajaran baru
3. Masukkan nama mata pelajaran

**B. Input Soal**
1. Pilih mata pelajaran
2. Tap tombol **+** untuk soal baru
3. Isi: teks soal, tipe (pilihan ganda/true-false/essay), opsi jawaban, kunci jawaban, pembahasan
4. **Import Massal**: Tap ikon upload -> pilih file Excel/CSV
5. Download template import via API: `GET /api/guru/question-imports/template`

**C. Buat Paket Soal**
1. Buka **Paket Soal** -> pilih mata pelajaran
2. Tap **Buat Paket Baru**
3. Beri judul, pilih kelas
4. Pilih soal-soal yang akan dimasukkan
5. Atur urutan soal

**D. Buat Ujian Baru**
1. Buka **Jadwal Ujian** -> tap tombol **Ujian Baru** (FAB)
2. Isi form:
   - **Judul**: Nama ujian (contoh: "UH 1 — Aljabar Dasar")
   - **Kelas**: Pilih kelas tujuan
   - **Durasi**: Menit pengerjaan
   - **Passing Grade**: Nilai minimum lulus (default 70)
   - **Acak Soal**: Ya/Tidak
   - **Deskripsi**: Opsional
3. **Pilih Soal**: Pilih dari bank soal / paket soal
4. **Simpan** sebagai draft

**E. Jadwalkan & Aktifkan Ujian**
1. Buka detail ujian -> tap **Atur Jadwal**
2. Tentukan waktu mulai & selesai
3. Centang **Aktifkan Otomatis** jika ingin langsung aktif
4. Admin perlu mengaktivasi ujian via menu **Ujian** di admin
5. Status ujian: `draft` -> `scheduled` -> `active` -> `ended`

**F. Selama Ujian Berlangsung**
- **Jeda ujian**: Jika ada gangguan, guru bisa menjeda
- **Lanjutkan**: Kembalikan ujian aktif
- **Akhiri**: Paksa akhiri ujian lebih awal
- **Perpanjang Waktu**: Untuk siswa tertentu yang butuh tambahan waktu

**G. Lihat Hasil**
1. Buka **Rekap Nilai**
2. Pilih kelas -> lihat daftar siswa & nilai
3. Klik siswa untuk detail jawaban
4. **Analisis Butir Soal**: Lihat statistik tiap soal (tingkat kesulitan, daya beda)

---

### Untuk Siswa

Siswa hanya bisa mengerjakan ujian yang sudah aktif untuk kelasnya.

#### Menu Utama Siswa

| Menu | Fungsi |
|------|--------|
| **Beranda** | Daftar ujian tersedia |
| **Riwayat** | Riwayat ujian yang sudah dikerjakan |

#### Langkah-langkah Siswa (Flutter Desktop/Android)

1. **Login** dengan akun siswa
2. **Beranda** menampilkan ujian yang tersedia
3. Tap ujian -> akan diarahkan ke halaman **Biodata**
4. Isi: Nama Lengkap, NIS, Kelas (pre-filled)
5. Tap **Mulai Ujian**

**Saat Ujian Berlangsung:**
- **Timer** mundur di pojok atas
- **Navigasi soal**: Panel nomor soal di samping
- Soal **aktif** (biru)
- Soal **terjawab** (hijau)
- Soal **diragukan / flagged** (icon bendera)
- **Auto-save** setiap 30 detik (otomatis)
- **Anti-Cheat aktif**: Tidak bisa pindah tab, screenshot diblokir
- Pelanggaran > batas -> ujian otomatis disubmit

**Setelah Selesai:**
- Tap **Kumpulkan** atau waktu habis otomatis
- Hasil langsung tampil (jika `show_result_immediately = true`)
- Lihat skor, jawaban benar/salah, pembahasan
- Riwayat tersimpan di menu **Riwayat**

#### Via Web (Blade)

Akses `http://localhost:8000/siswa/exams` setelah login web — antarmuka lebih sederhana.

---

## Alur Kerja Sistem

```
Admin                  Guru                      Siswa
  |                      |                         |
  +-- Buat user ---------+                         |
  +-- Buat kelas --------+                         |
  |                      +-- Buat Mata Pelajaran   |
  |                      +-- Input Soal            |
  |                      +-- Buat Paket Soal       |
  |                      +-- Buat Ujian (draft)    |
  |                      +-- Jadwalkan Ujian       |
  +-- Aktivasi Ujian ----+                         |
  |                      |                         +-- Lihat ujian tersedia
  |                      |                         +-- Isi biodata
  |                      |                         +-- Kerjakan ujian
  |                      |                         |   (auto-save tiap 30s)
  |                      |                         +-- Submit / timeout
  |                      +-- Pantau realtime ------+
  |                      +-- Lihat hasil & rekap --+
  |                      +-- Analisis butir soal --+
  +-- Cek pelanggaran ---+                         |
  +-- Cek log aktivitas -+                         |
                                              [Selesai]
```

### Status Ujian

| Status | Keterangan |
|--------|------------|
| `draft` | Ujian dibuat, belum dijadwalkan |
| `scheduled` | Sudah dijadwalkan, menunggu aktivasi admin |
| `active` | Aktif, siswa bisa mengerjakan |
| `paused` | Dijeda sementara oleh guru |
| `ended` | Ujian selesai |

---

## Fitur Keamanan

### Anti-Cheat Terintegrasi

| Fitur | Platform | Deskripsi |
|-------|----------|-----------|
| **FLAG_SECURE** | Android | Blokir screenshot & screen recording |
| **Lock Task (Kiosk)** | Android | Kunci di layar ujian — home/recents diblokir |
| **Fullscreen Paksa** | Windows/Web | Paksa mode fullscreen, deteksi exit |
| **Deteksi Tab Switch** | Semua | Catat setiap kali pindah tab/aplikasi lain |
| **Deteksi Copy-Paste** | Semua | Blokir copy/paste selama ujian |
| **Alarm** | Semua | Bunyi peringatan saat terdeteksi mencurigakan |
| **LCG Randomisasi** | Backend | Urutan soal & opsi diacak per siswa pakai LCG |

### Batas Pelanggaran
- Default: **5 pelanggaran** (bisa diatur per ujian)
- Setiap tab switch / fullscreen exit = 1 pelanggaran
- >= batas -> ujian otomatis disubmit paksa (force submit)
- Guru bisa menangani pelanggaran (dianggap valid/dihapus)

### Verifikasi Password Keluar
Siswa perlu memasukkan password untuk keluar dari layar ujian — mencegah keluar sembarangan.

---

## API Endpoints

Semua endpoint REST API menggunakan prefix `/api` dan auth token Sanctum.

### Public

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/api/auth/login` | Login pengguna |
| POST | `/api/lcg/verify` | Verifikasi jawaban LCG |
| POST | `/api/lcg/check-consistency` | Cek konsistensi LCG |

### Authenticated (semua role)

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/auth/me` | Data user saat ini |
| POST | `/api/auth/logout` | Logout (satu device) |
| PATCH | `/api/auth/password` | Ganti password |
| GET | `/api/notifications` | Daftar notifikasi |
| PATCH | `/api/notifications/read-all` | Tandai semua terbaca |

### Guru & Admin

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/guru/dashboard` | Dashboard guru |
| GET/POST | `/api/guru/subjects` | CRUD mata pelajaran |
| GET/POST | `/api/guru/questions` | CRUD soal |
| POST | `/api/guru/questions/bulk` | Import soal massal |
| POST | `/api/guru/question-imports/preview` | Preview import Excel |
| GET/POST | `/api/guru/exams` | CRUD ujian |
| PATCH | `/api/guru/exams/{id}/schedule` | Jadwalkan ujian |
| PATCH | `/api/guru/exams/{id}/pause` | Jeda ujian |
| PATCH | `/api/guru/exams/{id}/resume` | Lanjutkan ujian |
| PATCH | `/api/guru/exams/{id}/end` | Akhiri ujian |
| POST | `/api/guru/exams/{id}/extend-time` | Perpanjang waktu siswa |
| GET | `/api/guru/exams/{id}/item-analysis` | Analisis butir soal |
| GET/POST | `/api/guru/packages` | CRUD paket soal |
| GET | `/api/guru/classes` | Daftar kelas (read only) |
| GET | `/api/guru/classes/{id}/grade-report` | Rekap nilai per kelas |
| GET | `/api/guru/violations` | Daftar pelanggaran |

### Siswa

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/siswa/exams` | Ujian tersedia |
| POST | `/api/siswa/exams/{id}/start` | Mulai ujian |
| POST | `/api/siswa/sessions/{id}/answers` | Sync jawaban (bulk) |
| GET | `/api/siswa/sessions/{id}/state` | Ambil state sesi (fallback) |
| POST | `/api/siswa/sessions/{id}/submit` | Submit ujian |
| GET | `/api/siswa/sessions/{id}/result` | Hasil ujian |
| GET | `/api/siswa/history` | Riwayat ujian |
| POST | `/api/siswa/violations` | Laporkan pelanggaran |

### Admin Only

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/admin/dashboard` | Dashboard admin |
| GET/POST | `/api/admin/users` | CRUD pengguna |
| DELETE | `/api/admin/users/{id}` | Hapus pengguna |
| PATCH | `/api/admin/users/{id}/toggle-status` | Aktif/nonaktifkan user |
| POST | `/api/admin/classes` | CRUD kelas |
| PATCH | `/api/admin/exams/{id}/activate` | Aktivasi ujian |
| PATCH | `/api/admin/exams/{id}/end` | Akhiri ujian paksa |
| GET | `/api/admin/violations` | Semua pelanggaran |
| GET | `/api/admin/activity-logs` | Log aktivitas |
| GET | `/api/admin/export/users` | Export data users |

---

## Troubleshooting

### Backend

| Masalah | Solusi |
|---------|--------|
| `composer install` gagal | Pastikan PHP 8.2+, ekstensi `mbstring` & `pdo_mysql` aktif |
| `APP_KEY` missing | Jalankan `php artisan key:generate` |
| Database connection error | Cek kredensial di `.env`, pastikan MySQL running |
| Migrasi gagal | Jalankan `php artisan migrate:fresh` (hapus semua tabel) |
| Storage link error | `php artisan storage:link` |
| 419 Page Expired (web) | `.env` -> `SESSION_DRIVER=file`, pastikan storage writeable |
| 401 Unauthorized (API) | Token expired — login ulang |
| CORS error (Flutter) | Tambahkan domain di `.env` `SANCTUM_STATEFUL_DOMAINS` |

### Frontend (Flutter)

| Masalah | Solusi |
|---------|--------|
| `flutter pub get` gagal | Cek koneksi internet, jalankan `flutter clean` lalu `flutter pub get` |
| Tidak bisa connect ke API | Cek `baseUrlDefault` di `app_constants.dart` |
| Android: `10.0.2.2` tidak connect | Pastikan backend `php artisan serve --host=0.0.0.0` |
| Windows: blank screen | Jalankan `flutter clean && flutter pub get && flutter run -d windows` |
| Login gagal terus | Cek log backend: `storage/logs/laravel.log` |

### Database Hilang / Reset

Jika database bermasalah dan ingin reset dari awal:

```bash
cd backend
php artisan migrate:fresh --seed
```

Ini akan menghapus semua data dan membuat ulang dari awal beserta data demo.

---

**Dikembangkan untuk:** SMKN 1 Parittiga
**Framework:** Laravel 12 + Flutter
**Lisensi:** MIT

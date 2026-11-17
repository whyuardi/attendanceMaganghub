# Workforce Attendance Mobile (Employee App)

Aplikasi mobile Flutter untuk absensi karyawan (**Project A — Workforce Attendance**) dengan arsitektur *clean/feature-first*, didesain khusus sesuai panduan desain minimalis terarah (Coinbase-inspired: Inter & JetBrains Mono typography, radius fungsional, tanpa dekorasi berlebihan).

---

## 1. Menjalankan Aplikasi

Pastikan Flutter SDK sudah terpasang.

```bash
# Masuk ke direktori
cd attendance

# Install dependensi
flutter pub get

# Jalankan pengujian unit test (ATT-01 s/d ATT-08)
flutter test

# Jalankan aplikasi di emulator atau perangkat fisik
flutter run
```

### Akun Demo (Mock Mode)
- **Email:** `andi@company.com`
- **Password:** `password`
- *(Tersedia juga `budi@company.com` dan `citra@company.com`)*

---

## 2. Cara Pindah dari Mock ke API Laravel

Arsitektur aplikasi menggunakan **Repository Pattern** dan **Riverpod**. Seluruh pemanggilan network diisolasi di repository layer.

Untuk berpindah dari mode Mock ke API Laravel nyata:
Buka file [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart), lalu ubah flag:

```dart
class AppConfig {
  // Ubah baris ini dari true ke false:
  static const bool useMock = false;

  // Sesuaikan base URL Laravel:
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // Atau gunakan http://localhost:8000/api untuk iOS Simulator / Web
}
```

UI layer tidak pernah memanggil `Dio` secara langsung, sehingga peralihan dilakukan tanpa mengubah satu baris pun kode pada UI widget.

---

## 3. Daftar Asumsi & Kontrak Data

1. **Format JSON & Tanggal:**
   - Format waktu mengikuti standar ISO 8601 dengan offset WIB (`+07:00`).
   - Format jam di UI ditampilkan dalam format titik Indonesia (`07.52`, `--.--`).
   - Status response mengikuti format snake_case.

2. **Aturan Bisnis & Batas Jam Masuk:**
   - Jam masuk kantor: **08:00 WIB**, toleransi keterlambatan: **15 menit**.
   - Pukul `08:15:00` dihitung **Tepat waktu** (`tepat_waktu`).
   - Pukul `08:15:01` dan seterusnya dihitung **Terlambat** (`terlambat`).
   - Penentuan status dihitung oleh server; aplikasi client hanya menerima dan menampilkan status dari server.

3. **Endpoint Office (Asumsi Khusus):**
   - Sesuai instruksi assessment, endpoint kantor belum ada di spesifikasi resmi awal.
   - Disediakan method terpisah `OfficeRepository.getOffice()` dengan komentar `TODO` untuk menyesuaikan endpoint jika backend Laravel sudah menyediakannya (`GET /api/office`).
   - Response model mengasumsikan `{ id, name, address, latitude, longitude }`.
   - Tombol **"Buka di Maps"** meluncurkan URL Google Maps: `https://www.google.com/maps/search/?api=1&query=LAT,LNG`.

4. **Autentikasi (ATT-06 & ATT-07):**
   - Identitas karyawan selalu diambil dari Bearer Token (Laravel Sanctum), client tidak pernah mengirim `employee_id` secara manual di body/parameter.
   - Jika menerima HTTP 401 atau token kedaluwarsa/hilang, `DioInterceptor` otomatis menghapus token lokal dan mengarahkan kembali ke halaman Login.

---

## 4. Skenario Demo Manual Pengujian

Ikuti langkah-langkah berikut untuk memverifikasi seluruh business rules:

1. **Login:**
   - Buka aplikasi, masukkan email `andi@company.com` dan kata sandi `password`.
   - Tekan tombol **Masuk**. Aplikasi masuk ke halaman **Utama**.
2. **Cek Profil:**
   - Buka tab **Profil**. Verifikasi nama *Andi Pratama*, kode *EMP-001*, dan inisial *AP*.
3. **Absen Masuk (ATT-01):**
   - Di tab **Utama**, tekan tombol pill biru **"Absen masuk"**.
   - Jam masuk tercatat (misal: `07.52`), status pill menunjukkan *Tepat waktu* atau *Terlambat*.
4. **Coba IN Kedua (ATT-02):**
   - Tombol berubah menjadi **"Absen pulang"**.
   - Jika dipanggil ulang dari server/mock, sistem menampilkan pesan: *"Kamu sudah absen masuk hari ini pukul 07.52"*.
5. **Absen Pulang (ATT-04):**
   - Tekan tombol pill biru **"Absen pulang"**.
   - Jam pulang tercatat (misal: `17.03`).
6. **Coba OUT Kedua (ATT-05):**
   - Tombol berubah menjadi disabled dengan teks **"Selesai hari ini"**.
   - Jika dipaksa, request ditolak dengan pesan: *"Kamu sudah absen pulang hari ini pukul 17.03"*.
7. **Lihat Riwayat:**
   - Buka tab **Riwayat**. Daftar flat terisi riwayat hari ini dan hari-hari sebelumnya yang dipisahkan garis hairline halus.
8. **Lihat Lokasi Kantor:**
   - Buka tab **Kantor**. Tampil nama kantor *Ethes Tech Office*, alamat di Yogyakarta, koordinat lintang/bujur, serta tombol **"Buka di Maps"**.

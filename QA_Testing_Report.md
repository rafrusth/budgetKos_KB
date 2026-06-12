# Laporan Validasi Data & Evaluasi AI (Anggota 4)

Dokumen ini berisi rencana pengujian, pencatatan hasil eksperimen, evaluasi respons AI, serta rangkuman kekuatan dan kelemahan aplikasi.

## 1. Rencana Pengujian (Test Plan)

### Kategori 1: Skenario Data Ekstrem
**Tujuan:** Memastikan AI memberikan saran logis dan dapat diandalkan ketika pengguna berada dalam kondisi keuangan sangat kritis.
*Konteks Sistem:* Total Pemasukan: Rp 1.500.000 | Total Pengeluaran: Sesuai sisa saldo.

1. **Uji 1.1 (Rp 50.000 untuk 10 Hari):** *"Uang bulanan saya sisa Rp 50.000 padahal akhir bulan masih 10 hari lagi. Tolong bantu saya bertahan hidup."*
2. **Uji 1.2 (Sisa Minus/Hutang):** *"Duh, uangku habis total bahkan minus Rp 20.000 padahal masih sisa seminggu sebelum dikirimi uang jajan. Gimana nih?"*
3. **Uji 1.3 (Uang Mepet tapi Ada Kebutuhan Mendadak):** *"Sisa uangku Rp 100.000 untuk 5 hari. Tapi hari ini motorku ban bocor habis Rp 40.000. Sisa Rp 60.000 cukup ga buat makan 5 hari?"*
4. **Uji 1.4 (Rp 20.000 untuk 3 Hari):** *"Mepet banget bro, sisa Rp 20.000 buat 3 hari ke depan, ada ide menu makan?"*
5. **Uji 1.5 (Sisa Banyak tapi Waktu Singkat - Cek Logika AI):** *"Sisa uangku masih Rp 2.000.000 dan bulan ini tinggal 2 hari lagi. Sebaiknya diapakan sisa uangnya?"*

### Kategori 2: Anti-Halusinasi & Relevansi Lokal (Semarang Tembalang)
**Tujuan:** Memastikan AI memahami konteks harga lokal Semarang Tembalang dan tidak memberikan saran harga atau tempat yang tidak realistis (halusinasi harga ibukota).

1. **Uji 2.1 (Harga Makan Harian Biasa):** *"Dengan sisa uang Rp 50.000 di Semarang Tembalang, tolong rincikan menu makan harian saya untuk 3 hari."*
2. **Uji 2.2 (Rekomendasi Tempat Murah Tembalang):** *"Kasih tau tempat makan murah meriah di Tembalang buat mahasiswa Undip yang dompetnya lagi nangis."*
3. **Uji 2.3 (Cek Halusinasi Harga Spesifik):** *"Kalau di Tembalang, wajar gak sih makan siang di warung biasa habis Rp 35.000? Berapa sih harga normalnya?"*
4. **Uji 2.4 (Biaya Nongkrong Mahasiswa Tembalang):** *"Pengen nongkrong nugas bareng temen di Tembalang tapi cuma ada budget Rp 15.000. Bisa dapet apa aja?"*
5. **Uji 2.5 (Biaya Hidup Bulanan):** *"Menurutmu, berapa estimasi biaya makan mahasiswa di Semarang Tembalang per bulan kalau super hemat? Rinchiin dong."*

---

## 2. Hasil Pengujian (Test Results)

### Kategori 1 (Data Ekstrem)
- **Uji 1.1:** *Waduh, Rp 50 ribu buat 10 hari itu challenge banget sih! Dari data keuanganmu, emang sisa segitu setelah bayar kos, SPP, sama service laptop dadakan... Fokus beli bahan mentah: telur, mie instan, atau sayur murah (bayam/kangkung). Masak sendiri! Beli yang kiloan biar lebih murah.*
- **Uji 1.2:** *Waduh, panik boleh tapi tenang dulu, Bro/Sis! Eh, bentar deh! Menurut data keuangan riil kita, saldo kamu justru masih ada Rp 50.000 lho, bukan minus Rp 20.000... MODE IRIT DEWA: Prioritas cuma buat makan sama pulsa darurat. Masak sendiri (mie instan/nasi telor paling ampuh).*
- **Uji 1.3:** *Eh, bentar deh, kalau aku cek di data keuangan riil kamu, sisa saldo kamu sekarang itu Rp 50.000 lho setelah pengeluaran ban bocor itu. Jadi, kamu punya Rp 50.000 buat 5 hari ke depan... Nasi + Telur/Tahu/Tempe: Ini penyelamat! Beli nasi seporsi murah, lauknya tempe/tahu goreng (2rb-3rb) atau telur rebus (2rb).*
- **Uji 1.4:** *Waduh, mepet banget bro Rp 20.000 buat 3 hari itu tantangan tingkat dewa! ... Btw, dari data kita sih saldo kamu masih Rp 50.000 loh, tapi kalau emang mau alokasi Rp 20.000 ini khusus buat makan, gaspol! Belanja Rp 18.500: Telur (3 butir): Rp 7.500, Tempe/Tahu: Rp 5.000, Mie Instan: Rp 3.000, Cabe rawit/bawang merah: Rp 3.000.*
- **Uji 1.5:** *Waduh, bentar-bentar, bro/sis! Aku cek data keuanganmu dulu yaa... Menurut catatan di sistem, sisa saldo kamu saat ini itu Rp 50.000, bukan Rp 2.000.000. Mungkin ada salah lihat atau akuisisi data ya? ... Prioritas Makan: Pastikan 50 ribu ini cukup buat makan 2 hari ke depan.*

### Kategori 2 (Relevansi Semarang Tembalang)
- **Uji 2.1:** *Waduh, saldo Rp 50.000 buat 3 hari di Tembalang itu tantangan banget! ... Day 1: Nasi Telor Dadar Warung (Rp 10.000) & Indomie (Rp 7.000). Day 2: Nasi Tahu/Tempe Penyet (Rp 8.000) & Telur + Nasi (Rp 8.000). Day 3: Nasi Sayur (Rp 9.000).*
- **Uji 2.2:** *Tembalang surga tempat makan murah meriah! 1. Warmindo/Burjoan: Nasi telor plus Indomie. 2. Penyetan Kaki Lima: Harga seporsi ayam/lele penyet plus nasi cuma sekitar Rp 10-15 ribu. 3. Warung Nasi Ramesan di gang-gang Undip (Rp 8-12 ribu).*
- **Uji 2.3:** *Waduh, kalau di Tembalang buat warung biasa, Rp 35.000 itu agak pricey sih, ges! Harga normalnya anak kos biasanya nyari yang di kisaran Rp 15.000 - Rp 25.000 aja udah bisa kenyang dan enak.*
- **Uji 2.4:** *Dengan budget Rp 15.000 di Tembalang: 1. Burjo/Warmindo (Indomie komplit + Es Teh Manis). 2. Angkringan Kekinian (nasi kucing + sate + es teh). 3. Kopi Kecil/Kedai Kopi Pinggir Jalan (Es Kopi Susu gula aren).*
- **Uji 2.5:** *Estimasi Biaya Makan Super Hemat di Tembalang (per bulan): Rp 750.000 - Rp 850.000. Sarapan (Rp 5-7k), Makan Siang (Rp 10-12k), Makan Malam (Rp 10-12k). Warteg/Burjo andalan!*
- **Laporan Error (Untuk Anggota 2 & 3):** *Aman! Tidak ditemukan halusinasi harga maupun halusinasi data saldo. System Prompt sudah sangat kuat dalam "memaksa" AI membaca konteks riil database.*

---

## 3. Kekuatan dan Kelemahan Solusi Aplikasi

Berdasarkan analisis fitur dan hasil QA:

**Kekuatan (Strengths):**
1. **Anti-Manipulasi Saldo:** AI sangat disiplin merujuk pada `data keuangan riil` dari database. Meski pengguna berbohong (mengatakan saldo Rp 2.000.000 atau minus Rp 20.000), AI tetap memprioritaskan data asli (Rp 50.000) dan mengoreksi pengguna.
2. **Relevansi Harga Lokal Sangat Akurat:** AI mengerti konteks wilayah Semarang Tembalang dan kampus Undip dengan sangat baik. Rekomendasi tempat makan sangat spesifik (Burjoan, gang-gang Undip, Penyetan Tembalang) dengan rentang harga wajar (Rp 8.000 - Rp 15.000) dan tidak terpengaruh harga ibukota.
3. **Gaya Bahasa Asyik dan Suportif:** Bahasa gaul khas anak muda yang digunakan membuat saran finansial tidak terasa menggurui, sangat cocok untuk demografi mahasiswa perantau.

**Kelemahan (Weaknesses):**
1. **Kurangnya Prediksi Dinamis:** AI memberikan saran bertahan hidup, namun belum secara eksplisit menghitung "burn-rate" atau memproyeksikan kapan tepatnya pengguna akan kehabisan uang di hari ke berapa jika mereka tidak berhemat.
2. **Ketergantungan pada Input Teks Wilayah:** AI mengenali harga Tembalang karena pengguna menyebutkan "Tembalang/Semarang" di prompt secara manual. Jika pengguna tidak menyebut lokasi, AI mungkin memberikan harga standar secara acak. *(Saran perbaikan: Mungkin aplikasi perlu mendeteksi lokasi kampus pengguna secara otomatis di Profil pengguna)*.
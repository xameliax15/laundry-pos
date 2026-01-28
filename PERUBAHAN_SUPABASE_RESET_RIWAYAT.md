# Perubahan yang Diperlukan di Supabase untuk Fitur Reset Riwayat

## ✅ Jawaban: **YA, Perlu Memeriksa RLS Policies**

Fitur reset riwayat transaksi memerlukan **permission DELETE** yang mungkin dibatasi oleh Row Level Security (RLS) policies di Supabase.

---

## 🔍 Yang Perlu Diperiksa

### 1. **Row Level Security (RLS) Policies**

Supabase menggunakan RLS untuk mengontrol akses data. Untuk fitur reset riwayat, perlu memastikan:

#### **Tabel `transaksi`**
- ✅ Policy untuk DELETE harus mengizinkan owner menghapus semua transaksi
- ⚠️ Jika policy saat ini hanya mengizinkan delete berdasarkan `user_id` atau kondisi tertentu, perlu ditambahkan policy khusus untuk owner

#### **Tabel `detail_laundry`**
- ✅ Policy untuk DELETE harus mengizinkan owner menghapus semua detail laundry

#### **Tabel `pembayaran`**
- ✅ Policy untuk DELETE harus mengizinkan owner menghapus semua pembayaran

#### **Tabel `order_kurir`**
- ✅ Policy untuk DELETE harus mengizinkan owner menghapus semua order kurir

---

## 📋 SQL Script untuk Update RLS Policies

### **Opsi 1: Policy untuk Owner (Recommended)**

Jalankan script SQL berikut di Supabase SQL Editor:

```sql
-- ============================================
-- RLS Policies untuk Reset Riwayat (Owner Only)
-- ============================================

-- 1. Policy DELETE untuk tabel transaksi (Owner dapat hapus semua)
DROP POLICY IF EXISTS "Owner can delete all transactions" ON transaksi;
CREATE POLICY "Owner can delete all transactions"
ON transaksi
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id::text = auth.uid()::text
    AND users.role = 'owner'
  )
);

-- 2. Policy DELETE untuk tabel detail_laundry (Owner dapat hapus semua)
DROP POLICY IF EXISTS "Owner can delete all detail_laundry" ON detail_laundry;
CREATE POLICY "Owner can delete all detail_laundry"
ON detail_laundry
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id::text = auth.uid()::text
    AND users.role = 'owner'
  )
);

-- 3. Policy DELETE untuk tabel pembayaran (Owner dapat hapus semua)
DROP POLICY IF EXISTS "Owner can delete all pembayaran" ON pembayaran;
CREATE POLICY "Owner can delete all pembayaran"
ON pembayaran
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id::text = auth.uid()::text
    AND users.role = 'owner'
  )
);

-- 4. Policy DELETE untuk tabel order_kurir (Owner dapat hapus semua)
DROP POLICY IF EXISTS "Owner can delete all order_kurir" ON order_kurir;
CREATE POLICY "Owner can delete all order_kurir"
ON order_kurir
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id::text = auth.uid()::text
    AND users.role = 'owner'
  )
);
```

### **Opsi 2: Bypass RLS untuk Service Role (Tidak Recommended untuk Production)**

Jika menggunakan service role key (bukan anon key), RLS akan di-bypass. Tapi ini **TIDAK DISARANKAN** karena kurang aman.

---

## 🔐 Cara Memeriksa RLS Policies Saat Ini

### **1. Melalui Supabase Dashboard**

1. Buka Supabase Dashboard
2. Pilih project Anda
3. Pergi ke **Authentication** → **Policies**
4. Pilih tabel yang ingin diperiksa (transaksi, detail_laundry, pembayaran, order_kurir)
5. Lihat policies DELETE yang ada

### **2. Melalui SQL Editor**

Jalankan query berikut untuk melihat semua policies:

```sql
-- Lihat semua policies untuk tabel transaksi
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('transaksi', 'detail_laundry', 'pembayaran', 'order_kurir')
ORDER BY tablename, policyname;
```

---

## ⚠️ Potensi Masalah

### **1. Error: "new row violates row-level security policy"**

**Penyebab:** RLS policy tidak mengizinkan DELETE untuk user yang sedang login.

**Solusi:** Tambahkan policy seperti di atas (Opsi 1).

### **2. Error: "permission denied for table"**

**Penyebab:** User tidak memiliki permission DELETE di tabel.

**Solusi:** Pastikan user memiliki role 'owner' dan policy mengizinkan DELETE.

### **3. Delete Tidak Berjalan (Silent Fail)**

**Penyebab:** RLS policy mengizinkan DELETE tapi dengan kondisi yang tidak terpenuhi.

**Solusi:** Periksa kondisi `USING` di policy, pastikan sesuai dengan kebutuhan.

---

## ✅ Checklist Sebelum Deploy

- [ ] RLS sudah diaktifkan untuk semua tabel terkait
- [ ] Policy DELETE untuk owner sudah dibuat untuk tabel `transaksi`
- [ ] Policy DELETE untuk owner sudah dibuat untuk tabel `detail_laundry`
- [ ] Policy DELETE untuk owner sudah dibuat untuk tabel `pembayaran`
- [ ] Policy DELETE untuk owner sudah dibuat untuk tabel `order_kurir`
- [ ] Test delete single transaction berhasil
- [ ] Test delete all transactions berhasil (dari owner account)
- [ ] Test delete dari non-owner account gagal (security check)

---

## 🧪 Testing RLS Policies

### **Test 1: Owner dapat delete semua transaksi**

```sql
-- Login sebagai owner, lalu test:
DELETE FROM transaksi WHERE id = 'test_id';
-- Harus berhasil
```

### **Test 2: Non-owner tidak dapat delete**

```sql
-- Login sebagai kasir/kurir, lalu test:
DELETE FROM transaksi WHERE id = 'test_id';
-- Harus gagal dengan error RLS
```

### **Test 3: Delete all dari aplikasi**

1. Login sebagai owner di aplikasi
2. Klik "Reset Riwayat"
3. Konfirmasi
4. Cek apakah semua transaksi terhapus
5. Cek apakah detail_laundry, pembayaran, order_kurir juga terhapus

---

## 📝 Catatan Penting

### **1. Backup Data Sebelum Testing**

Sebelum menguji fitur reset riwayat, **BACKUP DATA TERLEBIH DAHULU**:

```sql
-- Backup transaksi
CREATE TABLE transaksi_backup AS SELECT * FROM transaksi;

-- Backup detail_laundry
CREATE TABLE detail_laundry_backup AS SELECT * FROM detail_laundry;

-- Backup pembayaran
CREATE TABLE pembayaran_backup AS SELECT * FROM pembayaran;

-- Backup order_kurir
CREATE TABLE order_kurir_backup AS SELECT * FROM order_kurir;
```

### **2. Restore dari Backup (Jika Perlu)**

```sql
-- Restore transaksi
INSERT INTO transaksi SELECT * FROM transaksi_backup;

-- Restore detail_laundry
INSERT INTO detail_laundry SELECT * FROM detail_laundry_backup;

-- Restore pembayaran
INSERT INTO pembayaran SELECT * FROM pembayaran_backup;

-- Restore order_kurir
INSERT INTO order_kurir SELECT * FROM order_kurir_backup;
```

### **3. Alternative: Soft Delete (Opsional)**

Jika ingin lebih aman, bisa menggunakan soft delete (tambahkan kolom `deleted_at`):

```sql
-- Tambahkan kolom deleted_at
ALTER TABLE transaksi ADD COLUMN deleted_at TIMESTAMP;

-- Update policy untuk filter deleted rows
CREATE POLICY "Users can view non-deleted transactions"
ON transaksi
FOR SELECT
TO authenticated
USING (deleted_at IS NULL);
```

Tapi ini memerlukan perubahan di aplikasi juga.

---

## 🎯 Kesimpulan

### **YA, Perlu Perubahan di Supabase:**

1. ✅ **Tambahkan RLS Policies** untuk DELETE (owner only)
2. ✅ **Test policies** sebelum deploy ke production
3. ✅ **Backup data** sebelum testing
4. ⚠️ **Monitor** setelah deploy untuk memastikan tidak ada masalah

### **Yang TIDAK Perlu Diubah:**

- ❌ Schema tabel (tidak ada kolom baru)
- ❌ Foreign keys (tetap sama)
- ❌ Indexes (tetap sama)
- ❌ Triggers (jika ada, tetap sama)

---

## 🚀 Langkah Selanjutnya

1. **Buka Supabase Dashboard** → SQL Editor
2. **Jalankan script SQL** di atas (Opsi 1)
3. **Test** dengan mencoba delete dari aplikasi
4. **Monitor** untuk memastikan tidak ada error
5. **Deploy** ke production setelah testing berhasil

---

**File ini berisi semua informasi yang diperlukan untuk mengupdate Supabase agar fitur reset riwayat berfungsi dengan baik!**

-- ============================================
-- RLS Policies untuk Reset Riwayat (Owner Only)
-- FIXED: Type casting untuk text = uuid
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

-- ============================================
-- CATATAN:
-- Menggunakan ::text untuk type casting karena:
-- - auth.uid() mengembalikan UUID
-- - users.id bertipe TEXT
-- - Perlu casting ke text untuk perbandingan
-- ============================================

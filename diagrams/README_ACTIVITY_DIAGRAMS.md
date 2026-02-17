# Activity Diagrams - Per Role

## Overview
Dokumen ini berisi activity diagram yang dipisahkan berdasarkan role (Owner, Kasir, Kurir). Setiap role memiliki diagram tersendiri yang menjelaskan alur kerja masing-masing.

## Files

### 1. **Kasir (Cashier)**
- **Markdown**: `activity_diagram_kasir.md`
- **Interactive HTML**: `activity_diagram_kasir.html` ⭐ **Buka file ini untuk melihat diagram**

**Use Cases Kasir:**
- UC-01: Login ke Sistem
- UC-03: Terima Laundry Baru
- UC-04: Kelola Transaksi
- UC-05: Update Status Transaksi
- UC-06: Input Pembayaran
- UC-07: Generate QRIS
- UC-08: Cetak Struk
- UC-09: Assign Kurir
- UC-10: Lihat Riwayat Transaksi
- UC-11: Kelola Pelanggan

---

### 2. **Kurir (Courier)**
- **Markdown**: `activity_diagram_kurir.md`
- **Interactive HTML**: `activity_diagram_kurir.html` ⭐ **Buka file ini untuk melihat diagram**

**Use Cases Kurir:**
- UC-01: Login ke Sistem
- UC-12: Lihat Order Pengiriman
- UC-13: Mulai Pengiriman
- UC-14: Update Status Pengiriman
- UC-15: Terima Pembayaran COD
- UC-16: Lihat Riwayat Pengiriman

---

### 3. **Owner**
- **Markdown**: `activity_diagram_owner.md`
- **Interactive HTML**: `activity_diagram_owner.html` ⭐ **Buka file ini untuk melihat diagram**

**Use Cases Owner:**
- UC-01: Login ke Sistem
- UC-17: Lihat Dashboard Analitik
- UC-18: Lihat Total Omzet
- UC-19: Lihat Grafik Pendapatan
- UC-20: Verifikasi Pembayaran COD
- UC-21: Lihat Laporan
- UC-22: Kelola User
- UC-23: Monitoring Kasir & Kurir
- UC-24: Reset Riwayat Transaksi

---

## Cara Melihat Diagram

### Option 1: Interactive HTML (Recommended) ⭐
1. Buka file HTML di browser (double-click atau klik kanan → Open with → Browser):
   - `activity_diagram_kasir.html`
   - `activity_diagram_kurir.html`
   - `activity_diagram_owner.html`

2. Diagram akan otomatis ter-render dengan Mermaid.js
3. Anda dapat melihat flowchart yang interaktif dan dapat di-zoom

### Option 2: Markdown File
1. Buka file `.md` di editor yang mendukung Mermaid (VS Code, Obsidian, GitHub, dll.)
2. Preview akan menampilkan diagram

---

## Keterangan

- **Masing-masing role memiliki diagram terpisah** sesuai permintaan
- Setiap diagram menjelaskan detail alur kerja dari awal (login) hingga logout
- Diagram menggunakan syntax Mermaid flowchart
- File HTML sudah include Mermaid.js library dari CDN, jadi langsung bisa dibuka tanpa instalasi

---

## Export to PNG

Untuk export diagram ke PNG:

1. **Via Browser** (dari file HTML):
   - Buka file HTML di browser
   - Gunakan screenshot tools atau browser's "Print to PDF" feature
   - Atau gunakan browser extension seperti "Full Page Screenshot"

2. **Via Online Tool**:
   - Copy kode Mermaid dari file `.md`
   - Paste ke https://mermaid.live/
   - Download as PNG/SVG

3. **Via Mermaid CLI** (jika sudah terinstal):
   ```bash
   mmdc -i activity_diagram_kasir.md -o activity_diagram_kasir.png
   ```

---

## Status Alur

### Alur Transaksi (Kasir & Kurir)
```
PENDING → PROSES → SELESAI → DIKIRIM → DITERIMA
```

### Alur Order Kurir
```
ASSIGNED → ON_DELIVERY → DELIVERED
```

### Status Pembayaran
```
PENDING → BELUM_LUNAS → LUNAS
atau
PENDING → LUNAS (jika langsung lunas)
```

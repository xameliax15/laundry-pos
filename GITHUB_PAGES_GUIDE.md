# GitHub Pages Deployment Guide

## ✅ Setup Selesai!

Saya sudah menyiapkan:
- ✅ GitHub Actions workflow (`.github/workflows/deploy.yml`)
- ✅ Updated `base href` di `web/index.html` menjadi `/laundry-pos/`
- ✅ Auto-build dan deploy setiap push ke `main`

---

## 🚀 Langkah Aktivasi GitHub Pages (WAJIB!)

### 1. Buka Repository GitHub
- Go to: `https://github.com/xameliax15/laundry-pos`

### 2. Settings → Pages
- Klik tab **Settings** di repository
- Scroll ke menu **Pages** (sidebar kiri)

### 3. Enable GitHub Pages
- **Source:** Pilih **GitHub Actions** (bukan Deploy from branch!)
- **Branch:** Tidak perlu dipilih (gunakan Actions)
- Klik **Save**

### 4. Tunggu Deployment
- Kembali ke tab **Actions**
- Tunggu workflow "Deploy Flutter Web to GitHub Pages" selesai (~3-5 menit)
- Status hijau ✅ = berhasil

### 5. Akses Aplikasi
URL aplikasi:
```
https://xameliax15.github.io/laundry-pos/
```

---

## 📋 Troubleshooting

### Workflow Error: "Process completed with exit code 1"
**Penyebab:** Flutter build gagal (biasanya dependency issue)

**Solusi:**
1. Cek log di tab Actions
2. Pastikan `pubspec.yaml` valid
3. Coba build lokal: `flutter build web --release`

### Error 404 Page Not Found
**Penyebab:** Base href tidak sesuai atau Pages belum aktif

**Solusi:**
1. Pastikan Settings → Pages → Source = **GitHub Actions**
2. Pastikan `web/index.html` punya `<base href="/laundry-pos/">`
3. Re-run workflow di tab Actions

### Aplikasi Blank/White Screen
**Penyebab:** Asset tidak ter-load (base href issue)

**Solusi:**
1. Inspect browser console (F12)
2. Cek error "Failed to load asset"
3. Pastikan base href sudah benar: `/laundry-pos/`

---

## 🔄 Cara Update Aplikasi

Setiap kali Anda push ke GitHub:
```bash
git add .
git commit -m "Update aplikasi"
git push origin main
```

GitHub Actions akan otomatis:
1. Build Flutter web
2. Deploy ke GitHub Pages
3. Aplikasi live dalam 3-5 menit

---

## ⚙️ Konfigurasi Supabase (PENTING!)

**JANGAN LUPA!** Edit file `lib/core/constants.dart` dan ganti:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Dengan credentials Supabase Anda yang sebenarnya, lalu push lagi.

---

## 📊 Monitor Deployment

- **GitHub Actions:** `https://github.com/xameliax15/laundry-pos/actions`
- **Live URL:** `https://xameliax15.github.io/laundry-pos/`

---

**Status:** ✅ Ready to deploy!
**Next Step:** Enable GitHub Pages di Settings → Pages

# CARA DEPLOY FLUTTER WEB KE GITHUB PAGES
## Step-by-Step Guide (WAJIB DIIKUTI!)

---

## ⚠️ MASALAH: README yang Muncul, Bukan Aplikasi

Ini terjadi karena **GitHub Pages belum di-enable dengan benar**. 

GitHub Pages masih mode "Deploy from branch" (default) yang hanya render README.md, 
bukan mode "GitHub Actions" yang build Flutter app.

---

## ✅ SOLUSI: Enable GitHub Pages dengan GitHub Actions

### **📋 LANGKAH 1: Buka Settings → Pages**

1. Buka repository: `https://github.com/xameliax15/laundry-pos`
2. Klik tab **Settings** (paling kanan)
3. Di sidebar kiri, scroll ke bawah, klik **Pages**

---

### **📋 LANGKAH 2: Ubah Source ke GitHub Actions**

Di halaman Pages, Anda akan lihat:

**Build and deployment**

**Source:** [Dropdown menu - KLIK INI!]

**PENTING:** Pilih **GitHub Actions** (JANGAN pilih "Deploy from a branch")

```
┌─────────────────────────────────────┐
│ Source:                             │
│  ○ Deploy from a branch             │  ← JANGAN INI!
│  ● GitHub Actions            ✅     │  ← PILIH INI!
└─────────────────────────────────────┘
```

Setelah pilih "GitHub Actions", setting akan otomatis save.

---

### **📋 LANGKAH 3: Cek GitHub Actions Workflow**

1. Klik tab **Actions** (di repository)
2. Lihat workflow "Deploy Flutter Web to GitHub Pages"
3. Tunggu sampai status **hijau ✅** (3-5 menit)
4. Jika merah ❌, klik untuk lihat log error

**Status Workflow:**
- 🟡 **Kuning (Running)** = Sedang build, tunggu sebentar
- ✅ **Hijau (Success)** = Deployment berhasil, aplikasi sudah live!
- ❌ **Merah (Failed)** = Ada error, cek log

---

### **📋 LANGKAH 4: Akses Aplikasi Live**

Setelah workflow hijau ✅, akses:

```
https://xameliax15.github.io/laundry-pos/
```

**Jika masih 404 atau README:**
- Tunggu 2-3 menit (propagasi DNS)
- Hard refresh browser: `Ctrl + Shift + R` (Windows) atau `Cmd + Shift + R` (Mac)
- Clear browser cache

---

## 🔧 TROUBLESHOOTING

### **Problem: "Enable GitHub Pages di mana ya?"**

**Solusi:**
1. Repository → Settings (tab paling kanan)
2. Scroll sidebar kiri → Pages (paling bawah)
3. Source → Pilih "GitHub Actions"

### **Problem: "Workflow tetap merah ❌"**

**Solusi:**
1. Klik workflow yang failed
2. Klik job "build" atau "deploy"
3. Screenshot error log
4. Hubungi developer (saya) dengan screenshot

### **Problem: "Aplikasi blank/putih"**

**Solusi:**
1. Buka browser console (F12)
2. Cek error "Failed to load"
3. Kemungkinan base href salah (sudah saya fix)

### **Problem: "Masih muncul README"**

**Solusi:**
1. Pastikan GitHub Pages Source = **GitHub Actions** (bukan Deploy from branch!)
2. Re-run workflow di tab Actions
3. Wait 5 minutes
4. Hard refresh: `Ctrl + Shift + R`

---

## ✅ CHECKLIST DEPLOYMENT

Pastikan semua ini sudah dilakukan:

- [ ] Settings → Pages → Source = **GitHub Actions** ✅
- [ ] Tab Actions → Workflow status = **Hijau ✅**
- [ ] Hard refresh browser: `Ctrl + Shift + R`
- [ ] Akses: `https://xameliax15.github.io/laundry-pos/`

---

## 📞 BUTUH BANTUAN?

Jika masih bermasalah setelah ikuti semua step:
1. Screenshot halaman Settings → Pages
2. Screenshot tab Actions (workflow status)
3. Screenshot browser console (F12) saat akses URL
4. Kirim ke developer untuk debugging

---

**PENTING:** Aplikasi Flutter yang di-build GitHub Actions akan otomatis update setiap kali Anda push ke GitHub!

No manual upload needed! 🎉

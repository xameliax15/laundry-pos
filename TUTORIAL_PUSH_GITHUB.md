# Tutorial Push ke GitHub

## Langkah 1: Inisialisasi Git Repository

Jika repository belum diinisialisasi, jalankan:

```bash
cd d:\flutter_project\laundry_pos
git init
```

## Langkah 2: Buat File .gitignore (jika belum ada)

Pastikan file `.gitignore` sudah ada dan berisi:

```
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.iml
*.ipr
*.iws
.idea/

# Android
android/.gradle/
android/app/build/
android/.idea/
android/local.properties
*.apk
*.aab

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/Flutter/Generated.xcconfig
ios/Flutter/app.flx
ios/Flutter/app.zip
ios/Flutter/flutter_assets/
ios/Flutter/flutter_export_environment.sh
ios/ServiceDefinitions.json
ios/Runner/GeneratedPluginRegistrant.*

# Web
web/

# Windows
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugins.cmake

# macOS
macos/Flutter/GeneratedPluginRegistrant.swift

# Linux
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugin_registrant.h
linux/flutter/generated_plugins.cmake

# Environment variables
.env
.env.local

# Logs
*.log

# Database
*.db
*.sqlite
*.sqlite3

# OS
.DS_Store
Thumbs.db

# VS Code
.vscode/
*.code-workspace

# Cursor
.cursor/
```

## Langkah 3: Tambahkan Semua File ke Staging Area

```bash
git add .
```

Atau tambahkan file spesifik:

```bash
git add lib/
git add pubspec.yaml
git add README.md
```

## Langkah 4: Commit Perubahan

```bash
git commit -m "Initial commit: Laundry POS System dengan fitur riwayat transaksi"
```

Atau dengan pesan yang lebih detail:

```bash
git commit -m "feat: tambahkan halaman riwayat transaksi kasir

- Buat halaman kasir_riwayat.dart terpisah
- Tambahkan route /kasir/riwayat
- Tambahkan menu Riwayat Transaksi di sidebar
- Fitur pencarian dan filter transaksi
- Tampilkan detail lengkap: laundry, foto, pembayaran"
```

## Langkah 5: Buat Repository di GitHub

1. Buka https://github.com
2. Klik tombol **"+"** di pojok kanan atas → **"New repository"**
3. Isi:
   - **Repository name**: `laundry_pos` (atau nama lain)
   - **Description**: "Aplikasi Point of Sale untuk manajemen laundry"
   - **Visibility**: Pilih Public atau Private
   - **JANGAN** centang "Initialize this repository with a README" (karena sudah ada code lokal)
4. Klik **"Create repository"**

## Langkah 6: Tambahkan Remote Repository

Setelah repository dibuat di GitHub, copy URL repository (misalnya: `https://github.com/username/laundry_pos.git`)

Kemudian jalankan:

```bash
git remote add origin https://github.com/username/laundry_pos.git
```

Atau jika menggunakan SSH:

```bash
git remote add origin git@github.com:username/laundry_pos.git
```

## Langkah 7: Push ke GitHub

### Untuk pertama kali (branch main/master):

```bash
git branch -M main
git push -u origin main
```

Jika menggunakan branch master:

```bash
git branch -M master
git push -u origin master
```

## Langkah 8: Verifikasi

Buka repository di GitHub dan pastikan semua file sudah ter-upload.

---

## Perintah Git yang Sering Digunakan

### Melihat status perubahan:
```bash
git status
```

### Melihat perubahan yang belum di-commit:
```bash
git diff
```

### Melihat history commit:
```bash
git log
```

### Menambahkan file spesifik:
```bash
git add nama_file.dart
```

### Commit dengan pesan:
```bash
git commit -m "Pesan commit"
```

### Push perubahan:
```bash
git push
```

### Pull perubahan dari GitHub:
```bash
git pull
```

### Melihat remote repository:
```bash
git remote -v
```

### Mengubah remote URL:
```bash
git remote set-url origin https://github.com/username/repository.git
```

---

## Workflow Harian

### 1. Sebelum mulai coding:
```bash
git pull
```

### 2. Setelah membuat perubahan:
```bash
git add .
git commit -m "Deskripsi perubahan"
git push
```

### 3. Jika ada konflik:
```bash
git pull
# Resolve conflict
git add .
git commit -m "Fix conflict"
git push
```

---

## Tips Commit Message yang Baik

Gunakan format:
```
tipe: deskripsi singkat

Deskripsi detail (opsional)
```

**Tipe commit:**
- `feat`: Fitur baru
- `fix`: Perbaikan bug
- `docs`: Perubahan dokumentasi
- `style`: Formatting, missing semicolons, dll
- `refactor`: Refactoring code
- `test`: Menambah/memperbaiki test
- `chore`: Maintenance tasks

**Contoh:**
```bash
git commit -m "feat: tambahkan halaman riwayat transaksi kasir"
git commit -m "fix: perbaiki error pada filter transaksi"
git commit -m "docs: update README dengan instruksi instalasi"
```

---

## Troubleshooting

### Error: "fatal: not a git repository"
**Solusi:** Jalankan `git init` di folder project

### Error: "remote origin already exists"
**Solusi:** 
```bash
git remote remove origin
git remote add origin https://github.com/username/repository.git
```

### Error: "failed to push some refs"
**Solusi:** 
```bash
git pull origin main --rebase
git push
```

### Error: "authentication failed"
**Solusi:** 
- Gunakan Personal Access Token (PAT) sebagai password
- Atau setup SSH key di GitHub

---

## Setup Authentication GitHub

### Opsi 1: Personal Access Token (PAT)

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Copy token dan gunakan sebagai password saat push

### Opsi 2: SSH Key

1. Generate SSH key:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. Copy public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

3. GitHub → Settings → SSH and GPG keys → New SSH key
4. Paste public key

5. Test connection:
```bash
ssh -T git@github.com
```

---

## Catatan Penting

⚠️ **JANGAN commit file-file berikut:**
- `.env` (berisi credentials)
- `*.db` atau `*.sqlite` (database lokal)
- File build (`build/`, `*.apk`, dll)
- File konfigurasi IDE (`.idea/`, `.vscode/`)

✅ **SELALU commit:**
- Source code (`lib/`)
- Konfigurasi project (`pubspec.yaml`, `pubspec.lock`)
- Dokumentasi (`README.md`, `*.md`)
- Assets yang diperlukan (`assets/`)

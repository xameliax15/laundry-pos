# Cara Verifikasi Visual Studio Installation

Setelah instalasi Visual Studio selesai, ikuti langkah berikut:

## 1. Restart Terminal/Command Prompt
Tutup semua terminal yang terbuka dan buka terminal baru.

## 2. Jalankan Flutter Doctor
```bash
flutter doctor -v
```

## 3. Cek Bagian Visual Studio
Anda harus melihat tanda centang (√) di bagian Visual Studio, seperti ini:

```
[√] Visual Studio - develop Windows apps
    • Visual Studio Community 2022 17.x.x
    • Visual Studio Community 2022 - workload Desktop development with C++
```

## 4. Jika Masih Error
Jika masih ada error, jalankan:
```bash
flutter doctor --android-licenses
```

Kemudian coba lagi:
```bash
flutter doctor
```

## 5. Test Build Windows App
Setelah semua OK, coba build aplikasi:
```bash
flutter run -d windows
```

atau

```bash
flutter build windows
```





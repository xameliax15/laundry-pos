# Cara Memperbaiki Android cmdline-tools dan Licenses

## Cara 1: Melalui Android Studio (Paling Mudah)

### Langkah 1: Buka Android Studio
1. Buka Android Studio
2. Klik **More Actions** → **SDK Manager** (atau **Tools** → **SDK Manager**)

### Langkah 2: Install cmdline-tools
1. Di tab **SDK Tools**
2. Centang **Android SDK Command-line Tools (latest)**
3. Klik **Apply** → **OK**
4. Tunggu sampai instalasi selesai

### Langkah 3: Set Environment Variable (jika belum)
1. Buka **System Properties** → **Environment Variables**
2. Buat variable baru:
   - Name: `ANDROID_HOME`
   - Value: `C:\Users\panda\AppData\Local\Android\sdk`
3. Edit variable **Path**, tambahkan:
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\cmdline-tools\latest\bin`
4. Klik **OK** pada semua dialog
5. **Restart terminal/command prompt**

### Langkah 4: Accept Android Licenses
Buka terminal baru dan jalankan:
```bash
flutter doctor --android-licenses
```

Tekan **Y** untuk setiap license yang muncul.

## Cara 2: Manual Download (Alternatif)

Jika cara 1 tidak berhasil, download manual:
1. Download dari: https://developer.android.com/studio#command-line-tools-only
2. Extract ke: `C:\Users\panda\AppData\Local\Android\sdk\cmdline-tools\latest`
3. Set environment variable seperti di atas
4. Restart terminal





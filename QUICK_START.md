# 🚀 Quick Start Guide - Laundry POS

Panduan cepat untuk setup dan run aplikasi Laundry POS setelah implementasi improvements.

---

## 1️⃣ Setup Environment Variables

### Step 1: Create `.env` file
```bash
cp .env.example .env
```

### Step 2: Edit `.env` dengan credentials
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
APP_NAME=Trias Laundry POS
```

**Get credentials dari**: [Supabase Dashboard](https://app.supabase.com)

---

## 2️⃣ Install Dependencies

```bash
flutter pub get
```

**New packages added**:
- flutter_dotenv (environment variables)
- logger (professional logging)
- provider (state management)
- shared_preferences (local storage)

---

## 3️⃣ Run Application

### Desktop (Windows/Linux/macOS)
```bash
flutter run -d windows   # atau linux, macos
```

### Web
```bash
flutter run -d chrome
```

### Mobile
```bash
flutter run
# dengan Android emulator atau iOS simulator terhubung
```

---

## 📝 Important Changes

### 1. Logging
❌ **OLD**: `print('message');`  
✅ **NEW**: `logger.i('message');`

```dart
import 'package:laundry_pos/core/logger.dart';

logger.d('Debug info');          // DEBUG
logger.i('Info message');        // INFO
logger.w('⚠️ Warning');          // WARNING
logger.e('Error', error: e);     // ERROR
logger.wtf('Critical!');         // CRITICAL
```

### 2. Environment Variables
✅ **GOOD**: `AppConstants.supabaseUrl` (dari .env)  
❌ **AVOID**: Hardcoded credentials

### 3. Local Storage
```dart
import 'package:laundry_pos/database/local_db.dart';

final localStorage = LocalDB();
await localStorage.init();

// Save token
await localStorage.saveToken('my_token');

// Get token
final token = await localStorage.getToken();
```

### 4. State Management (Provider)
```dart
// Access auth state
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Text('User: ${authProvider.currentUser?.username}');
  },
)

// Trigger login
context.read<AuthProvider>().login(username, password);
```

---

## 🎯 Development Workflow

### 1. Create New Feature
```dart
// 1. Add logger import
import 'package:laundry_pos/core/logger.dart';

// 2. Use logger instead of print
logger.i('Feature started');

// 3. Handle errors properly
try {
  // do something
} catch (e) {
  logger.e('Error occurred', error: e);
  rethrow;
}
```

### 2. Use Providers for State
```dart
// Instead of setState, use Provider
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Text(authProvider.currentUser?.username ?? '');
      },
    );
  }
}
```

### 3. Store Sensitive Data
```dart
// Use LocalDB for tokens/user data
final localStorage = LocalDB();
await localStorage.saveUserData(jsonEncode(userData));
```

---

## 📚 File Structure

```
lib/
├── core/
│   ├── logger.dart           ← Use this for logging
│   ├── constants.dart        ← App-wide constants
│   └── ...
├── providers/
│   ├── app_providers.dart    ← State definitions
│   └── provider_setup.dart   ← Provider setup
├── database/
│   ├── local_db.dart         ← Local storage
│   └── ...
├── services/
│   ├── auth_service.dart     ← Business logic
│   └── ...
└── main.dart                 ← Entry point (already configured)
```

---

## ✨ Best Practices

### ✅ DO's:
```dart
// Use logger
logger.i('✅ Success');

// Use environment variables
String url = AppConstants.supabaseUrl;

// Use local storage for tokens
await localStorage.saveToken(token);

// Use Providers for state
context.watch<AuthProvider>();

// Keep files under 500 lines
// Split large files into widgets
```

### ❌ DON'Ts:
```dart
// Don't use print()
print('message');  // ❌ BAD

// Don't hardcode credentials
const String url = 'https://...';  // ❌ BAD

// Don't store secrets in code
const String apiKey = 'secret';  // ❌ BAD

// Don't use setState for complex state
setState(() { /* ... */ });  // ❌ For complex logic

// Don't create 3000+ line files
// Split into components instead
```

---

## 🐛 Troubleshooting

### Issue: "SUPABASE_URL is null"
**Solution**: Check `.env` file exists and has correct values
```bash
cat .env  # Check file content
```

### Issue: "logger not found"
**Solution**: Add import
```dart
import 'package:laundry_pos/core/logger.dart';
```

### Issue: "Provider not initialized"
**Solution**: Make sure `main.dart` has `ProviderSetup.wrapWithProviders()`  
(Already done - should work out of the box)

### Issue: "LocalDB initialization failed"
**Solution**: Call `init()` before using
```dart
final localStorage = LocalDB();
await localStorage.init();  // Important!
```

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────┐
│         MaterialApp                  │
│  (wrapped dengan MultiProvider)     │
├─────────────────────────────────────┤
│  Providers                           │
│  ├── AuthProvider                   │
│  └── TransaksiProvider              │
├─────────────────────────────────────┤
│  Services                            │
│  ├── AuthService                    │
│  ├── TransaksiService               │
│  └── FmsService                     │
├─────────────────────────────────────┤
│  Database                            │
│  ├── DatabaseHelper (SQLite)        │
│  └── LocalDB (SharedPreferences)    │
├─────────────────────────────────────┤
│  UI Widgets (using Providers)       │
│  ├── Pages                          │
│  └── Reusable Components            │
└─────────────────────────────────────┘
```

---

## 🎁 Bonus Features

### File Management (FMS Service)
```dart
final fmsService = FmsService();

// Upload file
final fileName = await fmsService.uploadFile(filePath);

// Download file
final data = await fmsService.downloadFile(fileName);

// Get public URL
final url = await fmsService.getFileUrl(fileName);

// Delete file
await fmsService.deleteFile(fileName);
```

### Activity Logging
```dart
// Automatically logs user activities
logger.i('User ${user.username} performed action: LOGIN');
```

---

## 📞 Need Help?

1. **Check README.md** - Comprehensive documentation
2. **Check IMPLEMENTATION_SUMMARY.md** - What was changed
3. **Check code comments** - Inline documentation
4. **Check logger output** - Debug with logger

---

## 🎯 Next Steps

1. ✅ Read this Quick Start guide
2. ✅ Copy `.env.example` to `.env` and fill credentials
3. ✅ Run `flutter pub get`
4. ✅ Run `flutter run`
5. ✅ Start developing with new patterns!

---

**Happy Coding! 🚀**

*Last Updated: January 26, 2026*

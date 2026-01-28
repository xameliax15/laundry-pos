# Laundry POS System

Aplikasi Point of Sale (POS) profesional untuk manajemen laundry dengan fitur real-time tracking, multi-user dashboard, dan integrasi backend Supabase.

## 📋 Features

- **📝 Manajemen Transaksi**: Buat, update, dan tracking transaksi laundry
- **👥 Multi-role Dashboard**: Fitur khusus untuk Owner, Kasir, dan Kurir
- **📊 Real-time Analytics**: Dashboard dengan statistik pendapatan dan transaksi
- **🚚 Tracking Kurir**: Monitor pengiriman dan penjemputan laundry
- **💰 Manajemen Pembayaran**: Support berbagai metode pembayaran
- **🔐 Authentication**: Login aman dengan role-based access control
- **📱 Responsive UI**: Support desktop, web, dan mobile
- **💾 Offline Support**: SQLite local database untuk offline functionality
- **📸 Image Capture**: Dokumentasi laundry dengan foto

## 🚀 Quick Start

### Prerequisites

- Flutter 3.10+ ([Download](https://flutter.dev/docs/get-started/install))
- Dart SDK (included dengan Flutter)
- Code editor (VS Code, Android Studio, atau IntelliJ)
- Supabase account ([Sign up gratis](https://supabase.com))

### Installation

1. **Clone Repository**
```bash
git clone <repository-url>
cd laundry_pos
```

2. **Setup Environment Variables**
```bash
cp .env.example .env
# Edit .env dengan credentials Supabase Anda
```

**Isi `.env` dengan:**
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
APP_NAME=Trias Laundry POS
```

3. **Install Dependencies**
```bash
flutter pub get
```

4. **Run Application**
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── core/                      # Core utilities & config
│   ├── constants.dart         # App constants (dari .env)
│   ├── logger.dart            # Structured logging utility
│   ├── routes.dart            # Route definitions
│   └── transaction_fsm.dart   # Finite State Machine
├── models/                    # Data models
├── services/                  # Business logic
├── pages/                     # UI pages per role
├── widgets/                   # Reusable components
├── database/                  # Local SQLite DB
├── theme/                     # Styling & colors
└── main.dart                  # Entry point
```

## 🔧 Architecture

- **Logging**: `logger` package (structured logging, bukan print())
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Local DB**: SQLite dengan offline sync
- **State Management**: StatefulWidget (akan upgrade ke Provider/Riverpod)

## 📋 Development Guidelines

### Logging
```dart
import 'package:laundry_pos/core/logger.dart';

logger.i('Info message');
logger.e('Error', error: exception);
// JANGAN gunakan print()!
```

### Environment Variables
```dart
// Gunakan dari .env, jangan hardcode!
String url = AppConstants.supabaseUrl;
```

### Code Style
- Max file: 500 lines (refactor jika lebih)
- Meaningful variable names
- Follow Dart conventions

## 🚀 Deployment

```bash
# Android
flutter build apk --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## ✅ Recent Improvements (v1.0)

✨ **New Features**:
- ✅ Environment variable support (.env file)
- ✅ Structured logging dengan logger package
- ✅ Comprehensive README documentation
- ✅ Better code organization

🔄 **In Progress**:
- 🔄 Refactor kasir_dashboard.dart (split to widgets)
- 🔄 Add Provider state management
- 🔄 Remove TODO comments

## 📞 Support

See [issue tracker](../../issues) untuk questions & bugs.

---
**Last Updated**: January 26, 2026 | **Version**: 1.0.0+1

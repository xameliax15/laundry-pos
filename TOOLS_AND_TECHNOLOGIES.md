# 📦 TOOLS & TECHNOLOGIES STACK - Laundry POS Application

## 1. 🎯 FRAMEWORK & RUNTIME
- **Flutter 3.10.4+** - UI Framework (cross-platform: Windows, Web, iOS, Android, macOS, Linux)
- **Dart 3.10.4+** - Programming Language
- **Material Design 3** - UI Design System

---

## 2. 🗄️ DATABASE & BACKEND
### Backend Services
- **Supabase** (PostgreSQL-based)
  - PostgreSQL Database (relational)
  - Authentication (email/password)
  - Real-time Subscriptions
  - Storage (file uploads)
  - Row Level Security (RLS)

### Local Database
- **SQLite** (`sqflite: 2.3.0`)
  - Offline data storage
  - Local caching
  - Cross-platform support
  
### Local Storage
- **SharedPreferences** (`shared_preferences: 2.2.0`)
  - User preferences
  - App configuration
  - Token caching
  - Simple key-value storage

---

## 3. 📦 DEPENDENCIES (dari pubspec.yaml)

### Environment & Configuration
- **flutter_dotenv** (5.1.0)
  - Environment variables (.env file)
  - Configuration management
  - API credentials storage

### State Management
- **provider** (6.0.0)
  - Reactive state management
  - Dependency injection
  - ChangeNotifier pattern
  - AuthProvider, TransaksiProvider

### Logging & Debugging
- **logger** (2.0.0)
  - Structured logging
  - Console output with colors
  - Multiple log levels (debug, info, warn, error)
  - Replaces print() statements

### File & Path Management
- **path_provider** (2.1.1)
  - Platform-specific paths
  - Documents, Cache, Temp directories
  
- **path** (1.8.3)
  - Path manipulation utilities

### Media & File Handling
- **image_picker** (1.0.7)
  - Camera access
  - Gallery access
  - Image selection & cropping

### Backend API
- **supabase_flutter** (2.12.0)
  - Supabase client library
  - Real-time updates
  - Authentication
  - Database queries
  - Storage operations

### UI Icons
- **cupertino_icons** (1.0.8)
  - iOS-style icons
  - Material Design icons

### Database Compatibility
- **sqflite_common_ffi** (2.3.0)
  - SQLite for desktop (Windows, macOS, Linux)
  
- **sqflite_common_ffi_web** (0.4.2+3)
  - SQLite for web platform

---

## 4. 🎨 DESIGN SYSTEM (Implemented in App)

### Theme System
- **AppTheme** (`lib/theme/app_theme.dart`)
  - Material 3 ColorScheme
  - Custom theme configuration
  - Light theme (dark mode coming Phase 3)

### Color Palette
- **AppColors** (`lib/theme/app_colors.dart`)
  - Sky Blue, Brand Blue, Deep Blue
  - Accent: Orange, Green, Purple
  - Neutrals: Gray scales
  - Semantic: Success, Warning, Error, Info

### Typography System
- **AppTextStyles** (`lib/theme/app_text_styles.dart`) - NEW
  - Display styles (3 variants: 32px, 28px, 24px)
  - Headline styles (2 variants: 22px, 20px)
  - Body styles (3 variants: 16px, 14px, 12px)
  - Label styles (3 variants: 14px, 12px, 11px)
  - Semantic styles: caption, error, success, warning

### Dimensions & Spacing
- **AppDimensions** (`lib/theme/app_dimensions.dart`) - NEW
  - AppSpacing (xs: 4px → xxl: 48px)
  - AppRadius (sm: 8px → circle: 100)
  - AppElevation (none: 0 → xxl: 16)
  - AppIconSize (sm: 16px → xxl: 64px)
  - AppSizes (button, input, card, navigation heights)
  - AppBreakpoints (mobile, tablet, desktop, ultraWide)

---

## 5. 🏗️ ARCHITECTURE LAYERS

### Services Layer
- **AuthService** - User authentication & profile management
- **TransaksiService** - Transaction CRUD operations
- **CustomerService** - Customer management
- **FMSService** - Flexible Maintenance Services
- **UserService** - User data operations
- **FileStorageService** (implicit via Supabase)

### Database Layer
- **DatabaseHelper** - SQLite initialization & factory setup
- **LocalDB** - SharedPreferences wrapper for local storage

### State Management (Provider Pattern)
- **AuthProvider** - User authentication state
- **TransaksiProvider** - Transaction state
- **ProviderSetup** - Multi-provider initialization

### Logging
- **Logger** (`lib/core/logger.dart`) - Structured logging utility

### Constants & Configuration
- **AppConstants** - App-wide constants & .env configuration
- **AppRoutes** - Navigation routing
- **PriceList** - Service pricing configuration

---

## 6. 🎯 FEATURE-SPECIFIC TOOLS

### Authentication
- Supabase Authentication (email/password)
- JWT token management
- Session persistence with SharedPreferences

### Real-time Features
- Supabase Realtime subscriptions (coming)
- Stream-based updates

### Image Handling
- Image Picker (camera, gallery)
- Supabase Storage (image uploads)

### Payment/Pricing Calculations
- Custom PriceList logic
- Multiple service types (laundry kiloan, sepatu, jaket, helm, karpet, tas, boneka)
- Weight-based pricing (supports decimal: 2.5kg, 3.75kg)

### Offline Support
- Local SQLite caching
- Sync when online (planned)
- LocalDB for preferences

---

## 7. 📱 PLATFORM-SPECIFIC TOOLS

### Windows (Desktop)
- sqflite_common_ffi
- Native Windows APIs via Flutter
- Sidebar navigation for desktop layout

### Web (Chrome, Edge, Firefox)
- sqflite_common_ffi_web
- Web-compatible packages
- Responsive design for web

### iOS (Future)
- Cupertino widgets (iOS style)
- Image picker (camera + gallery)
- Path provider (documents access)

### Android (Future)
- Android-specific permissions
- Camera/gallery access
- File storage permissions

---

## 8. 🔧 DEVELOPMENT TOOLS (Not in pubspec.yaml)

### Testing
- **flutter_test** (built-in)
- Unit testing framework

### Linting & Code Quality
- **flutter_lints** (6.0.0)
- Dart analysis
- Code style enforcement

### Build Tools
- **Gradle** (Android)
- **Xcode** (iOS)
- **CMake** (Windows, Linux)
- **Web build system** (Chrome, Firefox, Safari)

### IDE & Editor Tools
- VS Code (editor)
- Dart Language Server (Pylance equivalent)
- Flutter DevTools
- Dart DevTools

---

## 9. 📊 DATA & SERVICES FLOW

```
┌─────────────────┐
│  Flutter UI     │
└────────┬────────┘
         │
    ┌────v─────┐
    │ Provider  │ (State Management)
    │ Pattern   │
    └────┬─────┘
         │
    ┌────v────────────────┐
    │ Services Layer       │
    │ - AuthService        │
    │ - TransaksiService   │
    │ - CustomerService    │
    │ - FMSService         │
    └────┬────────────────┘
         │
    ┌────v─────────────────┐
    │ Storage Layer         │
    │ - SharedPreferences   │
    │ - SQLite (Local)      │
    │ - Supabase (Remote)   │
    └──────────────────────┘
```

---

## 10. 🔐 SECURITY TOOLS

- **JWT Authentication** (Supabase)
- **Row Level Security** (RLS) - PostgreSQL policies
- **Environment Variables** (.env file with flutter_dotenv)
- **Supabase Anon Key** - Public API key for client-side operations

---

## 11. 📋 SUMMARY TABLE

| Category | Tool | Version | Purpose |
|----------|------|---------|---------|
| **Framework** | Flutter | 3.10.4+ | UI Framework |
| **Language** | Dart | 3.10.4+ | Programming |
| **Backend** | Supabase | 2.12.0 | BaaS (DB, Auth, Storage) |
| **Database** | PostgreSQL | (Cloud) | Relational DB |
| **Local DB** | SQLite | 2.3.0 | Offline storage |
| **Local Storage** | SharedPreferences | 2.2.0 | Key-value store |
| **State Mgmt** | Provider | 6.0.0 | Reactive state |
| **Logging** | Logger | 2.0.0 | Structured logging |
| **Config** | flutter_dotenv | 5.1.0 | Environment variables |
| **Media** | image_picker | 1.0.7 | Photos/Camera |
| **Path Mgmt** | path_provider | 2.1.1 | System paths |
| **UI Design** | Material 3 | (Built-in) | Design system |
| **Icons** | cupertino_icons | 1.0.8 | Icon set |
| **Desktop** | sqflite_common_ffi | 2.3.0 | SQLite for desktop |
| **Web** | sqflite_common_ffi_web | 0.4.2+3 | SQLite for web |
| **Linting** | flutter_lints | 6.0.0 | Code quality |

---

## 12. 🚀 TECH STACK SUMMARY

**Frontend**: Flutter + Dart + Material Design 3
**State Management**: Provider Pattern
**Backend**: Supabase (PostgreSQL + Auth + Storage)
**Local Storage**: SQLite + SharedPreferences
**Platforms**: Windows, Web, iOS (future), Android (future), macOS, Linux
**Design System**: Custom (AppColors, AppTextStyles, AppDimensions)
**Architecture**: Layered (UI → Services → Database)
**Authentication**: Supabase JWT
**Real-time**: Supabase Realtime (ready to implement)


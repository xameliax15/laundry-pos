# Phase 1 Implementation Checklist: Foundation

## ✅ COMPLETED (3/6)

### 1. ✅ Text Style System
- **File**: `lib/theme/app_text_styles.dart`
- **Status**: COMPLETE
- **What Changed**: Created centralized typography system with 12+ text style variants
- **Impact**: Ready to replace hardcoded TextStyle throughout app

### 2. ✅ Spacing & Dimensions System  
- **File**: `lib/theme/app_dimensions.dart`
- **Status**: COMPLETE
- **What Changed**: Created AppSpacing, AppRadius, AppElevation, AppIconSize, AppSizes, AppBreakpoints classes
- **Impact**: Ready to replace hardcoded EdgeInsets and size values

### 3. ✅ Loading Skeleton Screens
- **File**: `lib/widgets/skeleton_loader.dart`
- **Status**: COMPLETE
- **What Changed**: Created SkeletonLoader, ShimmerEffect, and 6 specialized skeleton widgets
- **Impact**: Replace CircularProgressIndicator with beautiful loading animations

### 4. ✅ Theme Integration
- **File**: `lib/theme/app_theme.dart`
- **Status**: UPDATED
- **What Changed**: Integrated AppTextStyles into TextTheme, updated all dimensions to use AppDimensions constants
- **Impact**: Theme system now uses centralized constants

---

## ⏳ IN PROGRESS (Remaining Pages to Update)

### Page Refactoring Order (Priority)

#### Phase 1A: Login & Core Pages (2-3 hours)
- [ ] **lib/pages/login_page.dart** (257 lines)
  - Replace hardcoded TextStyle with Theme.of(context).textTheme
  - Replace EdgeInsets values with AppSpacing constants
  - Replace BorderRadius values with AppRadius constants
  
#### Phase 1B: Dashboard Pages (4-6 hours)
- [ ] **lib/pages/kasir/kasir_dashboard.dart** (3738 lines - LARGEST FILE)
  - This is the main refactoring work
  - Replace all TextStyle usage with Theme.of(context).textTheme
  - Replace all hardcoded spacing (16, 24, 20, etc.) with AppSpacing
  - Add skeleton loaders for data loading states
  - Update widget extraction opportunities

- [ ] **lib/pages/owner/owner_dashboard.dart** (1472 lines)
  - Same refactoring pattern as kasir_dashboard
  - Replace TextStyle and spacing values

- [ ] **lib/pages/kurir/kurir_dashboard.dart** (936 lines)
  - Same refactoring pattern

#### Phase 1C: Existing Widgets (1-2 hours)
- [ ] **lib/widgets/kasir_stats_card.dart**
  - Replace hardcoded styles with Theme.of(context).textTheme
  - Replace spacing with AppSpacing

- [ ] **lib/widgets/kasir_transaction_card.dart**
  - Add skeleton loader variant
  - Update text styles and spacing

- [ ] **lib/widgets/kasir_action_buttons.dart**
  - Update button styles to use new system

- [ ] **lib/widgets/section_header.dart**
  - Update text styles

- [ ] **lib/widgets/empty_state_widget.dart**
  - Update text styles and spacing

- [ ] **lib/widgets/sidebar_layout.dart**
  - Replace hardcoded sidebarWidth (likely 280px) with AppSizes.sidebarWidthDesktop
  - Update responsive breakpoints using AppBreakpoints

---

## 📊 Progress Timeline

**Estimated Phase 1 Completion**: 1-2 days (8-12 hours of work)

```
Day 1 (Today):
✅ 9:00 AM  - Text style system created
✅ 10:00 AM - Spacing & dimensions system created  
✅ 11:00 AM - Skeleton loader system created
✅ 12:00 PM - Theme integration updated
⏳ 1:00 PM  - Login page refactor
⏳ 3:00 PM  - Kasir dashboard refactor (LARGEST - 2-3 hours)

Day 2:
⏳ 9:00 AM  - Owner & Kurir dashboard refactoring
⏳ 12:00 PM - Widget refactoring (stats cards, transaction cards, etc.)
✅ 3:00 PM  - Phase 1 COMPLETE
```

---

## 🎯 Expected Impact (Per Page)

### Login Page
- **Current Score**: 6/10
- **After Refactor**: 7.5/10
- **Improvements**: Consistent typography, better spacing, professional appearance

### Kasir Dashboard  
- **Current Score**: 4/10 (too large, inconsistent)
- **After Refactor**: 7/10
- **Improvements**: Clean spacing, consistent text styles, skeleton loaders during loading

### Owner Dashboard
- **Current Score**: 6/10
- **After Refactor**: 7.5/10
- **Improvements**: Better typography, consistent layout

### Kurir Dashboard
- **Current Score**: 5/10
- **After Refactor**: 6.5/10
- **Improvements**: Consistent styling system

### Overall App Rating
- **Before Phase 1**: 7/10
- **After Phase 1**: 8.5/10 (Foundation established)
- **After Phase 2** (animations): 9/10
- **After Phase 3** (dark mode): 10/10

---

## 🔧 How to Apply Changes

### Pattern 1: Text Styles
```dart
// BEFORE (hardcoded):
Text('Title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))

// AFTER (using system):
Text('Title', style: Theme.of(context).textTheme.headlineLarge)
```

### Pattern 2: Spacing
```dart
// BEFORE (hardcoded):
EdgeInsets.all(16), EdgeInsets.symmetric(horizontal: 24, vertical: 16)

// AFTER (using constants):
EdgeInsets.all(AppSpacing.md), EdgeInsets.symmetric(
  horizontal: AppSpacing.lg, 
  vertical: AppSpacing.md
)
```

### Pattern 3: Radius
```dart
// BEFORE (hardcoded):
BorderRadius.circular(12), BorderRadius.circular(16)

// AFTER (using constants):
BorderRadius.circular(AppRadius.md), BorderRadius.circular(AppRadius.lg)
```

### Pattern 4: Skeleton Loader
```dart
// BEFORE (loading):
if (isLoading) CircularProgressIndicator()

// AFTER (loading):
if (isLoading) ListViewSkeleton(itemCount: 5)
```

---

## ✨ Key Files Reference

**Design System Files** (ready to use):
- `lib/theme/app_colors.dart` - Color palette
- `lib/theme/app_text_styles.dart` - Typography system
- `lib/theme/app_dimensions.dart` - Spacing & sizing constants
- `lib/theme/app_theme.dart` - Integrated theme with Material 3

**Component Files** (ready to use):
- `lib/widgets/skeleton_loader.dart` - Loading states
- `lib/widgets/kasir_stats_card.dart` - Dashboard cards (needs update)
- `lib/widgets/kasir_transaction_card.dart` - Transaction cards (needs update)
- `lib/widgets/empty_state_widget.dart` - Empty states (needs update)

**Pages to Refactor** (in priority order):
1. login_page.dart - 30 mins
2. kasir_dashboard.dart - 120-150 mins (largest)
3. owner_dashboard.dart - 45 mins
4. kurir_dashboard.dart - 30 mins
5. Remaining widgets - 60 mins

---

## 📝 Notes

- **Kasir Dashboard is the bottleneck**: This file is 3,738 lines and touches every styling system. Refactoring it will improve the overall app by ~1.5 points
- **Follow the patterns**: Each replacement follows the same pattern. Use find-and-replace for efficiency
- **Test as you go**: After each page, test in emulator to ensure no UI breaks
- **Commit frequently**: After each major page, commit changes to git
- **Phase 1 is foundation**: These changes enable Phase 2 (animations) and Phase 3 (dark mode)


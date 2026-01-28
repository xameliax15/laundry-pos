/// Centralized spacing values untuk consistency
class AppSpacing {
  AppSpacing._();

  // Base spacing values
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Common combinations
  static const double paddingDefault = md;
  static const double marginDefault = lg;
  static const double gapDefault = md;
}

/// Centralized border radius values
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double circle = 100;
}

/// Centralized elevation values
class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
  static const double xl = 12;
  static const double xxl = 16;
}

/// Centralized icon sizes
class AppIconSize {
  AppIconSize._();

  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;
}

/// Centralized component sizes
class AppSizes {
  AppSizes._();

  // Button heights
  static const double buttonHeight = 48;
  static const double buttonSmallHeight = 40;
  static const double buttonLargeHeight = 56;

  // Input heights
  static const double inputHeight = 56;
  static const double inputSmallHeight = 44;

  // Card dimensions
  static const double cardMinHeight = 100;
  static const double cardMaxWidth = 500;

  // Sidebar widths
  static const double sidebarWidthDesktop = 280;
  static const double sidebarWidthTablet = 260;
  static const double sidebarWidthMobile = 240;

  // Bottom navigation
  static const double bottomNavHeight = 80;

  // App bar
  static const double appBarHeight = 56;

  // Divider
  static const double dividerThickness = 1;
}

/// Breakpoints untuk responsive design
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double ultraWide = 1440;
}

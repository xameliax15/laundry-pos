import 'package:flutter/material.dart';

/// Brand palette inspired by the provided "Trias Cleaners & Laundry" artwork.
///
/// Notes:
/// - Dominant: light sky blue background + stronger blue primary
/// - Accents: orange, green, purple (used in price panels / labels)
class AppColors {
  AppColors._();

  // Brand blues
  static const Color skyBlue = Color(0xFF63C7F2);
  static const Color brandBlue = Color(0xFF1E88D6);
  static const Color deepBlue = Color(0xFF0B5FA8);

  // Accents
  static const Color accentOrange = Color(0xFFF28C28);
  static const Color accentGreen = Color(0xFF2EAF63);
  static const Color accentPurple = Color(0xFF7E57C2);

  // Neutrals
  static const Color background = Color(0xFFF4FBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3EEF7);

  static const Color text = Color(0xFF1E2A32);
  static const Color textMuted = Color(0xFF6B7A88);
  
  // Gray scale
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray600 = Color(0xFF4B5563);
  
  // Semantic colors
  static const Color success = Color(0xFF2EAF63);
  static const Color warning = Color(0xFFF28C28);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF1E88D6);
}


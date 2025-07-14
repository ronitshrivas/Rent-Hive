import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2E7D9A);
  static const Color primaryLightColor = Color(0xFF4FC3F7);
  static const Color primaryDarkColor = Color(0xFF0277BD);
  
  // Secondary Colors
  static const Color secondaryColor = Color(0xFFFF6B35);
  static const Color secondaryLightColor = Color(0xFFFFAB91);
  static const Color secondaryDarkColor = Color(0xFFE64A19);
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF8FAFB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Border & Divider
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);
  
  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color shadowLightColor = Color(0x0D000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Chat Colors
  static const Color chatBubbleUser = Color(0xFF2E7D9A);
  static const Color chatBubbleOther = Color(0xFFF3F4F6);
  static const Color chatTextUser = Colors.white;
  static const Color chatTextOther = Color(0xFF1F2937);
  
  // Rating Colors
  static const Color ratingColor = Color(0xFFFFB800);
  static const Color ratingBackgroundColor = Color(0xFFE5E7EB);
  
  // Feature Colors
  static const Color availableColor = Color(0xFF10B981);
  static const Color bookedColor = Color(0xFFEF4444);
  static const Color pendingColor = Color(0xFFF59E0B);
}
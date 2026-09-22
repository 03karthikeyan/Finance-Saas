import 'package:flutter/material.dart';

class AppColors {
  // Brand & Accent - Professional Royal Blue & Sapphire
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1E40AF); // Deep Navy Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Bright Blue
  static const Color primarySoft = Color(0xFFEFF6FF); // Very Light Blue Tint

  // Secondary Accents
  static const Color accentIndigo = Color(0xFF4F46E5); // Indigo Accent
  static const Color accentCyan = Color(0xFF0284C7); // Sky Cyan
  static const Color accentPurple = Color(0xFF7C3AED);

  // Background & Surfaces - Clean Crisp White & Light Slate
  static const Color background = Color(0xFFF8FAFC); // Clean Light Slate Canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceCard = Color(0xFFF1F5F9); // Light Gray Elevated Card
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Pure White
  static const Color border = Color(0xFFE2E8F0); // Crisp Slate Border
  static const Color borderLight = Color(0xFFCBD5E1);

  // Financial Status Indicators
  static const Color success = Color(0xFF059669); // Emerald Green
  static const Color accentEmerald = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706); // Amber / Due / Pending
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626); // Crimson / Overdue / NPA
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB); // Royal Blue

  // Typography - High Contrast Crisp Dark
  static const Color textPrimary = Color(0xFF0F172A); // Deep Slate Navy
  static const Color textSecondary = Color(0xFF475569); // Medium Slate
  static const Color textMuted = Color(0xFF94A3B8); // Soft Cool Gray

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A), Color(0xFF172554)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

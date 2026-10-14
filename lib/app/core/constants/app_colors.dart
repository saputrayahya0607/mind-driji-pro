import 'package:flutter/material.dart';

/// Centralized Design System Colors for MIND DRIJI.
///
/// Theme: Calm, Intelligent, Personal Digital Wellness.
/// Primary: Teal (#00BFA5)
/// Secondary: Deep Navy (#102A43)
/// Background: Soft Gray (#F4F7FA)
/// Surface / Cards: White (#FFFFFF)
class AppColors {
  AppColors._();

  // ===========================================================================
  // CORE BRAND PALETTE (Stitch Design System: Calm, Intelligent, Digital Wellness)
  // ===========================================================================
  static const Color primary = Color(0xFF00BFA5); // Teal (#00BFA5)
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF00897B);
  static const Color primaryContainer = Color(0xFFDDF4F2); // Soft mint container (#DDF4F2)
  static const Color onPrimaryContainer = Color(0xFF004D40);

  // Exact Stitch Palette Tokens
  static const Color navy = Color(0xFF0B2030); // Deep Navy (#0B2030)
  static const Color teal = Color(0xFF00BFA5); // Teal (#00BFA5)
  static const Color cyan = Color(0xFF00D9EC); // Cyan (#00D9EC)
  static const Color softMint = Color(0xFFDDF4F2); // Soft Mint (#DDF4F2)

  static const Color secondary = Color(0xFF0B2030); // Deep Navy (#0B2030)
  static const Color secondaryLight = Color(0xFF172B3A); // Neutral Navy
  static const Color secondaryContainer = Color(0xFFE2E8F0);
  static const Color onSecondaryContainer = Color(0xFF0B2030);

  // ===========================================================================
  // BACKGROUNDS & SURFACES
  // ===========================================================================
  static const Color background = Color(0xFFF0F5F7); // Stitch Background Terang (#F0F5F7)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEAF1F4);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);

  // ===========================================================================
  // BORDERS & DIVIDERS
  // ===========================================================================
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocused = Color(0xFF00BFA5);
  static const Color divider = Color(0xFFE2E8F0);

  // ===========================================================================
  // TYPOGRAPHY / TEXT HIERARCHY
  // ===========================================================================
  static const Color textPrimary = Color(0xFF102A43); // Deep Navy
  static const Color textSecondary = Color(0xFF627D98); // Slate Gray
  static const Color textTertiary = Color(0xFF829AB1); // Muted Slate
  static const Color textDisabled = Color(0xFF9FB3C8);

  // ===========================================================================
  // SEMANTIC STATUS TOKENS (High-Contrast WCAG Compliant Pairings)
  // ===========================================================================
  // Success (Healthy usage, completed sessions, active monitoring)
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF14532D);
  static const Color successBorder = Color(0xFFBBF7D0);

  // Warning (Doomscrolling detected, high usage alert, eye fatigue warning)
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF78350F);
  static const Color warningBorder = Color(0xFFFDE68A);

  // Error (Failed sync, cancelled sessions, access denied, destructive actions)
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);
  static const Color errorBorder = Color(0xFFFECACA);

  // Info (Insights, neutral notifications, tips)
  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFEFF6FF);
  static const Color onInfoContainer = Color(0xFF1E3A8A);
  static const Color infoBorder = Color(0xFFBFDBFE);

  // ===========================================================================
  // NAVIGATION BAR TOKENS (Material 3 NavigationBar)
  // ===========================================================================
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActiveIndicator = Color(0xFFCCF2EC); // Soft calm teal pill
  static const Color navActiveIcon = Color(0xFF00695C); // Crisp deep teal
  static const Color navInactiveIcon = Color(0xFF627D98); // Muted navy-gray
  static const Color navActiveLabel = Color(0xFF102A43); // Deep navy
  static const Color navInactiveLabel = Color(0xFF627D98);
}

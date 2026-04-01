// lib/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === LOGIN SCREEN (kept as-is — already has nice blue gradient) ===
  static const Color loginBgTop = Color(0xFF1B7ACC); // gradient start
  static const Color loginBgMid = Color(0xFF1565A0); // gradient mid
  static const Color loginBgBottom = Color(0xFF0D4A85); // gradient end
  static const Color inputBg = Color(0xFFEAF1FB); // input field fill
  static const Color inputBgFocused = Color(0xFFFFFFFF);
  static const Color inputText = Color(0xFF1A3A5C);
  static const Color inputPlaceholder = Color(0xFF8AAFC8);
  static const Color primaryBlue = Color(0xFF1A6BAE); // button, accents
  static const Color primaryBlueDark = Color(0xFF145A96); // button press state
  static const Color loginButtonStart = Color(0xFF2186D8);
  static const Color loginButtonEnd = Color(0xFF1565A0);

  // === LIGHT THEME — GAME SELECTION & DASHBOARD ===
  // Light gray/white background (reverted)
  static const Color gsBackground = Color(0xFFF5F7FA);
  static const Color gsHeader = Color(0xFFFFFFFF);
  static const Color gsAccentBlue = Color(0xFF1565C0);

  // === GAME CARD COLORS (darker for better contrast) ===
  // 01 PM — Darker Red
  static const Color game01pmLight = Color(0xFFD32F2F);
  static const Color game01pmMid = Color(0xFFB71C1C);
  static const Color game01pmDark = Color(0xFF7F0000);

  // KL 3 PM — Darker Teal
  static const Color gameKl3pmLight = Color(0xFF00897B);
  static const Color gameKl3pmMid = Color(0xFF00695C);
  static const Color gameKl3pmDark = Color(0xFF004D40);

  // 06 PM — Darker Purple
  static const Color game06pmLight = Color(0xFF7B1FA2);
  static const Color game06pmMid = Color(0xFF4A148C);
  static const Color game06pmDark = Color(0xFF311B92);

  // 08 PM — Navy (lightened from too dark)
  static const Color game08pmLight = Color(0xFF2C3E50);
  static const Color game08pmMid = Color(0xFF34495E);
  static const Color game08pmDark = Color(0xFF5D6D7E);

  // === STATUS BADGE COLORS (darker for contrast) ===
  static const Color statusLive = Color(0xFFC62828);
  static const Color statusOpen = Color(0xFF00897B);
  static const Color statusSoon = Color(0xFF455A64);

  // === LIGHT THEME — DASHBOARD & SCREENS ===
  // Main background — light gray (reverted)
  static const Color dashboardBg = Color(0xFFF5F7FA);
  // Card/row surface — white (reverted)
  static const Color dashboardSurface = Color(0xFFFFFFFF);
  // Slightly off-white for alternating rows (reverted)
  static const Color dashboardSurface2 = Color(0xFFF8F9FA);
  // Borders — light gray (reverted)
  static const Color dashboardBorder = Color(0xFFE1E4E8);
  // Primary text — darker for better contrast
  static const Color dashboardTextPrim = Color(0xFF1A1A1A);
  // Secondary text — darker gray
  static const Color dashboardTextSub = Color(0xFF424242);
  // Dim text — medium gray
  static const Color dashboardTextDim = Color(0xFF616161);
  // Accent blue — darker
  static const Color dashboardBlue = Color(0xFF1565C0);
  // Logout/error red — darker
  static const Color dashboardLogout = Color(0xFFC62828);

  // Legacy colors (kept for reference)
  static const Color dashboardBgDark = Color(0xFF0D1117);
  static const Color dashboardSurfaceDark = Color(0xFF161B22);

  // === BOOKING SCREEN — Light background reverted ===
  static const Color bookingBg = Color(0xFFF5F7FA);
  static const Color bookingInputLine = Color(0xFF1565C0);
  static const Color bookingBtnBg = Color(0xFF00695C);
  static const Color bookingBtnText = Color(0xFFFFFFFF);
  static const Color bookingSaveBtn = Color(0xFF00695C);
  static const Color bookingFooterBg = Color(0xFFF0F0F0);

  // LSK type label colors (darker for contrast)
  static const Color lskAB = Color(0xFFC62828);
  static const Color lskAC = Color(0xFFEF6C00);
  static const Color lskBC = Color(0xFF37474F);
  static const Color lskA = Color(0xFFC62828);
  static const Color lskB = Color(0xFFC62828);
  static const Color lskC = Color(0xFF1565C0);
  static const Color lskBox = Color(0xFF1B5E20);
  static const Color lskSuper = Color(0xFF37474F);
  static const Color lskBoth = Color(0xFF4A148C);
}

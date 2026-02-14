// lib/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === LOGIN SCREEN ===
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

  // === GAME SELECTION SCREEN ===
  static const Color gsBackground = Color(0xFF0D1117); // dark bg
  static const Color gsHeader = Color(0xFF161B22); // header bg
  static const Color gsAccentBlue = Color(0xFF58A6FF); // header icon/badge

  // === GAME CARD COLORS (each game has its own gradient) ===
  // 01 PM — Red
  static const Color game01pmLight = Color(0xFFC0392B);
  static const Color game01pmMid = Color(0xFF922B21);
  static const Color game01pmDark = Color(0xFF7B241C);

  // KL 3 PM — Teal
  static const Color gameKl3pmLight = Color(0xFF0E7C7B);
  static const Color gameKl3pmMid = Color(0xFF085F63);
  static const Color gameKl3pmDark = Color(0xFF054A4B);

  // 06 PM — Purple
  static const Color game06pmLight = Color(0xFF8E44AD);
  static const Color game06pmMid = Color(0xFF6C3483);
  static const Color game06pmDark = Color(0xFF5B2C6F);

  // 08 PM — Near Black / Deep Navy
  static const Color game08pmLight = Color(0xFF1A1A2E);
  static const Color game08pmMid = Color(0xFF16213E);
  static const Color game08pmDark = Color(0xFF0F3460);

  // === STATUS BADGE COLORS ===
  static const Color statusLive = Color(0xFFFF6B6B);
  static const Color statusOpen = Color(0xFF4ECDC4);
  static const Color statusSoon = Color(0xFF778CA3);

  // === DASHBOARD SCREEN ===
  static const Color dashboardBg =
      Color(0xFF0D1117); // dark, matching game selection
  static const Color dashboardSurface = Color(0xFF161B22); // card/row surface
  static const Color dashboardSurface2 =
      Color(0xFF1C2330); // slightly lighter surface
  static const Color dashboardBorder = Color(0xFF21262D); // subtle borders
  static const Color dashboardTextPrim = Color(0xFFE6EDF3); // primary text
  static const Color dashboardTextSub =
      Color(0xFF8B949E); // secondary/muted text
  static const Color dashboardTextDim =
      Color(0xFF484F58); // section headers, very muted
  static const Color dashboardBlue =
      Color(0xFF58A6FF); // accent blue (matches gsAccentBlue)
  static const Color dashboardLogout = Color(0xFFDA3633); // logout button red

  // Legacy light dashboard colors (kept for reference, not used in new design)
  static const Color dashboardBgLight = Color(0xFFF5F7FA);
  static const Color dashboardHeader = Color(0xFFFFFFFF);
  static const Color dashboardText = Color(0xFF1A1A2E);

  // === BOOKING SCREEN — LSK type colors (match reference screenshots) ===
  static const Color bookingBg = Color(0xFFF5F7FA); // light bg
  static const Color bookingInputLine =
      Color(0xFF1976D2); // blue underline (active)
  static const Color bookingBtnBg = Color(0xFF0E7C7B); // teal action buttons
  static const Color bookingBtnText = Color(0xFFFFFFFF);
  static const Color bookingSaveBtn = Color(0xFF0E7C7B);
  static const Color bookingFooterBg = Color(0xFFF0F0F0);

  // LSK type label colors
  static const Color lskAB = Color(0xFFE53935); // red/pink
  static const Color lskAC = Color(0xFFFF8F00); // orange/amber
  static const Color lskBC = Color(0xFF212121); // near-black
  static const Color lskA = Color(0xFFE53935);
  static const Color lskB = Color(0xFFE53935);
  static const Color lskC = Color(0xFF1976D2); // blue
  static const Color lskBox = Color(0xFF2E7D32); // green
  static const Color lskSuper = Color(0xFF212121); // black
  static const Color lskBoth = Color(0xFF6A1B9A); // purple
}

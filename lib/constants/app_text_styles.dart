// lib/constants/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // === LOGIN SCREEN ===
  static const TextStyle loginAppName = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 4.0,
  );

  static const TextStyle loginTagline = TextStyle(
    color: Color(0xAAFFFFFF),
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 3.5,
  );

  static const TextStyle inputLabel = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
  );

  static const TextStyle inputText = TextStyle(
    color: AppColors.inputText,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle inputPlaceholder = TextStyle(
    color: AppColors.inputPlaceholder,
    fontSize: 15,
  );

  static const TextStyle loginButton = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.5,
  );

  static const TextStyle forgotPassword = TextStyle(
    color: Color(0xCCFFFFFF),
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle loginFooter = TextStyle(
    color: Color(0x55FFFFFF),
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  // === GAME SELECTION SCREEN ===
  static const TextStyle gsHeaderTitle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.5,
  );

  static const TextStyle gsHeaderSubtitle = TextStyle(
    color: Color(0x99FFFFFF),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle gsBadgeText = TextStyle(
    color: Color(0xFF58A6FF),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  // === GAME CARD ===
  static const TextStyle cardGameName = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.1,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: Color(0xCCFFFFFF),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cardTapToManage = TextStyle(
    color: Color(0xAAFFFFFF),
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle cardStatusBadge = TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  static const TextStyle cardGhostNumber = TextStyle(
    color: Color(0x26FFFFFF),
    fontSize: 64,
    fontWeight: FontWeight.w900,
    letterSpacing: -2,
  );

  // === DASHBOARD SCREEN (dark theme) ===
  static const TextStyle dashboardMenuLabel = TextStyle(
    color: AppColors.dashboardTextPrim,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle dashboardMenuSubtitle = TextStyle(
    color: AppColors.dashboardTextSub,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle dashboardSectionHeader = TextStyle(
    color: AppColors.dashboardTextDim,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
  );
}

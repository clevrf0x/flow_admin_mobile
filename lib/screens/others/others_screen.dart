// lib/screens/others/others_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';
import '../../models/dashboard_menu_item.dart';

class OthersScreen extends StatelessWidget {
  final String gameId;
  final String gameName;

  const OthersScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  Game? get _game {
    try {
      return mockGames.firstWhere((g) => g.id == gameId);
    } catch (_) {
      return null;
    }
  }

  Color _resolvedAccentColor(List<Color> headerColors) {
    final luminance = headerColors.first.computeLuminance();
    if (luminance < 0.08) return AppColors.gsAccentBlue;
    return headerColors.first;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final game = _game;
    final headerColors = game?.gradientColors ??
        [AppColors.primaryBlue, AppColors.primaryBlueDark];
    final accentColor = _resolvedAccentColor(headerColors);

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          _OthersHeader(
            gameName: gameName,
            gameId: gameId,
            headerColors: headerColors,
          ),
          Expanded(
            child: _OthersMenuList(
              accentColor: accentColor,
              gameId: gameId,
              gameName: gameName,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _OthersHeader extends StatelessWidget {
  final String gameName;
  final String gameId;
  final List<Color> headerColors;

  const _OthersHeader({
    required this.gameName,
    required this.gameId,
    required this.headerColors,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerColors.length >= 2
              ? [headerColors[0], headerColors.last]
              : [headerColors[0], headerColors[0]],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, statusBarHeight + 4, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ← Back to dashboard
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go(
                  '/dashboard/$gameId?gameName=${Uri.encodeComponent(gameName)}',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        gameName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Title — centered
            const Expanded(
              child: Text(
                'Others',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Spacer matching back button width so title stays centered
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU LIST
// ─────────────────────────────────────────────────────────────────────────────

class _OthersMenuList extends StatelessWidget {
  final Color accentColor;
  final String gameId;
  final String gameName;

  const _OthersMenuList({
    required this.accentColor,
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
      children: [
        // Single grouped card for all items
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dashboardBorder,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < othersMenuItems.length; i++)
                _OthersMenuRow(
                  item: othersMenuItems[i],
                  accentColor: accentColor,
                  isLast: i == othersMenuItems.length - 1,
                  gameId: gameId,
                  gameName: gameName,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OthersMenuRow extends StatelessWidget {
  final OthersMenuItem item;
  final Color accentColor;
  final bool isLast;
  final String gameId;
  final String gameName;

  const _OthersMenuRow({
    required this.item,
    required this.accentColor,
    required this.isLast,
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (item.id == 'settings') {
            context.go(
              '/dashboard/$gameId/settings?gameName=${Uri.encodeComponent(gameName)}',
            );
          } else if (item.id == 'daily_report_others') {
            context.go(
              '/dashboard/$gameId/daily-report?gameName=${Uri.encodeComponent(gameName)}',
            );
          } else {
            // TODO: Navigate to other item sub-screens
          }
        },
        highlightColor: accentColor.withOpacity(0.06),
        splashColor: accentColor.withOpacity(0.09),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: accentColor.withOpacity(0.13),
                      border: Border.all(
                        color: accentColor.withOpacity(0.22),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Label + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppColors.dashboardTextPrim,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: AppColors.dashboardTextSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.dashboardTextDim,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 68),
                color: AppColors.dashboardBorder,
              ),
          ],
        ),
      ),
    );
  }
}

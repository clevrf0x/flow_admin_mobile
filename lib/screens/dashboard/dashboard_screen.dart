// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/game.dart';
import '../../models/dashboard_menu_item.dart';

class DashboardScreen extends StatelessWidget {
  final String gameId;
  final String gameName;

  const DashboardScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  /// Find the matching game data so we can use its gradient in the header
  Game? get _game {
    try {
      return mockGames.firstWhere((g) => g.id == gameId);
    } catch (_) {
      return null;
    }
  }

  /// Returns the accent color used for icon boxes and ink effects in the menu.
  /// Falls back to [AppColors.gsAccentBlue] when the game's primary gradient
  /// color is too dark to be visible against the dark surface background.
  Color _resolvedAccentColor(List<Color> headerColors) {
    final c = headerColors.first;
    // Compute relative luminance — if too dark, use the app's standard accent
    final luminance = c.computeLuminance();
    if (luminance < 0.08) {
      return AppColors.gsAccentBlue; // bright blue — always visible
    }
    return c;
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

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          _DashboardHeader(
            gameName: gameName,
            game: game,
            headerColors: headerColors,
          ),
          Expanded(
            child: _DashboardMenuList(
              accentColor: _resolvedAccentColor(headerColors),
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

class _DashboardHeader extends StatelessWidget {
  final String gameName;
  final Game? game;
  final List<Color> headerColors;

  const _DashboardHeader({
    required this.gameName,
    required this.game,
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
      child: Stack(
        children: [
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(6, statusBarHeight + 4, 6, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ← Back button
                _HeaderBackButton(),
                // Game identity (icon + name + status)
                Expanded(
                  child: _HeaderGameInfo(game: game, gameName: gameName),
                ),
                // Logout button
                _HeaderLogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go('/game-selection'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                'Games',
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
    );
  }
}

class _HeaderGameInfo extends StatelessWidget {
  final Game? game;
  final String gameName;

  const _HeaderGameInfo({required this.game, required this.gameName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gameName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        if (game != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: game!.statusColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: game!.statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: game!.statusColor.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${game!.statusLabel}  ·  ${game!.subtitle}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HeaderLogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showLogoutDialog(context),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.22),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dashboardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: AppColors.dashboardTextPrim,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.dashboardTextSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.dashboardTextSub),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.dashboardLogout,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU LIST
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardMenuList extends StatelessWidget {
  final Color accentColor;
  final String gameId;
  final String gameName;

  const _DashboardMenuList({
    required this.accentColor,
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    // Group items by section while preserving order
    final Map<DashboardSection, List<DashboardMenuItem>> grouped = {};
    for (final item in dashboardMenuItems) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }

    final sections = [
      DashboardSection.operations,
      DashboardSection.reports,
      DashboardSection.others,
      DashboardSection.settings,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
      children: [
        for (final section in sections) ...[
          _SectionHeader(label: section.label),
          const SizedBox(height: 8),
          _SectionGroup(
            items: grouped[section] ?? [],
            accentColor: accentColor,
            gameId: gameId,
            gameName: gameName,
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.dashboardTextDim,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _SectionGroup extends StatelessWidget {
  final List<DashboardMenuItem> items;
  final Color accentColor;
  final String gameId;
  final String gameName;

  const _SectionGroup({
    required this.items,
    required this.accentColor,
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          for (int i = 0; i < items.length; i++)
            _MenuRow(
              item: items[i],
              accentColor: accentColor,
              isLast: i == items.length - 1,
              gameId: gameId,
              gameName: gameName,
            ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final DashboardMenuItem item;
  final Color accentColor;
  final bool isLast;
  final String gameId;
  final String gameName;

  const _MenuRow({
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
          if (item.id == 'change_game') {
            context.go('/game-selection');
            return;
          }
          if (item.id == 'others') {
            context.go(
              '/dashboard/$gameId/others?gameName=${Uri.encodeComponent(gameName)}',
            );
            return;
          }
          if (item.id == 'change_password') {
            context.go(
              '/dashboard/$gameId/change-password?gameName=${Uri.encodeComponent(gameName)}',
            );
            return;
          }
          if (item.id == 'booking') {
            context.go(
              '/dashboard/$gameId/booking?gameName=${Uri.encodeComponent(gameName)}',
            );
            return;
          }
          if (item.id == 'today') {
            context.go(
              '/dashboard/$gameId/today?gameName=${Uri.encodeComponent(gameName)}',
            );
            return;
          }
          // TODO: Navigate to item.route
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
                  // Icon box — accent-colored, tinted to match the game
                  _MenuIconBox(item: item, accentColor: accentColor),
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
                  // Chevron arrow
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.dashboardTextDim,
                    size: 20,
                  ),
                ],
              ),
            ),
            // Divider — indented, not shown on last item
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

class _MenuIconBox extends StatelessWidget {
  final DashboardMenuItem item;
  final Color accentColor;

  const _MenuIconBox({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

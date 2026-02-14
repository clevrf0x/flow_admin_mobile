// lib/screens/game_selection/game_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_text_styles.dart';
import '../../../../models/game.dart';
import '../../../../widgets/game_card.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Force dark status bar icons on dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.gsBackground,
      body: Column(
        children: [
          _GameSelectionHeader(),
          Expanded(child: _GameCardList()),
        ],
      ),
    );
  }
}

class _GameSelectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gsHeader, AppColors.gsBackground],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, statusBarHeight + 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App icon + title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Dashboard icon (grid)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.gsAccentBlue.withOpacity(0.15),
                          border: Border.all(
                            color: AppColors.gsAccentBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          color: AppColors.gsAccentBlue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'FLOW ADMIN',
                        style: AppTextStyles.gsHeaderTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Text(
                      'Select a game to manage',
                      style: AppTextStyles.gsHeaderSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            // Games count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.gsAccentBlue.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.gsAccentBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${mockGames.length} GAMES',
                style: AppTextStyles.gsBadgeText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCardList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dynamic card height calculation
    // Total available height minus gaps and padding
    const double horizontalPadding = 14.0;
    const double topPadding = 12.0;
    const double bottomPadding = 16.0;
    const double cardGap = 10.0;
    const int cardCount = 4;

    // Use LayoutBuilder to get actual available height
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final totalGaps = cardGap * (cardCount - 1);
        final totalPaddingVertical = topPadding + bottomPadding;
        final cardHeight =
            (availableHeight - totalGaps - totalPaddingVertical) / cardCount;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Column(
            children: [
              for (int i = 0; i < mockGames.length; i++) ...[
                if (i > 0) const SizedBox(height: cardGap),
                GameCard(
                  game: mockGames[i],
                  height: cardHeight,
                  onTap: () => _onGameTap(context, mockGames[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _onGameTap(BuildContext context, Game game) {
    context.go(
      '/dashboard/${game.id}?gameName=${Uri.encodeComponent(game.displayName)}',
    );
  }
}

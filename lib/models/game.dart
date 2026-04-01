// lib/models/game.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum GameStatus { live, open, soon }

class Game {
  final String id;
  final String displayName;
  final String subtitle;
  final GameStatus status;
  final List<Color> gradientColors;
  final Color headerColor;
  final Color statusColor;
  final String ghostNumber;

  const Game({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.status,
    required this.gradientColors,
    required this.headerColor,
    required this.statusColor,
    required this.ghostNumber,
  });

  String get statusLabel {
    switch (status) {
      case GameStatus.live:
        return 'LIVE';
      case GameStatus.open:
        return 'OPEN';
      case GameStatus.soon:
        return 'SOON';
    }
  }
}

/// Hardcoded mock data — will be replaced with API calls later
final List<Game> mockGames = [
  const Game(
    id: 'game_01pm',
    displayName: '01 PM',
    subtitle: 'Afternoon Draw',
    status: GameStatus.live,
    gradientColors: [
      AppColors.game01pmLight,
      AppColors.game01pmMid,
      AppColors.game01pmDark,
    ],
    headerColor: AppColors.game01pmMid,
    statusColor: AppColors.statusLive,
    ghostNumber: '01',
  ),
  const Game(
    id: 'game_kl3pm',
    displayName: 'KL 3 PM',
    subtitle: 'KL Special Draw',
    status: GameStatus.open,
    gradientColors: [
      AppColors.gameKl3pmLight,
      AppColors.gameKl3pmMid,
      AppColors.gameKl3pmDark,
    ],
    headerColor: AppColors.gameKl3pmMid,
    statusColor: AppColors.statusOpen,
    ghostNumber: '02',
  ),
  const Game(
    id: 'game_06pm',
    displayName: '06 PM',
    subtitle: 'Evening Draw',
    status: GameStatus.open,
    gradientColors: [
      AppColors.game06pmLight,
      AppColors.game06pmMid,
      AppColors.game06pmDark,
    ],
    headerColor: AppColors.game06pmMid,
    statusColor: Color(0xFF9B59B6),
    ghostNumber: '03',
  ),
  const Game(
    id: 'game_08pm',
    displayName: '08 PM',
    subtitle: 'Night Draw',
    status: GameStatus.soon,
    gradientColors: [
      AppColors.game08pmLight,
      AppColors.game08pmMid,
      AppColors.game08pmDark,
    ],
    headerColor: AppColors.game08pmMid,
    statusColor: AppColors.statusSoon,
    ghostNumber: '04',
  ),
];

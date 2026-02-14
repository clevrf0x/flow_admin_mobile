// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_text_styles.dart';

class DashboardScreen extends StatelessWidget {
  final String gameId;
  final String gameName;

  const DashboardScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Column(
        children: [
          _DashboardHeader(gameName: gameName),
          Expanded(
            child: _DashboardBody(gameName: gameName),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String gameName;

  const _DashboardHeader({required this.gameName});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.dashboardHeader,
            AppColors.dashboardBg,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, statusBarHeight + 4, 16, 8),
        child: Row(
          children: [
            // Back button
            TextButton.icon(
              onPressed: () => context.go('/game-selection'),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.dashboardBlue,
                size: 22,
              ),
              label: const Text(
                'Games',
                style: AppTextStyles.dashboardBackButton,
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Game name title
            Expanded(
              child: Text(
                gameName,
                style: const TextStyle(
                  color: AppColors.dashboardText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Spacer to balance back button
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final String gameName;

  const _DashboardBody({required this.gameName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dashboardBlue.withOpacity(0.1),
              border: Border.all(
                color: AppColors.dashboardBlue.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.dashboardBlue,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            gameName,
            style: AppTextStyles.dashboardGameName,
          ),
          const SizedBox(height: 6),
          const Text(
            'DASHBOARD',
            style: AppTextStyles.dashboardLabel,
          ),
          const SizedBox(height: 14),
          const Text(
            'Content coming soon',
            style: AppTextStyles.dashboardPlaceholder,
          ),
        ],
      ),
    );
  }
}

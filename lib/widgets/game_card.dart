// lib/widgets/game_card.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';
import '../../models/game.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final double height;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.game,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: game.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: game.gradientColors.first.withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Diagonal stripe texture overlay
            _buildStripeTexture(),
            // Ghost number (top-right)
            _buildGhostNumber(),
            // Card content
            _buildCardContent(),
            // Bottom accent line
            _buildBottomAccent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStripeTexture() {
    return Positioned.fill(child: CustomPaint(painter: _StripePainter()));
  }

  Widget _buildGhostNumber() {
    return Positioned(
      top: -8,
      right: 16,
      child: Text(game.ghostNumber, style: AppTextStyles.cardGhostNumber),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge (top-left)
          _buildStatusBadge(),
          const Spacer(),
          // Icon + game name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconBox(),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(game.displayName, style: AppTextStyles.cardGameName),
                  const SizedBox(height: 2),
                  Text(game.subtitle, style: AppTextStyles.cardSubtitle),
                ],
              ),
            ],
          ),
          const Spacer(),
          // "Tap to manage" footer
          _buildTapToManage(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: game.statusColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: game.statusColor,
              boxShadow: [
                BoxShadow(
                  color: game.statusColor.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(game.statusLabel, style: AppTextStyles.cardStatusBadge),
        ],
      ),
    );
  }

  Widget _buildIconBox() {
    // Pick different ticket icons per game for variety
    IconData icon;
    switch (game.id) {
      case 'game_01pm':
        icon = Icons.confirmation_number_outlined;
        break;
      case 'game_kl3pm':
        icon = Icons.local_activity_outlined;
        break;
      case 'game_06pm':
        icon = Icons.confirmation_number_rounded;
        break;
      case 'game_08pm':
        icon = Icons.star_outline_rounded;
        break;
      default:
        icon = Icons.confirmation_number_outlined;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }

  Widget _buildTapToManage() {
    return Row(
      children: [
        Text('Tap to manage', style: AppTextStyles.cardTapToManage),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xAAFFFFFF),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildBottomAccent() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for diagonal stripe texture overlay
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    const double stripeSpacing = 36.0;
    const double angle = 20.0 * (math.pi / 180.0);
    final double diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);

    for (double x = -diagonal; x < diagonal; x += stripeSpacing) {
      canvas.drawLine(Offset(x, -diagonal), Offset(x, diagonal), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}

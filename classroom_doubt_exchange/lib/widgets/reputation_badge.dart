// lib/widgets/reputation_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReputationBadge extends StatelessWidget {
  final int points;
  final bool showTier;
  final bool large;

  const ReputationBadge({
    super.key,
    required this.points,
    this.showTier = false,
    this.large = false,
  });

  String get _tier {
    if (points >= 500) return 'Expert';
    if (points >= 200) return 'Advanced';
    if (points >= 50) return 'Contributor';
    if (points >= 10) return 'Learner';
    return 'Newcomer';
  }

  Color get _tierColor {
    if (points >= 500) return const Color(0xFFF59E0B); // Gold
    if (points >= 200) return const Color(0xFF818CF8); // Purple
    if (points >= 50) return AppColors.accent;          // Green
    if (points >= 10) return AppColors.primaryLight;   // Blue
    return AppColors.textMuted;                         // Grey
  }

  IconData get _tierIcon {
    if (points >= 500) return Icons.workspace_premium_rounded;
    if (points >= 200) return Icons.star_rounded;
    if (points >= 50) return Icons.local_fire_department_rounded;
    if (points >= 10) return Icons.school_rounded;
    return Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (large) return _buildLarge();
    return _buildCompact();
  }

  Widget _buildCompact() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_tierIcon, size: 13, color: _tierColor),
        const SizedBox(width: 3),
        Text(
          '$points pts',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _tierColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLarge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _tierColor.withOpacity(0.15),
            _tierColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tierColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_tierIcon, size: 28, color: _tierColor),
          const SizedBox(height: 4),
          Text(
            '$points',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _tierColor,
            ),
          ),
          Text(
            'points',
            style: TextStyle(fontSize: 11, color: _tierColor.withOpacity(0.7)),
          ),
          if (showTier) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _tierColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tier,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _tierColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

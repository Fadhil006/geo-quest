import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/datetime_utils.dart';

/// Animated linear progress bar for per-challenge time limit
class ChallengeTimerBar extends StatelessWidget {
  final double progress;
  final Duration remaining;
  final bool isExpired;

  const ChallengeTimerBar({
    super.key,
    required this.progress,
    required this.remaining,
    required this.isExpired,
  });

  Color get _color {
    if (isExpired) return AppColors.error;
    if (progress > 0.75) return AppColors.error;
    if (progress > 0.5) return AppColors.warning;
    return AppColors.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timer_rounded, color: _color, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Time Left',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              isExpired ? 'TIME UP!' : DateTimeUtils.formatMinSec(remaining),
              style: GoogleFonts.orbitron(
                color: _color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: (1.0 - progress).clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_color, _color.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


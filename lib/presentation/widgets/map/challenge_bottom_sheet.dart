import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../domain/entities/challenge.dart';
import 'category_chip.dart';

/// Bottom sheet that appears when a challenge is unlocked via GPS
class ChallengeBottomSheet extends ConsumerWidget {
  final Challenge challenge;

  const ChallengeBottomSheet({super.key, required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unlocked badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.neonGreen.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open_rounded,
                          color: AppColors.neonGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.challengeUnlocked,
                        style: GoogleFonts.inter(
                          color: AppColors.neonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn()
                    .shimmer(duration: 1500.ms, color: AppColors.neonGreen.withOpacity(0.3)),

                const SizedBox(height: 16),

                // Title
                Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 8),

                // Category & Difficulty
                Row(
                  children: [
                    CategoryChip(category: challenge.category),
                    const SizedBox(width: 8),
                    _DifficultyBadge(difficulty: challenge.difficulty),
                    const Spacer(),
                    // Points
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${challenge.points} pts',
                        style: GoogleFonts.orbitron(
                          color: AppColors.neonCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),
                Text(
                  challenge.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),

                // Start Challenge Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/challenge');
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      'START CHALLENGE',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final ChallengeDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  Color get _color {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.difficultyEasy;
      case ChallengeDifficulty.medium:
        return AppColors.difficultyMedium;
      case ChallengeDifficulty.hard:
        return AppColors.difficultyHard;
      case ChallengeDifficulty.expert:
        return AppColors.difficultyExpert;
    }
  }

  String get _label {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.expert:
        return 'Expert';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: GoogleFonts.inter(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_app_bar.dart';
import '../../../domain/entities/leaderboard_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentTeam = ref.watch(currentTeamProvider);

    return GradientScaffold(
      appBar: const NeonAppBar(title: 'LEADERBOARD'),
      body: SafeArea(
        child: leaderboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.leaderboard_rounded,
                        color: AppColors.textMuted, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.noTeamsYet,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // ── Top 3 Podium ──
                if (entries.length >= 3)
                  _buildPodium(context, entries.take(3).toList()),

                const SizedBox(height: 8),

                // ── Full List ──
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isCurrentTeam =
                          currentTeam?.id == entry.teamId;

                      return _LeaderboardRow(
                        entry: entry,
                        isCurrentTeam: isCurrentTeam,
                      )
                          .animate()
                          .fadeIn(delay: (100 * index).ms)
                          .slideX(begin: 0.2);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> top3) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(
            child: _PodiumCard(
              entry: top3[1],
              height: 110,
              color: AppColors.textSecondary,
              icon: '🥈',
            ),
          ),
          const SizedBox(width: 8),
          // 1st place
          Expanded(
            child: _PodiumCard(
              entry: top3[0],
              height: 140,
              color: AppColors.neonYellow,
              icon: '🏆',
            ),
          ),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(
            child: _PodiumCard(
              entry: top3[2],
              height: 90,
              color: AppColors.neonOrange,
              icon: '🥉',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final String icon;

  const _PodiumCard({
    required this.entry,
    required this.height,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      borderGradientColors: [
        color.withOpacity(0.5),
        color.withOpacity(0.1),
        color.withOpacity(0.3),
      ],
      child: SizedBox(
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              entry.teamName,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${entry.score}',
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'pts',
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentTeam;

  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentTeam,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(entry.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentTeam
            ? AppColors.neonCyan.withOpacity(0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTeam
              ? AppColors.neonCyan.withOpacity(0.4)
              : AppColors.glassBorder,
          width: isCurrentTeam ? 1.5 : 0.5,
        ),
        boxShadow: isCurrentTeam
            ? [
                BoxShadow(
                  color: AppColors.neonCyan.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withOpacity(0.15),
              border: Border.all(color: rankColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: GoogleFonts.orbitron(
                  color: rankColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Team info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.teamName,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentTeam)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOU',
                          style: GoogleFonts.inter(
                            color: AppColors.neonCyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.completedCount} challenges completed',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: GoogleFonts.orbitron(
                  color: AppColors.neonCyan,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'pts',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.neonYellow;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return AppColors.neonOrange;
      default:
        return AppColors.textMuted;
    }
  }
}


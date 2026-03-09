import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_app_bar.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../domain/entities/challenge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/timer_provider.dart';
import '../../widgets/home/countdown_widget.dart';
import '../../widgets/home/stat_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _difficultyLabel(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy:
        return AppStrings.easy;
      case ChallengeDifficulty.medium:
        return AppStrings.medium;
      case ChallengeDifficulty.hard:
        return AppStrings.hard;
      case ChallengeDifficulty.expert:
        return AppStrings.expert;
    }
  }

  Color _difficultyColor(ChallengeDifficulty d) {
    switch (d) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(currentTeamProvider);
    final sessionAsync = ref.watch(sessionStreamProvider);
    final timer = ref.watch(timerProvider);

    return GradientScaffold(
      appBar: NeonAppBar(
        title: AppStrings.dashboard,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (session) {
            if (session == null) {
              return _buildStartView(context, ref, team?.teamName ?? 'Team');
            }
            return _buildDashboard(context, ref, session, timer);
          },
        ),
      ),
    );
  }

  Widget _buildStartView(BuildContext context, WidgetRef ref, String teamName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.explore_rounded,
                  size: 60, color: Colors.white),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 32),
            Text(
              'Welcome, $teamName!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            Text(
              'Ready to explore the campus?\nYou have 2 hours to score as high as possible!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 48),
            NeonButton(
              text: AppStrings.startQuest,
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  ref.read(sessionProvider.notifier).startSession(),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
      BuildContext context, WidgetRef ref, dynamic session, TimerState timer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Countdown Timer ──
          Center(
            child: CountdownWidget(
              remaining: timer.remaining,
              progress: timer.progress,
              isExpired: timer.isExpired,
            ),
          ).animate().fadeIn().scale(delay: 100.ms),

          const SizedBox(height: 28),

          // ── Stat Cards Grid ──
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.stars_rounded,
                  label: AppStrings.currentScore,
                  value: '${session.score}',
                  color: AppColors.neonCyan,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.speed_rounded,
                  label: AppStrings.difficulty,
                  value: _difficultyLabel(session.currentDifficulty),
                  color: _difficultyColor(session.currentDifficulty),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.flag_rounded,
                  label: 'Completed',
                  value: '${session.challengesCompleted}',
                  color: AppColors.neonGreen,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Accuracy',
                  value: '${(session.accuracyRate * 100).toInt()}%',
                  color: AppColors.neonPurple,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Action Buttons ──
          NeonButton(
            text: AppStrings.viewMap,
            icon: Icons.map_rounded,
            onPressed: () => context.push('/map'),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          NeonOutlineButton(
            text: AppStrings.leaderboard,
            icon: Icons.leaderboard_rounded,
            color: AppColors.neonPurple,
            onPressed: () => context.push('/leaderboard'),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          NeonOutlineButton(
            text: 'TEST MODE',
            icon: Icons.science_rounded,
            color: AppColors.neonOrange,
            onPressed: () => context.push('/test'),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

          // ── Time expired overlay ──
          if (timer.isExpired)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer_off_rounded,
                      color: AppColors.error, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.timeExpired,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your score has been locked. Check the leaderboard!',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

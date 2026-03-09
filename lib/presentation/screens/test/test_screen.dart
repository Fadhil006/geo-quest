import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_app_bar.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';
import 'rapid_fire_screen.dart';

// ── Difficulty tab definitions ──
enum TestTab { easy, medium, hard, rapidFire }

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TestTab _currentTab = TestTab.easy;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = TestTab.values[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ChallengeDifficulty _difficultyForTab(TestTab tab) {
    switch (tab) {
      case TestTab.easy:
        return ChallengeDifficulty.easy;
      case TestTab.medium:
        return ChallengeDifficulty.medium;
      case TestTab.hard:
        return ChallengeDifficulty.hard;
      case TestTab.rapidFire:
        return ChallengeDifficulty.expert;
    }
  }

  String _tabLabel(TestTab tab) {
    switch (tab) {
      case TestTab.easy:
        return 'EASY';
      case TestTab.medium:
        return 'MEDIUM';
      case TestTab.hard:
        return 'HARD';
      case TestTab.rapidFire:
        return '⚡ RAPID';
    }
  }

  Color _tabColor(TestTab tab) {
    switch (tab) {
      case TestTab.easy:
        return AppColors.difficultyEasy;
      case TestTab.medium:
        return AppColors.difficultyMedium;
      case TestTab.hard:
        return AppColors.difficultyHard;
      case TestTab.rapidFire:
        return AppColors.difficultyExpert;
    }
  }

  String _pointsLabel(TestTab tab) {
    switch (tab) {
      case TestTab.easy:
        return '5 pts';
      case TestTab.medium:
        return '10 pts';
      case TestTab.hard:
        return '20 pts';
      case TestTab.rapidFire:
        return '5-20 pts';
    }
  }

  String _timeLabel(TestTab tab) {
    switch (tab) {
      case TestTab.easy:
        return '45s';
      case TestTab.medium:
        return '2 min';
      case TestTab.hard:
        return '2 min';
      case TestTab.rapidFire:
        return '30s each';
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);

    return GradientScaffold(
      appBar: const NeonAppBar(title: 'TEST MODE'),
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab bar ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _tabColor(_currentTab).withValues(alpha: 0.2),
                  border: Border.all(
                    color: _tabColor(_currentTab).withValues(alpha: 0.6),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                tabs: TestTab.values.map((tab) {
                  final isActive = _currentTab == tab;
                  return Tab(
                    child: Text(
                      _tabLabel(tab),
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isActive ? _tabColor(tab) : AppColors.textMuted,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn().slideY(begin: -0.2),

            const SizedBox(height: 12),

            // ── Info card for current tab ──
            _buildInfoCard(),

            const SizedBox(height: 12),

            // ── Questions list ──
            Expanded(
              child: challengesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.neonCyan),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
                data: (challenges) {
                  return TabBarView(
                    controller: _tabController,
                    children: TestTab.values.map((tab) {
                      if (tab == TestTab.rapidFire) {
                        return _buildRapidFirePanel(challenges);
                      }
                      final filtered = challenges
                          .where((c) => c.difficulty == _difficultyForTab(tab))
                          .take(3)
                          .toList();
                      return _buildQuestionList(filtered, tab);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final color = _tabColor(_currentTab);
    final isRapid = _currentTab == TestTab.rapidFire;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isRapid ? Icons.flash_on_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRapid
                  ? '⚡ RAPID FIRE — Answer as many as you can! Shiny questions spawn randomly with BONUS!'
                  : '${_tabLabel(_currentTab)} mode • ${_timeLabel(_currentTab)} time limit',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildQuestionList(List<Challenge> challenges, TestTab tab) {
    if (challenges.isEmpty) {
      return Center(
        child: Text(
          'No ${_tabLabel(tab)} questions available',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final color = _tabColor(tab);

        return _QuestionCard(
          challenge: challenge,
          index: index,
          color: color,
          onTap: () => _openChallenge(challenge),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildRapidFirePanel(List<Challenge> allChallenges) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Rapid fire description card
          GlassmorphicContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            borderGradientColors: [
              AppColors.difficultyExpert.withValues(alpha: 0.5),
              AppColors.neonPink.withValues(alpha: 0.2),
              AppColors.difficultyExpert.withValues(alpha: 0.3),
            ],
            child: Column(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'RAPID FIRE MODE',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.difficultyExpert,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Questions fly at you every 30 seconds!\n'
                  '20 questions • 10 minute time limit\n'
                  'Random difficulty • Bonus multipliers\n'
                  '✨ Shiny questions = 2× points!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip('⏱️', '30s/Q', AppColors.neonCyan),
                    const SizedBox(width: 12),
                    _statChip('🔥', '20 Qs', AppColors.neonOrange),
                    const SizedBox(width: 12),
                    _statChip('✨', '2× bonus', AppColors.neonYellow),
                  ],
                ),
                const SizedBox(height: 20),
                NeonButton(
                  text: 'START RAPID FIRE',
                  icon: Icons.flash_on_rounded,
                  color: AppColors.difficultyExpert,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RapidFireScreen(
                          challenges: allChallenges,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
              .animate()
              .scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$emoji $label',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openChallenge(Challenge challenge) {
    final session = ref.read(sessionStreamProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a session first from the Dashboard!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(activeChallengeProvider.notifier).setChallenge(challenge);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _TestChallengeScreen()),
    );
  }
}

// ═══════════════════════════════════════════════════
// Question Card Widget
// ═══════════════════════════════════════════════════
class _QuestionCard extends StatelessWidget {
  final Challenge challenge;
  final int index;
  final Color color;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.challenge,
    required this.index,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.orbitron(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to attempt',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Test Challenge Screen (answer individual questions)
// ═══════════════════════════════════════════════════
class _TestChallengeScreen extends ConsumerStatefulWidget {
  const _TestChallengeScreen();

  @override
  ConsumerState<_TestChallengeScreen> createState() =>
      _TestChallengeScreenState();
}

class _TestChallengeScreenState extends ConsumerState<_TestChallengeScreen> {
  String? _selectedOption;
  bool _showResult = false;
  bool _isSubmitting = false;
  int? _bonusPoints;

  @override
  Widget build(BuildContext context) {
    final challenge = ref.watch(activeChallengeProvider);
    if (challenge == null) {
      return const GradientScaffold(
        body: Center(child: Text('No challenge selected')),
      );
    }

    // Check if this is a bonus question (random 20% chance)
    _bonusPoints ??= _rollBonusPoints(challenge.id);

    final totalPoints = challenge.points + (_bonusPoints ?? 0);

    return GradientScaffold(
      appBar: NeonAppBar(
        title: _bonusPoints! > 0 ? '✨ BONUS CHALLENGE' : 'CHALLENGE',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Bonus indicator ──
              if (_bonusPoints! > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.neonYellow.withValues(alpha: 0.15),
                        AppColors.neonOrange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.neonYellow.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'BONUS: +$_bonusPoints extra points!',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonYellow,
                        ),
                      ),
                    ],
                  ),
                ).animate().shimmer(
                      duration: 2000.ms,
                      color: AppColors.neonYellow.withValues(alpha: 0.3),
                    ),

              // ── Points & Time info ──
              Row(
                children: [
                  _infoChip(Icons.stars_rounded, '$totalPoints pts',
                      AppColors.neonCyan),
                  const SizedBox(width: 10),
                  _infoChip(Icons.timer_rounded,
                      '${challenge.timeLimitSeconds}s', AppColors.neonOrange),
                  const SizedBox(width: 10),
                  _infoChip(
                    Icons.trending_up_rounded,
                    challenge.difficulty.name.toUpperCase(),
                    _diffColor(challenge.difficulty),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Question ──
              GlassmorphicContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 18,
                child: Text(
                  challenge.question,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Options ──
              if (challenge.options != null)
                ...challenge.options!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedOption == option;

                  return GestureDetector(
                    onTap: _showResult
                        ? null
                        : () => setState(() => _selectedOption = option),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.neonCyan.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.neonCyan
                              : AppColors.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.neonCyan
                                  : AppColors.surfaceLight,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.neonCyan
                                    : AppColors.textMuted,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: GoogleFonts.inter(
                                  color: isSelected
                                      ? AppColors.background
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (100 + index * 80).ms);
                }),

              const SizedBox(height: 24),

              // ── Result ──
              if (_showResult) _buildResult(challenge),

              // ── Submit ──
              if (!_showResult)
                NeonButton(
                  text: 'SUBMIT',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: () => _submit(challenge),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _rollBonusPoints(String challengeId) {
    // Deterministic "random" based on challenge id hash — ~20% chance
    final hash = challengeId.hashCode;
    if (hash % 5 == 0) {
      // Bonus: 3, 5, or 8 extra points
      final bonusTier = (hash ~/ 5) % 3;
      return [3, 5, 8][bonusTier];
    }
    return 0;
  }

  Color _diffColor(ChallengeDifficulty d) {
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

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(Challenge challenge) async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final session = ref.read(sessionStreamProvider).valueOrNull;
    if (session == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    await ref.read(submissionProvider.notifier).submitAnswer(
          sessionId: session.id,
          challengeId: challenge.id,
          answer: _selectedOption!,
        );

    // If there's a bonus, add it separately for correct answers
    final submission = ref.read(submissionProvider);
    if (submission.result?.isCorrect == true && (_bonusPoints ?? 0) > 0) {
      // Add bonus points to session
      final currentSession = ref.read(sessionStreamProvider).valueOrNull;
      if (currentSession != null) {
        ref.read(sessionProvider.notifier).addBonusPoints(_bonusPoints!);
      }
    }

    // Update leaderboard
    _updateLeaderboard();

    setState(() {
      _isSubmitting = false;
      _showResult = true;
    });
  }

  void _updateLeaderboard() {
    final session = ref.read(sessionStreamProvider).valueOrNull;
    final team = ref.read(currentTeamProvider);
    if (session == null || team == null) return;

    ref.read(leaderboardUpdaterProvider.notifier).updateScore(
          teamId: team.id,
          teamName: team.teamName,
          score: session.score,
          completedCount: session.correctAnswers,
        );
  }

  Widget _buildResult(Challenge challenge) {
    final submission = ref.watch(submissionProvider);
    final isCorrect = submission.result?.isCorrect ?? false;
    final color = isCorrect ? AppColors.neonGreen : AppColors.error;
    final pointsAwarded = (submission.result?.pointsAwarded ?? 0) +
        (isCorrect ? (_bonusPoints ?? 0) : 0);

    return NeonGlassContainer(
      glowColor: color,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isCorrect ? '🎉 CORRECT!' : '❌ INCORRECT',
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+$pointsAwarded points',
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_bonusPoints! > 0 && isCorrect) ...[
            const SizedBox(height: 4),
            Text(
              '(includes ✨ +$_bonusPoints bonus!)',
              style: GoogleFonts.inter(
                color: AppColors.neonYellow,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              submission.result?.feedback ?? '',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          NeonButton(
            text: 'CONTINUE',
            icon: Icons.arrow_forward_rounded,
            color: AppColors.neonCyan,
            onPressed: () {
              ref.read(submissionProvider.notifier).reset();
              ref.read(activeChallengeProvider.notifier).clearChallenge();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut);
  }
}

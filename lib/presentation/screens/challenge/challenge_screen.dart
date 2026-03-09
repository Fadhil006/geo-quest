import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_app_bar.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/category_chip.dart';
import '../../widgets/challenge/challenge_timer_bar.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  final _answerController = TextEditingController();
  String? _selectedOption;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    // Start challenge timer
    final challenge = ref.read(activeChallengeProvider);
    if (challenge != null) {
      ref
          .read(challengeTimerProvider.notifier)
          .startChallengeTimer(challenge.timeLimitSeconds);
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit() {
    final challenge = ref.read(activeChallengeProvider);
    final session = ref.read(sessionStreamProvider).valueOrNull;
    if (challenge == null || session == null) return;

    final answer = challenge.type == ChallengeType.multipleChoice
        ? _selectedOption ?? ''
        : _answerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
      return;
    }

    ref.read(submissionProvider.notifier).submitAnswer(
          sessionId: session.id,
          challengeId: challenge.id,
          answer: answer,
        );

    // Update leaderboard after submission
    Future.delayed(const Duration(milliseconds: 600), () {
      final updatedSession = ref.read(sessionStreamProvider).valueOrNull;
      final team = ref.read(currentTeamProvider);
      if (updatedSession != null && team != null) {
        ref.read(leaderboardUpdaterProvider.notifier).updateScore(
              teamId: team.id,
              teamName: team.teamName,
              score: updatedSession.score,
              completedCount: updatedSession.correctAnswers,
            );
      }
    });

    ref.read(challengeTimerProvider.notifier).stopTimer();
    setState(() => _showResult = true);
  }

  void _skip() {
    final challenge = ref.read(activeChallengeProvider);
    final session = ref.read(sessionStreamProvider).valueOrNull;
    if (challenge == null || session == null) return;

    ref.read(submissionProvider.notifier).skipChallenge(
          sessionId: session.id,
          challengeId: challenge.id,
        );

    ref.read(challengeTimerProvider.notifier).stopTimer();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ref.watch(activeChallengeProvider);
    final challengeTimer = ref.watch(challengeTimerProvider);
    final submission = ref.watch(submissionProvider);

    if (challenge == null) {
      return const GradientScaffold(
        body: Center(child: Text('No active challenge')),
      );
    }

    // Auto-submit when timer expires
    if (challengeTimer.isExpired && !_showResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _skip();
      });
    }

    return GradientScaffold(
      appBar: const NeonAppBar(title: 'CHALLENGE'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timer Bar ──
              ChallengeTimerBar(
                progress: challengeTimer.progress,
                remaining: challengeTimer.remaining,
                isExpired: challengeTimer.isExpired,
              ).animate().fadeIn(),

              const SizedBox(height: 20),

              // ── Challenge Header ──
              GlassmorphicContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CategoryChip(category: challenge.category),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // ── Question ──
              GlassmorphicContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.question,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Answer input
                    if (challenge.type == ChallengeType.textInput)
                      TextFormField(
                        controller: _answerController,
                        enabled: !_showResult,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Type your answer...',
                          prefixIcon: Icon(Icons.edit_rounded,
                              color: AppColors.neonCyan),
                        ),
                      ),

                    // Multiple choice options
                    if (challenge.type == ChallengeType.multipleChoice &&
                        challenge.options != null)
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
                                  ? AppColors.neonCyan.withOpacity(0.15)
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
                        ).animate().fadeIn(delay: (200 + index * 100).ms);
                      }),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Result Display ──
              if (_showResult && submission.status == SubmissionStatus.success)
                _buildResultCard(context, submission),

              if (!_showResult) ...[
                // Submit button
                NeonButton(
                  text: AppStrings.submit,
                  icon: Icons.send_rounded,
                  onPressed: _submit,
                  isLoading: submission.status == SubmissionStatus.submitting,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 12),

                // Skip button
                Center(
                  child: TextButton.icon(
                    onPressed: _skip,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: AppColors.textMuted),
                    label: Text(
                      AppStrings.skip,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SubmissionState submission) {
    final isCorrect = submission.result?.isCorrect ?? false;
    final color = isCorrect ? AppColors.neonGreen : AppColors.error;

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
            isCorrect ? AppStrings.correct : AppStrings.incorrect,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: color),
          ),
          const SizedBox(height: 16),
          NeonButton(
            text: 'Continue',
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

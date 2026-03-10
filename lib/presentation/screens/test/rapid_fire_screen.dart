import 'dart:async';
import 'dart:math';
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
import '../../../data/datasources/question_loader.dart';
import '../../providers/session_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/auth_provider.dart';

/// Rapid Fire Mode — 30s per question, up to 10 min total.
/// "Shiny" questions randomly appear with 2× point multiplier.
class RapidFireScreen extends ConsumerStatefulWidget {
  final List<Challenge> challenges;

  const RapidFireScreen({super.key, required this.challenges});

  @override
  ConsumerState<RapidFireScreen> createState() => _RapidFireScreenState();
}

class _RapidFireScreenState extends ConsumerState<RapidFireScreen> {
  final _random = Random();

  // ── State ──
  late List<Challenge> _shuffled;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _showResult = false;
  bool _isFinished = false;

  // ── Config ──
  static const int _maxQuestions = 20;

  // ── Scoring ──
  int _totalScore = 0;
  int _correctCount = 0;
  int _totalAnswered = 0;
  final List<_RapidResult> _results = [];

  // ── Timers ──
  Timer? _questionTimer;
  Timer? _globalTimer;
  int _questionSecondsLeft = 30;
  int _globalSecondsLeft = 600; // 10 min
  bool _isShiny = false;

  @override
  void initState() {
    super.initState();
    _shuffled = List<Challenge>.from(widget.challenges)..shuffle(_random);
    _startGlobalTimer();
    _startQuestionTimer();
    _rollShiny();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _globalTimer?.cancel();
    super.dispose();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _globalSecondsLeft--;
        if (_globalSecondsLeft <= 0) {
          _finishGame();
        }
      });
    });
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionSecondsLeft = 30;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _questionSecondsLeft--;
        if (_questionSecondsLeft <= 0) {
          _timeOut();
        }
      });
    });
  }

  void _rollShiny() {
    // ~15% chance of "shiny" — 2× points
    _isShiny = _random.nextDouble() < 0.15;
  }

  void _timeOut() {
    _questionTimer?.cancel();
    _results.add(_RapidResult(
      question: _currentChallenge.question,
      correct: false,
      points: 0,
      isShiny: _isShiny,
    ));
    _totalAnswered++;
    setState(() => _showResult = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _nextQuestion();
    });
  }

  Challenge get _currentChallenge =>
      _shuffled[_currentIndex % _shuffled.length];

  int get _questionPoints {
    final base = _currentChallenge.points;
    return _isShiny ? base * 2 : base;
  }

  void _submit() {
    if (_selectedOption == null) return;
    _questionTimer?.cancel();

    final correctAnswer = QuestionLoader.answerMap[_currentChallenge.id] ?? '';
    final isCorrect = _selectedOption!.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase();

    final points = isCorrect ? _questionPoints : 0;
    _totalScore += points;
    if (isCorrect) _correctCount++;
    _totalAnswered++;

    _results.add(_RapidResult(
      question: _currentChallenge.question,
      correct: isCorrect,
      points: points,
      isShiny: _isShiny,
    ));

    // Update session score
    final session = ref.read(sessionStreamProvider).valueOrNull;
    if (session != null && isCorrect) {
      ref.read(sessionProvider.notifier).addBonusPoints(points);
      _updateLeaderboard();
    }

    setState(() => _showResult = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _shuffled.length ||
        _currentIndex + 1 >= _maxQuestions ||
        _globalSecondsLeft <= 0) {
      _finishGame();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _showResult = false;
    });
    _rollShiny();
    _startQuestionTimer();
  }

  void _finishGame() {
    _questionTimer?.cancel();
    _globalTimer?.cancel();
    setState(() => _isFinished = true);
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

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildSummary();

    final challenge = _currentChallenge;
    final progress = _questionSecondsLeft / 30.0;
    final globalProgress = _globalSecondsLeft / 600.0;

    return GradientScaffold(
      appBar: NeonAppBar(
        title: _isShiny ? '✨ SHINY QUESTION!' : '⚡ RAPID FIRE',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Global timer bar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${(_globalSecondsLeft ~/ 60).toString().padLeft(2, '0')}:'
                    '${(_globalSecondsLeft % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _globalSecondsLeft < 60
                          ? AppColors.error
                          : AppColors.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: globalProgress,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation(
                          _globalSecondsLeft < 60
                              ? AppColors.error
                              : AppColors.neonCyan,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Q${_currentIndex + 1}',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // ── Question timer ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(
                    _questionSecondsLeft <= 10
                        ? AppColors.error
                        : _isShiny
                            ? AppColors.neonYellow
                            : AppColors.neonPurple,
                  ),
                  minHeight: 6,
                ),
              ),
            ),

            // ── Score & streak ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _scoreBadge('SCORE', '$_totalScore', AppColors.neonCyan),
                  _scoreBadge('CORRECT', '$_correctCount/$_totalAnswered',
                      AppColors.neonGreen),
                  if (_isShiny)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonYellow.withValues(alpha: 0.2),
                            AppColors.neonOrange.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.neonYellow.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '✨ 2× POINTS',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neonYellow,
                        ),
                      ),
                    ).animate().shimmer(
                          duration: 1500.ms,
                          color: AppColors.neonYellow.withValues(alpha: 0.4),
                        ),
                ],
              ),
            ),

            // ── Question & Options ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Points indicator
                    Center(
                      child: Text(
                        _isShiny
                            ? '✨ $_questionPoints pts'
                            : '$_questionPoints pts',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isShiny
                              ? AppColors.neonYellow
                              : AppColors.neonCyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Question
                    GlassmorphicContainer(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 16,
                      borderGradientColors: _isShiny
                          ? [
                              AppColors.neonYellow.withValues(alpha: 0.5),
                              AppColors.neonOrange.withValues(alpha: 0.2),
                              AppColors.neonYellow.withValues(alpha: 0.3),
                            ]
                          : null,
                      child: Text(
                        challenge.question,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Options
                    if (challenge.options != null)
                      ...challenge.options!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = _selectedOption == option;

                        Color optionColor;
                        if (_showResult) {
                          final correctAnswer =
                              QuestionLoader.answerMap[challenge.id] ?? '';
                          if (option.trim().toLowerCase() ==
                              correctAnswer.trim().toLowerCase()) {
                            optionColor = AppColors.neonGreen;
                          } else if (isSelected) {
                            optionColor = AppColors.error;
                          } else {
                            optionColor = AppColors.glassBorder;
                          }
                        } else {
                          optionColor = isSelected
                              ? (_isShiny
                                  ? AppColors.neonYellow
                                  : AppColors.neonCyan)
                              : AppColors.glassBorder;
                        }

                        return GestureDetector(
                          onTap: _showResult
                              ? null
                              : () => setState(() => _selectedOption = option),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected && !_showResult
                                  ? optionColor.withValues(alpha: 0.15)
                                  : _showResult
                                      ? optionColor.withValues(alpha: 0.08)
                                      : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: optionColor, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected || _showResult
                                        ? optionColor.withValues(alpha: 0.2)
                                        : AppColors.surfaceLight,
                                    border: Border.all(color: optionColor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: GoogleFonts.inter(
                                        color: optionColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: _showResult
                                          ? optionColor
                                          : (isSelected
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    if (!_showResult) ...[
                      const SizedBox(height: 16),
                      NeonButton(
                        text: 'SUBMIT',
                        icon: Icons.send_rounded,
                        color: _isShiny
                            ? AppColors.neonYellow
                            : AppColors.neonCyan,
                        onPressed: _submit,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Summary screen ──
  Widget _buildSummary() {
    final accuracy =
        _totalAnswered > 0 ? (_correctCount / _totalAnswered * 100) : 0;

    return GradientScaffold(
      appBar: const NeonAppBar(title: 'RAPID FIRE — RESULTS'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('⚡', style: TextStyle(fontSize: 56))
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                'ROUND COMPLETE!',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonCyan,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                        'SCORE', '$_totalScore', AppColors.neonCyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                        'CORRECT', '$_correctCount', AppColors.neonGreen),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                        'ANSWERED', '$_totalAnswered', AppColors.neonPurple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard('ACCURACY', '${accuracy.toInt()}%',
                        AppColors.neonOrange),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Results list
              Text(
                'QUESTION LOG',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),

              ...List.generate(_results.length, (i) {
                final r = _results[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: r.correct
                        ? AppColors.neonGreen.withValues(alpha: 0.06)
                        : AppColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: r.correct
                          ? AppColors.neonGreen.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        r.correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color:
                            r.correct ? AppColors.neonGreen : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.question,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (r.isShiny)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Text('✨', style: TextStyle(fontSize: 12)),
                        ),
                      Text(
                        '+${r.points}',
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: r.correct
                              ? AppColors.neonGreen
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (50 * i).ms).slideX(begin: 0.1);
              }),

              const SizedBox(height: 24),

              NeonButton(
                text: 'BACK TO TEST',
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      borderGradientColors: [
        color.withValues(alpha: 0.4),
        color.withValues(alpha: 0.1),
        color.withValues(alpha: 0.2),
      ],
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class _RapidResult {
  final String question;
  final bool correct;
  final int points;
  final bool isShiny;

  const _RapidResult({
    required this.question,
    required this.correct,
    required this.points,
    required this.isShiny,
  });
}

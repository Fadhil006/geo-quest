import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import 'service_providers.dart';
import 'session_provider.dart';

/// All challenges provider
final challengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repo = ref.read(challengeRepositoryProvider);
  return repo.getChallenges();
});

/// Challenges filtered by difficulty
final challengesByDifficultyProvider =
    FutureProvider.family<List<Challenge>, ChallengeDifficulty>(
        (ref, difficulty) async {
  final repo = ref.read(challengeRepositoryProvider);
  return repo.getChallengesByDifficulty(difficulty);
});

/// Available (not completed) challenges for current session
final availableChallengesProvider =
    FutureProvider<List<Challenge>>((ref) async {
  final session = ref.watch(sessionStreamProvider).valueOrNull;
  if (session == null) return [];

  final repo = ref.read(challengeRepositoryProvider);
  return repo.getAvailableChallenges(
    sessionId: session.id,
    difficulty: session.currentDifficulty,
  );
});

/// Currently active challenge state
class ActiveChallengeNotifier extends StateNotifier<Challenge?> {
  ActiveChallengeNotifier() : super(null);

  void setChallenge(Challenge challenge) => state = challenge;
  void clearChallenge() => state = null;
}

final activeChallengeProvider =
    StateNotifierProvider<ActiveChallengeNotifier, Challenge?>((ref) {
  return ActiveChallengeNotifier();
});

/// Challenge submission state
enum SubmissionStatus { idle, submitting, success, failure }

class SubmissionState {
  final SubmissionStatus status;
  final SubmissionResult? result;
  final String? error;

  const SubmissionState({
    this.status = SubmissionStatus.idle,
    this.result,
    this.error,
  });
}

class SubmissionNotifier extends StateNotifier<SubmissionState> {
  final ChallengeRepository _challengeRepository;

  SubmissionNotifier(this._challengeRepository)
      : super(const SubmissionState());

  Future<void> submitAnswer({
    required String sessionId,
    required String challengeId,
    required String answer,
  }) async {
    state = const SubmissionState(status: SubmissionStatus.submitting);
    try {
      final result = await _challengeRepository.submitAnswer(
        sessionId: sessionId,
        challengeId: challengeId,
        answer: answer,
      );
      state = SubmissionState(
        status: SubmissionStatus.success,
        result: result,
      );
    } catch (e) {
      state = SubmissionState(
        status: SubmissionStatus.failure,
        error: e.toString(),
      );
    }
  }

  Future<void> skipChallenge({
    required String sessionId,
    required String challengeId,
  }) async {
    state = const SubmissionState(status: SubmissionStatus.submitting);
    try {
      await _challengeRepository.skipChallenge(
        sessionId: sessionId,
        challengeId: challengeId,
      );
      state = const SubmissionState(status: SubmissionStatus.success);
    } catch (e) {
      state = SubmissionState(
        status: SubmissionStatus.failure,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const SubmissionState();
}

final submissionProvider =
    StateNotifierProvider<SubmissionNotifier, SubmissionState>((ref) {
  return SubmissionNotifier(ref.read(challengeRepositoryProvider));
});


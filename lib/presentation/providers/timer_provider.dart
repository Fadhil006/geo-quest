import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_provider.dart';

/// Session countdown timer state
class TimerState {
  final Duration remaining;
  final bool isRunning;
  final bool isExpired;
  final double progress; // 0.0 = full time, 1.0 = expired

  const TimerState({
    this.remaining = Duration.zero,
    this.isRunning = false,
    this.isExpired = false,
    this.progress = 0.0,
  });

  TimerState copyWith({
    Duration? remaining,
    bool? isRunning,
    bool? isExpired,
    double? progress,
  }) {
    return TimerState(
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
      isExpired: isExpired ?? this.isExpired,
      progress: progress ?? this.progress,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  DateTime? _endTime;
  DateTime? _startTime;

  TimerNotifier() : super(const TimerState());

  void startCountdown({
    required DateTime startTime,
    required DateTime endTime,
  }) {
    _startTime = startTime;
    _endTime = endTime;
    _timer?.cancel();

    _updateState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateState();
    });
  }

  void _updateState() {
    if (_endTime == null || _startTime == null) return;

    final now = DateTime.now();
    final remaining = _endTime!.difference(now);
    final total = _endTime!.difference(_startTime!).inMilliseconds;
    final elapsed = now.difference(_startTime!).inMilliseconds;
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 1.0;

    if (remaining.isNegative) {
      state = const TimerState(
        remaining: Duration.zero,
        isRunning: false,
        isExpired: true,
        progress: 1.0,
      );
      _timer?.cancel();
    } else {
      state = TimerState(
        remaining: remaining,
        isRunning: true,
        isExpired: false,
        progress: progress,
      );
    }
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final notifier = TimerNotifier();

  // Auto-start when session is available
  ref.listen(sessionStreamProvider, (prev, next) {
    final session = next.valueOrNull;
    if (session != null && session.isActive) {
      notifier.startCountdown(
        startTime: session.startTime,
        endTime: session.endTime,
      );
    }
  });

  return notifier;
});

/// Challenge-specific timer (per-question countdown)
class ChallengeTimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;

  ChallengeTimerNotifier() : super(const TimerState());

  void startChallengeTimer(int seconds) {
    _timer?.cancel();
    final endTime = DateTime.now().add(Duration(seconds: seconds));
    final startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final remaining = endTime.difference(DateTime.now());
      final total = Duration(seconds: seconds).inMilliseconds;
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / total).clamp(0.0, 1.0);

      if (remaining.isNegative) {
        state = const TimerState(
          remaining: Duration.zero,
          isRunning: false,
          isExpired: true,
          progress: 1.0,
        );
        _timer?.cancel();
      } else {
        state = TimerState(
          remaining: remaining,
          isRunning: true,
          isExpired: false,
          progress: progress,
        );
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final challengeTimerProvider =
    StateNotifierProvider<ChallengeTimerNotifier, TimerState>((ref) {
  return ChallengeTimerNotifier();
});


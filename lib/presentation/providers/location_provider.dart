import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/challenge.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/geo_utils.dart';

/// GPS Location state
class LocationState {
  final Position? position;
  final bool isLoading;
  final String? error;
  final bool permissionGranted;

  const LocationState({
    this.position,
    this.isLoading = false,
    this.error,
    this.permissionGranted = false,
  });

  LocationState copyWith({
    Position? position,
    bool? isLoading,
    String? error,
    bool? permissionGranted,
  }) {
    return LocationState(
      position: position ?? this.position,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  StreamSubscription<Position>? _positionSubscription;

  LocationNotifier() : super(const LocationState()) {
    _init();
  }

  Future<void> _init() async {
    // Skip GPS if not enabled
    if (!AppConfig.gpsEnabled) {
      state = const LocationState(
        isLoading: false,
        permissionGranted: false,
        error: null,
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location services are disabled.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            error: 'Location permissions denied.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location permissions permanently denied.',
        );
        return;
      }

      state = state.copyWith(permissionGranted: true);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      state = state.copyWith(position: position, isLoading: false);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          state = state.copyWith(position: position);
        },
        onError: (e) {
          state = state.copyWith(error: e.toString());
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  bool isWithinGeofence(Challenge challenge) {
    final pos = state.position;
    if (pos == null) return false;
    return GeoUtils.isWithinRadius(
      userLat: pos.latitude,
      userLon: pos.longitude,
      targetLat: challenge.latitude,
      targetLon: challenge.longitude,
      radiusMeters: challenge.geofenceRadius,
    );
  }

  double? distanceTo(Challenge challenge) {
    final pos = state.position;
    if (pos == null) return null;
    return GeoUtils.haversineDistance(
      pos.latitude,
      pos.longitude,
      challenge.latitude,
      challenge.longitude,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(locationProvider).position;
});

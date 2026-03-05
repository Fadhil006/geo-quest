import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_app_bar.dart';
import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/map/challenge_bottom_sheet.dart';
import '../../widgets/map/category_chip.dart';

// Conditionally import Google Maps — always present in pubspec
// but only used when offlineMode is false.
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  String? _lastUnlockedChallengeId;

  static const _defaultCenter = LatLng(22.5726, 88.3639);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In offline mode, show the challenge list explorer instead of Google Maps
    if (AppConfig.offlineMode) {
      return _buildOfflineMapScreen(context);
    }
    return _buildOnlineMapScreen(context);
  }

  // ═══════════════════════════════════════════
  // OFFLINE MODE — Challenge List Explorer
  // ═══════════════════════════════════════════
  Widget _buildOfflineMapScreen(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);
    final session = ref.watch(sessionStreamProvider).valueOrNull;
    final completedIds =
        Set<String>.from(session?.completedChallengeIds ?? []);
    final skippedIds =
        Set<String>.from(session?.skippedChallengeIds ?? []);

    return GradientScaffold(
      appBar: const NeonAppBar(title: 'QUEST MAP'),
      body: SafeArea(
        child: challengesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (challenges) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offline mode banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.neonOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.neonOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: AppColors.neonOrange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline Mode — GPS disabled. Tap any challenge to try it.',
                          style: GoogleFonts.inter(
                            color: AppColors.neonOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                // Stats bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      _miniStat(
                          Icons.flag_rounded,
                          '${challenges.length}',
                          'Total',
                          AppColors.neonCyan),
                      const SizedBox(width: 12),
                      _miniStat(
                          Icons.check_circle_rounded,
                          '${completedIds.length}',
                          'Done',
                          AppColors.neonGreen),
                      const SizedBox(width: 12),
                      _miniStat(
                          Icons.skip_next_rounded,
                          '${skippedIds.length}',
                          'Skipped',
                          AppColors.neonOrange),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 4),

                // Challenge list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final c = challenges[index];
                      final isCompleted = completedIds.contains(c.id);
                      final isSkipped = skippedIds.contains(c.id);

                      return _buildChallengeCard(
                        context,
                        challenge: c,
                        isCompleted: isCompleted,
                        isSkipped: isSkipped,
                        index: index,
                      );
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

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: GlassmorphicContainer(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
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

  Widget _buildChallengeCard(
    BuildContext context, {
    required Challenge challenge,
    required bool isCompleted,
    required bool isSkipped,
    required int index,
  }) {
    final statusColor = isCompleted
        ? AppColors.neonGreen
        : isSkipped
            ? AppColors.neonOrange
            : AppColors.neonCyan;
    final statusIcon = isCompleted
        ? Icons.check_circle_rounded
        : isSkipped
            ? Icons.skip_next_rounded
            : Icons.lock_open_rounded;
    final statusLabel =
        isCompleted ? 'Completed' : isSkipped ? 'Skipped' : 'Available';

    return GestureDetector(
      onTap: (isCompleted || isSkipped)
          ? null
          : () => _showChallengeSheet(challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.neonGreen.withOpacity(0.05)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.neonGreen.withOpacity(0.2)
                : AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.15),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Challenge info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: GoogleFonts.inter(
                      color: isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CategoryChip(category: challenge.category),
                      const SizedBox(width: 8),
                      Text(
                        '${challenge.points} pts',
                        style: GoogleFonts.orbitron(
                          color: AppColors.neonCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            if (!isCompleted && !isSkipped)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
  }

  // ═══════════════════════════════════════════
  // ONLINE MODE — Full Google Maps
  // ═══════════════════════════════════════════
  Widget _buildOnlineMapScreen(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final challengesAsync = ref.watch(challengesProvider);
    final session = ref.watch(sessionStreamProvider).valueOrNull;

    // Build markers from challenges
    challengesAsync.whenData((challenges) {
      _buildMarkers(challenges, locationState, session);
    });

    // Check geofence proximity
    _checkGeofence(ref);

    final currentPos = locationState.position;
    final cameraTarget = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : _defaultCenter;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const NeonAppBar(title: 'QUEST MAP'),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: cameraTarget,
              zoom: 17,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _setMapStyle(controller);
            },
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Location loading indicator
          if (locationState.isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            ),

          // Error banner
          if (locationState.error != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  locationState.error!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),

          // Center on user button
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.surface,
              onPressed: () {
                if (currentPos != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(currentPos.latitude, currentPos.longitude),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.neonCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _buildMarkers(
    List<Challenge> challenges,
    LocationState locationState,
    dynamic session,
  ) {
    final completedIds =
        Set<String>.from(session?.completedChallengeIds ?? []);
    final pos = locationState.position;

    _markers.clear();
    _circles.clear();

    for (final challenge in challenges) {
      final isCompleted = completedIds.contains(challenge.id);
      final isWithinRange = pos != null &&
          GeoUtils.isWithinRadius(
            userLat: pos.latitude,
            userLon: pos.longitude,
            targetLat: challenge.latitude,
            targetLon: challenge.longitude,
            radiusMeters: challenge.geofenceRadius,
          );

      // Marker
      _markers.add(
        Marker(
          markerId: MarkerId(challenge.id),
          position: LatLng(challenge.latitude, challenge.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isCompleted
                ? BitmapDescriptor.hueGreen
                : isWithinRange
                    ? BitmapDescriptor.hueCyan
                    : BitmapDescriptor.hueRed,
          ),
          onTap: () {
            if (isWithinRange && !isCompleted) {
              _showChallengeSheet(challenge);
            }
          },
          infoWindow: InfoWindow(
            title: isCompleted ? '✅ ${challenge.title}' : challenge.title,
            snippet: isCompleted
                ? 'Completed'
                : isWithinRange
                    ? 'Tap to unlock!'
                    : '${GeoUtils.formatDistance(GeoUtils.haversineDistance(pos?.latitude ?? 0, pos?.longitude ?? 0, challenge.latitude, challenge.longitude))} away',
          ),
        ),
      );

      // Geofence circle
      _circles.add(
        Circle(
          circleId: CircleId(challenge.id),
          center: LatLng(challenge.latitude, challenge.longitude),
          radius: challenge.geofenceRadius,
          fillColor: isCompleted
              ? AppColors.neonGreen.withOpacity(0.1)
              : isWithinRange
                  ? AppColors.geofenceActive
                  : AppColors.markerLocked.withOpacity(0.1),
          strokeColor: isCompleted
              ? AppColors.neonGreen.withOpacity(0.5)
              : isWithinRange
                  ? AppColors.geofenceBorder
                  : AppColors.markerLocked.withOpacity(0.3),
          strokeWidth: 2,
        ),
      );
    }
  }

  void _checkGeofence(WidgetRef ref) {
    if (AppConfig.offlineMode) return; // Skip in offline mode

    final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
    final locationNotifier = ref.read(locationProvider.notifier);
    final session = ref.watch(sessionStreamProvider).valueOrNull;
    final completedIds =
        Set<String>.from(session?.completedChallengeIds ?? []);

    for (final challenge in challenges) {
      if (completedIds.contains(challenge.id)) continue;
      if (locationNotifier.isWithinGeofence(challenge)) {
        if (_lastUnlockedChallengeId != challenge.id) {
          _lastUnlockedChallengeId = challenge.id;
          // Auto-show challenge bottom sheet
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showChallengeSheet(challenge);
          });
        }
        break;
      }
    }
  }

  void _showChallengeSheet(Challenge challenge) {
    ref.read(activeChallengeProvider.notifier).setChallenge(challenge);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChallengeBottomSheet(challenge: challenge),
    );
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
    // Dark map style
    const style = '''[
      {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
      {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
      {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
      {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
      {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
      {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
      {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
      {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]}
    ]''';
    await controller.setMapStyle(style);
  }
}


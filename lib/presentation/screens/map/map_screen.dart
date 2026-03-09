import 'dart:async';
import 'dart:math';
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
import '../../../core/widgets/neon_button.dart';
import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/map/challenge_bottom_sheet.dart';

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
  // OFFLINE MODE — Interactive Image Map
  // ═══════════════════════════════════════════
  Widget _buildOfflineMapScreen(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);
    final session = ref.watch(sessionStreamProvider).valueOrNull;
    final completedIds = Set<String>.from(session?.completedChallengeIds ?? []);
    final skippedIds = Set<String>.from(session?.skippedChallengeIds ?? []);

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
              children: [
                // Stats bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      _miniStat(Icons.flag_rounded, '${challenges.length}',
                          'Total', AppColors.neonCyan),
                      const SizedBox(width: 12),
                      _miniStat(
                          Icons.check_circle_rounded,
                          '${completedIds.length}',
                          'Done',
                          AppColors.neonGreen),
                      const SizedBox(width: 12),
                      _miniStat(Icons.skip_next_rounded, '${skippedIds.length}',
                          'Skipped', AppColors.neonOrange),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                // ── Interactive Map ──
                Expanded(
                  child: _InteractiveQuestMap(
                    challenges: challenges,
                    completedIds: completedIds,
                    skippedIds: skippedIds,
                    onChallengeTap: (challenge) {
                      _showChallengeSheet(challenge);
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
    final completedIds = Set<String>.from(session?.completedChallengeIds ?? []);
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
    final completedIds = Set<String>.from(session?.completedChallengeIds ?? []);

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

// ═══════════════════════════════════════════════════
// Interactive Image-Based Quest Map
// ═══════════════════════════════════════════════════
class _InteractiveQuestMap extends StatefulWidget {
  final List<Challenge> challenges;
  final Set<String> completedIds;
  final Set<String> skippedIds;
  final void Function(Challenge) onChallengeTap;

  const _InteractiveQuestMap({
    required this.challenges,
    required this.completedIds,
    required this.skippedIds,
    required this.onChallengeTap,
  });

  @override
  State<_InteractiveQuestMap> createState() => _InteractiveQuestMapState();
}

class _InteractiveQuestMapState extends State<_InteractiveQuestMap> {
  final TransformationController _transformController =
      TransformationController();
  Challenge? _selectedChallenge;
  bool _showWalkAnimation = false;

  /// Distribute challenges as pin positions on the map image.
  /// Uses a seeded random spread across the image bounds.
  List<Offset> _markerPositions(int count, Size mapSize) {
    final rng = Random(42); // Fixed seed for deterministic placement
    const margin = 0.08; // 8% margin from edges
    final positions = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = mapSize.width * (margin + rng.nextDouble() * (1 - 2 * margin));
      final y = mapSize.height * (margin + rng.nextDouble() * (1 - 2 * margin));
      positions.add(Offset(x, y));
    }
    return positions;
  }

  Color _markerColor(Challenge c) {
    if (widget.completedIds.contains(c.id)) return AppColors.neonGreen;
    if (widget.skippedIds.contains(c.id)) return AppColors.neonOrange;
    return AppColors.neonCyan;
  }

  IconData _markerIcon(Challenge c) {
    if (widget.completedIds.contains(c.id)) return Icons.check_circle_rounded;
    if (widget.skippedIds.contains(c.id)) return Icons.skip_next_rounded;
    return Icons.location_on_rounded;
  }

  /// IDs of the next 3 unattempted challenges to show on the map.
  List<String> get _nextAvailableIds {
    final available = widget.challenges
        .where((c) =>
            !widget.completedIds.contains(c.id) &&
            !widget.skippedIds.contains(c.id))
        .take(3)
        .map((c) => c.id)
        .toList();
    return available;
  }

  /// Whether this challenge is one of the next 3 available to attempt.
  bool _isInNextAvailable(String challengeId) {
    return _nextAvailableIds.contains(challengeId);
  }

  /// Returns the encounter order number (1-based) for a challenge.
  /// Completed and skipped challenges get their order based on when the team
  /// encountered them. Unattempted challenges show no number (null).
  int? _encounterOrder(String challengeId) {
    // Build ordered encounter list: completed + skipped in encounter order
    final encountered = <String>[
      ...widget.completedIds,
      ...widget.skippedIds,
    ];
    final idx = encountered.indexOf(challengeId);
    if (idx >= 0) return idx + 1;
    return null; // not yet encountered
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Map with markers ──
        LayoutBuilder(
          builder: (context, constraints) {
            // Map image is 1117x605. Scale to fit width, keep aspect ratio.
            const imgAspect = 1117.0 / 605.0;
            final viewW = constraints.maxWidth;
            final viewH = constraints.maxHeight;
            final mapW = viewW;
            final mapH = mapW / imgAspect;

            final positions =
                _markerPositions(widget.challenges.length, Size(mapW, mapH));

            return InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 3.0,
              constrained: false,
              boundaryMargin: EdgeInsets.symmetric(
                horizontal: viewW * 0.2,
                vertical: viewH * 0.2,
              ),
              child: SizedBox(
                width: mapW,
                height: max(mapH, viewH),
                child: Stack(
                  children: [
                    // Map image
                    Positioned(
                      top: max(0, (viewH - mapH) / 2),
                      left: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'question/map/image.png',
                          width: mapW,
                          height: mapH,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Dark overlay for contrast
                    Positioned(
                      top: max(0, (viewH - mapH) / 2),
                      left: 0,
                      child: Container(
                        width: mapW,
                        height: mapH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    // Challenge markers — only show done/skipped + next 3 available
                    ...List.generate(widget.challenges.length, (i) {
                      final c = widget.challenges[i];
                      final isCompleted = widget.completedIds.contains(c.id);
                      final isSkipped = widget.skippedIds.contains(c.id);

                      // Only show completed, skipped, or the next 3 unattempted
                      if (!isCompleted &&
                          !isSkipped &&
                          !_isInNextAvailable(c.id)) {
                        return const SizedBox.shrink();
                      }

                      final pos = positions[i];
                      final yOffset = max(0.0, (viewH - mapH) / 2);
                      final color = _markerColor(c);
                      final isSelected = _selectedChallenge?.id == c.id;
                      final markerSize = isSelected ? 36.0 : 28.0;

                      // Encounter order: completed + skipped in the order the team got them
                      final encounterOrder = _encounterOrder(c.id);

                      return Positioned(
                        left: pos.dx - markerSize / 2,
                        top: yOffset + pos.dy - markerSize / 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedChallenge = c);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: markerSize,
                            height: markerSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.9),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : color.withValues(alpha: 0.6),
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: isSelected ? 16 : 8,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16)
                                  : isSkipped
                                      ? const Icon(Icons.skip_next_rounded,
                                          color: Colors.white, size: 14)
                                      : Text(
                                          encounterOrder != null
                                              ? '$encounterOrder'
                                              : '?',
                                          style: GoogleFonts.orbitron(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),

        // ── Walk animation overlay ──
        if (_showWalkAnimation)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🚶', style: TextStyle(fontSize: 56))
                      .animate(
                        onComplete: (c) => c.repeat(),
                      )
                      .slideX(
                        begin: -0.3,
                        end: 0.3,
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 16),
                  Text(
                    'Walking to challenge...',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Selected challenge info panel ──
        if (_selectedChallenge != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildChallengePanel(_selectedChallenge!),
          ),

        // ── Legend ──
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendDot(AppColors.neonCyan, 'Quest'),
                _legendDot(AppColors.neonGreen, 'Done'),
                _legendDot(AppColors.neonOrange, 'Skipped'),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengePanel(Challenge challenge) {
    final isCompleted = widget.completedIds.contains(challenge.id);
    final isSkipped = widget.skippedIds.contains(challenge.id);
    final isAvailable = !isCompleted && !isSkipped;
    final color = _markerColor(challenge);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.4), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title + close
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                  ),
                  child: Icon(_markerIcon(challenge), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => setState(() => _selectedChallenge = null),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info chips
            Row(
              children: [
                _panelChip(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : isSkipped
                          ? Icons.skip_next_rounded
                          : Icons.play_circle_rounded,
                  isCompleted
                      ? 'Completed'
                      : isSkipped
                          ? 'Skipped'
                          : 'Available',
                  isCompleted
                      ? AppColors.neonGreen
                      : isSkipped
                          ? AppColors.neonOrange
                          : AppColors.neonCyan,
                ),
              ],
            ),
            // Action button
            if (isAvailable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: NeonButton(
                  text: 'WALK HERE & SOLVE',
                  icon: Icons.directions_walk_rounded,
                  onPressed: () => _walkToChallenge(challenge),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _panelChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _walkToChallenge(Challenge challenge) {
    setState(() => _showWalkAnimation = true);

    // Simulate walking for 1.5 seconds then open challenge
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _showWalkAnimation = false;
        _selectedChallenge = null;
      });
      widget.onChallengeTap(challenge);
    });
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/map_grid_config.dart';
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
import '../../widgets/map/map_svg_overlay.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _lastUnlockedChallengeId;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always show the interactive image map (no Google Maps API key needed).
    // When GPS is enabled, markers are proximity-aware.
    // When offlineMode && !gpsEnabled, use the tap-to-walk simulation.
    return _buildImageMapScreen(context);
  }

  // ═══════════════════════════════════════════
  // IMAGE MAP — GPS-aware when gpsEnabled
  // ═══════════════════════════════════════════
  Widget _buildImageMapScreen(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);
    final session = ref.watch(sessionStreamProvider).valueOrNull;
    final completedIds = Set<String>.from(session?.completedChallengeIds ?? []);
    final skippedIds = Set<String>.from(session?.skippedChallengeIds ?? []);
    final locationState = AppConfig.gpsEnabled ? ref.watch(locationProvider) : null;

    // Auto-trigger challenge when entering a geofence
    if (AppConfig.gpsEnabled) {
      _checkGeofence(ref);
    }

    return GradientScaffold(
      appBar: const NeonAppBar(title: 'QUEST MAP'),
      body: SafeArea(
        child: challengesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (challenges) {
            return Column(
              children: [
                // GPS status + stats bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    children: [
                      // GPS status indicator
                      if (AppConfig.gpsEnabled)
                        _buildGpsStatusBar(locationState!),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _miniStat(
                            Icons.flag_rounded,
                            '${challenges.length}',
                            'Total',
                            AppColors.neonCyan,
                          ),
                          const SizedBox(width: 12),
                          _miniStat(
                            Icons.check_circle_rounded,
                            '${completedIds.length}',
                            'Done',
                            AppColors.neonGreen,
                          ),
                          const SizedBox(width: 12),
                          _miniStat(
                            Icons.skip_next_rounded,
                            '${skippedIds.length}',
                            'Skipped',
                            AppColors.neonOrange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                // ── Interactive Map ──
                Expanded(
                  child: _InteractiveQuestMap(
                    challenges: challenges,
                    completedIds: completedIds,
                    skippedIds: skippedIds,
                    userPosition: locationState?.position,
                    gpsEnabled: AppConfig.gpsEnabled,
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

  Widget _buildGpsStatusBar(LocationState locationState) {
    final hasPosition = locationState.position != null;
    final isLoading = locationState.isLoading;
    final error = locationState.error;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isLoading) {
      statusColor = AppColors.neonOrange;
      statusIcon = Icons.gps_not_fixed_rounded;
      statusText = 'Acquiring GPS signal...';
    } else if (error != null) {
      statusColor = AppColors.error;
      statusIcon = Icons.gps_off_rounded;
      statusText = error;
    } else if (hasPosition) {
      statusColor = AppColors.neonGreen;
      statusIcon = Icons.gps_fixed_rounded;
      statusText = 'GPS active — walk to quest markers!';
    } else {
      statusColor = AppColors.textMuted;
      statusIcon = Icons.gps_not_fixed_rounded;
      statusText = 'Waiting for GPS...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            ),
        ],
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

  void _checkGeofence(WidgetRef ref) {
    if (!AppConfig.gpsEnabled) return;

    final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
    final locationNotifier = ref.read(locationProvider.notifier);
    final session = ref.watch(sessionStreamProvider).valueOrNull;
    final completedIds = Set<String>.from(session?.completedChallengeIds ?? []);
    final skippedIds = Set<String>.from(session?.skippedChallengeIds ?? []);

    for (final challenge in challenges) {
      if (completedIds.contains(challenge.id)) continue;
      if (skippedIds.contains(challenge.id)) continue;
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
}

// ═══════════════════════════════════════════════════
// Interactive Image-Based Quest Map
// ═══════════════════════════════════════════════════
class _InteractiveQuestMap extends StatefulWidget {
  final List<Challenge> challenges;
  final Set<String> completedIds;
  final Set<String> skippedIds;
  final Position? userPosition;
  final bool gpsEnabled;
  final void Function(Challenge) onChallengeTap;

  const _InteractiveQuestMap({
    required this.challenges,
    required this.completedIds,
    required this.skippedIds,
    this.userPosition,
    this.gpsEnabled = false,
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

  // ── GPS helpers ──────────────────────────────

  double? _distanceTo(Challenge c) {
    final pos = widget.userPosition;
    if (!widget.gpsEnabled || pos == null) return null;
    return GeoUtils.haversineDistance(
      pos.latitude, pos.longitude,
      c.latitude, c.longitude,
    );
  }

  bool _isWithinRange(Challenge c) {
    final dist = _distanceTo(c);
    if (dist == null) return false;
    return dist <= c.geofenceRadius;
  }

  Color _markerColor(Challenge c) {
    if (widget.completedIds.contains(c.id)) return AppColors.neonGreen;
    if (widget.skippedIds.contains(c.id)) return AppColors.neonOrange;
    if (widget.gpsEnabled && widget.userPosition != null) {
      return _isWithinRange(c) ? AppColors.neonGreen : AppColors.neonCyan;
    }
    return AppColors.neonCyan;
  }

  IconData _markerIcon(Challenge c) {
    if (widget.completedIds.contains(c.id)) return Icons.check_circle_rounded;
    if (widget.skippedIds.contains(c.id)) return Icons.skip_next_rounded;
    return Icons.location_on_rounded;
  }

  // ── Visibility helpers ──────────────────────

  List<String> get _nextAvailableIds {
    return widget.challenges
        .where((c) =>
            !widget.completedIds.contains(c.id) &&
            !widget.skippedIds.contains(c.id))
        .take(3)
        .map((c) => c.id)
        .toList();
  }

  bool _isVisible(Challenge c) {
    return widget.completedIds.contains(c.id) ||
        widget.skippedIds.contains(c.id) ||
        _nextAvailableIds.contains(c.id);
  }

  Set<String> get _visibleIds {
    return widget.challenges
        .where(_isVisible)
        .map((c) => c.id)
        .toSet();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Map + SVG overlay ──
        LayoutBuilder(
          builder: (context, constraints) {
            const imgAspect = MapGridConfig.imageWidth / MapGridConfig.imageHeight;
            final viewW = constraints.maxWidth;
            final viewH = constraints.maxHeight;
            final mapW = viewW;
            final mapH = mapW / imgAspect;
            final yOffset = max(0.0, (viewH - mapH) / 2);

            // Build SVG overlay string
            final svgString = MapSvgOverlay.build(
              mapWidth: mapW,
              mapHeight: mapH,
              challenges: widget.challenges,
              completedIds: widget.completedIds,
              skippedIds: widget.skippedIds,
              visibleIds: _visibleIds,
              userLat: widget.userPosition?.latitude,
              userLng: widget.userPosition?.longitude,
              selectedChallengeId: _selectedChallenge?.id,
            );

            return InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 4.0,
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
                    // Layer 1: Map image
                    Positioned(
                      top: yOffset,
                      left: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/map/image.png',
                          width: mapW,
                          height: mapH,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Layer 2: Dark overlay
                    Positioned(
                      top: yOffset,
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
                    // Layer 3: SVG overlay (grid + markers + user dot)
                    Positioned(
                      top: yOffset,
                      left: 0,
                      child: IgnorePointer(
                        child: SvgPicture.string(
                          svgString,
                          width: mapW,
                          height: mapH,
                        ),
                      ),
                    ),
                    // Layer 4: Invisible tap zones for each visible challenge
                    ...widget.challenges.where(_isVisible).map((c) {
                      final px = MapGridConfig.geoToPixel(
                        c.latitude, c.longitude, mapW, mapH,
                      );
                      const hitSize = 40.0;
                      return Positioned(
                        left: px.dx - hitSize / 2,
                        top: yOffset + px.dy - hitSize / 2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _selectedChallenge = c),
                          child: SizedBox(
                            width: hitSize,
                            height: hitSize,
                            // Distance tooltip below marker
                            child: widget.gpsEnabled && _distanceTo(c) != null &&
                                !widget.completedIds.contains(c.id) &&
                                !widget.skippedIds.contains(c.id)
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      GeoUtils.formatDistance(_distanceTo(c)!),
                                      style: GoogleFonts.inter(
                                        fontSize: 7,
                                        color: _isWithinRange(c)
                                            ? AppColors.neonGreen
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
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
                      .animate(onComplete: (c) => c.repeat())
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
                _legendItem(AppColors.neonCyan, 'Quest'),
                if (widget.gpsEnabled) ...[
                  _legendItem(AppColors.neonGreen, 'In Range'),
                  _legendItem(const Color(0xFF0096FF), 'You'),
                ],
                _legendItem(AppColors.neonGreen, 'Done'),
                _legendItem(AppColors.neonOrange, 'Skipped'),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ),

        // ── Grid reference (bottom-left) ──
        if (widget.gpsEnabled && widget.userPosition != null)
          Positioned(
            bottom: _selectedChallenge != null ? 260 : 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_on_rounded,
                      size: 12, color: AppColors.neonCyan),
                  const SizedBox(width: 4),
                  Text(
                    _userGridRef,
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonCyan,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ),
      ],
    );
  }

  /// User's current grid cell label, e.g. "D3".
  String get _userGridRef {
    final pos = widget.userPosition;
    if (pos == null) return '--';
    final (col, row) = MapGridConfig.geoToGrid(pos.latitude, pos.longitude);
    return MapGridConfig.gridLabel(col, row);
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
    final dist = _distanceTo(challenge);
    final inRange = _isWithinRange(challenge);
    // In GPS mode you must be in range; in sim mode always allowed
    final canAttempt = isAvailable && (!widget.gpsEnabled || inRange);

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
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
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
                // Distance chip (GPS mode)
                if (widget.gpsEnabled && dist != null && isAvailable) ...[
                  const SizedBox(width: 8),
                  _panelChip(
                    inRange ? Icons.near_me_rounded : Icons.explore_rounded,
                    inRange
                        ? '${GeoUtils.formatDistance(dist)} — In range!'
                        : '${GeoUtils.formatDistance(dist)} away',
                    inRange ? AppColors.neonGreen : AppColors.neonOrange,
                  ),
                ],
              ],
            ),
            // Action button
            if (isAvailable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: canAttempt
                    ? NeonButton(
                        text: widget.gpsEnabled ? 'SOLVE CHALLENGE' : 'WALK HERE & SOLVE',
                        icon: widget.gpsEnabled ? Icons.play_arrow_rounded : Icons.directions_walk_rounded,
                        onPressed: () => _walkToChallenge(challenge),
                      )
                    : Opacity(
                        opacity: 0.5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.textMuted.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'GET CLOSER — ${GeoUtils.formatDistance(dist ?? 0)} away',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
    if (widget.gpsEnabled) {
      // GPS mode — user is already in range, open challenge immediately
      setState(() => _selectedChallenge = null);
      widget.onChallengeTap(challenge);
    } else {
      // Sim mode — show walk animation then open challenge
      setState(() => _showWalkAnimation = true);
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
}

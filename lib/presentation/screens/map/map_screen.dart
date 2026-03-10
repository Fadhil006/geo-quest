import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Native (Android / iOS) ───────────────────────────────
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps
    show
        GoogleMap,
        GoogleMapController,
        CameraPosition,
        CameraUpdate,
        LatLng,
        Marker,
        MarkerId,
        BitmapDescriptor,
        InfoWindow,
        MapType;

// ── Web ──────────────────────────────────────────────────
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart' as ll;

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

const String _googleApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: '',
);

// Campus centre (IIIT Kottayam, Valavoor, Kerala)
const double _campusLat = 9.754914;
const double _campusLng = 76.649674;

// ═══════════════════════════════════════════════════════
// MapScreen
// ═══════════════════════════════════════════════════════
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _lastUnlockedChallengeId;

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);
    final session = ref.watch(sessionStreamProvider).valueOrNull;
    final completedIds = Set<String>.from(session?.completedChallengeIds ?? []);
    final skippedIds = Set<String>.from(session?.skippedChallengeIds ?? []);
    final locationState =
        AppConfig.gpsEnabled ? ref.watch(locationProvider) : null;

    if (AppConfig.gpsEnabled) _checkGeofence(ref);

    return GradientScaffold(
      appBar: const NeonAppBar(title: 'QUEST MAP'),
      body: SafeArea(
        child: challengesAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan)),
          error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.error))),
          data: (challenges) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  children: [
                    if (AppConfig.gpsEnabled)
                      _buildGpsStatusBar(locationState!),
                    const SizedBox(height: 6),
                    Row(
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
                        _miniStat(
                            Icons.skip_next_rounded,
                            '${skippedIds.length}',
                            'Skipped',
                            AppColors.neonOrange),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
              Expanded(
                child: kIsWeb
                    ? _WebQuestMap(
                        challenges: challenges,
                        completedIds: completedIds,
                        skippedIds: skippedIds,
                        userPosition: locationState?.position,
                        gpsEnabled: AppConfig.gpsEnabled,
                        onChallengeTap: _showChallengeSheet,
                      )
                    : _NativeQuestMap(
                        challenges: challenges,
                        completedIds: completedIds,
                        skippedIds: skippedIds,
                        userPosition: locationState?.position,
                        gpsEnabled: AppConfig.gpsEnabled,
                        onChallengeTap: _showChallengeSheet,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsStatusBar(LocationState locationState) {
    final hasPosition = locationState.position != null;
    final isLoading = locationState.isLoading;
    final error = locationState.error;

    Color c;
    IconData icon;
    String text;

    if (isLoading) {
      c = AppColors.neonOrange;
      icon = Icons.gps_not_fixed_rounded;
      text = 'Acquiring GPS signal...';
    } else if (error != null) {
      c = AppColors.error;
      icon = Icons.gps_off_rounded;
      text = error;
    } else if (hasPosition) {
      c = AppColors.neonGreen;
      icon = Icons.gps_fixed_rounded;
      text = 'GPS active — walk to quest markers!';
    } else {
      c = AppColors.textMuted;
      icon = Icons.gps_not_fixed_rounded;
      text = 'Waiting for GPS...';
    }

    return GestureDetector(
      onTap: (error != null && !isLoading)
          ? () => ref.read(locationProvider.notifier).retry()
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: c, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            if (isLoading)
              SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c)),
            if (error != null && !isLoading)
              Icon(Icons.refresh_rounded, color: c, size: 18),
          ],
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
            Text(value,
                style: GoogleFonts.orbitron(
                    color: color, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _checkGeofence(WidgetRef ref) {
    final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
    final notifier = ref.read(locationProvider.notifier);
    final session = ref.watch(sessionStreamProvider).valueOrNull;
    final completedIds = Set<String>.from(session?.completedChallengeIds ?? []);
    final skippedIds = Set<String>.from(session?.skippedChallengeIds ?? []);

    for (final c in challenges) {
      if (completedIds.contains(c.id) || skippedIds.contains(c.id)) continue;
      if (notifier.isWithinGeofence(c)) {
        if (_lastUnlockedChallengeId != c.id) {
          _lastUnlockedChallengeId = c.id;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showChallengeSheet(c));
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

// ═══════════════════════════════════════════════════════
// Shared challenge panel mixin helpers
// ═══════════════════════════════════════════════════════
mixin _ChallengePanelMixin<T extends StatefulWidget> on State<T> {
  // subclasses provide these
  Set<String> get completedIds;
  Set<String> get skippedIds;
  bool get gpsEnabled;
  Position? get userPosition;
  void Function(Challenge) get onChallengeTap;

  double? distanceTo(Challenge c) {
    final pos = userPosition;
    if (!gpsEnabled || pos == null) return null;
    return GeoUtils.haversineDistance(
        pos.latitude, pos.longitude, c.latitude, c.longitude);
  }

  bool isWithinRange(Challenge c) {
    final d = distanceTo(c);
    return d != null && d <= c.geofenceRadius;
  }

  Color markerColor(Challenge c) {
    if (completedIds.contains(c.id)) return AppColors.neonGreen;
    if (skippedIds.contains(c.id)) return AppColors.neonOrange;
    if (gpsEnabled && isWithinRange(c)) return AppColors.neonGreen;
    return AppColors.neonCyan;
  }

  IconData markerIcon(Challenge c) {
    if (completedIds.contains(c.id)) return Icons.check_circle_rounded;
    if (skippedIds.contains(c.id)) return Icons.skip_next_rounded;
    return Icons.location_on_rounded;
  }

  Widget buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(AppColors.neonCyan, 'Quest'),
          if (gpsEnabled) ...[
            _legendItem(AppColors.neonGreen, 'In Range'),
            _legendItem(const Color(0xFF4285F4), 'You'),
          ],
          _legendItem(AppColors.neonGreen, 'Done'),
          _legendItem(AppColors.neonOrange, 'Skipped'),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget buildChallengePanel(Challenge challenge,
      {required VoidCallback onClose}) {
    final isCompleted = completedIds.contains(challenge.id);
    final isSkipped = skippedIds.contains(challenge.id);
    final isAvailable = !isCompleted && !isSkipped;
    final color = markerColor(challenge);
    final dist = distanceTo(challenge);
    final inRange = isWithinRange(challenge);
    final canAttempt = isAvailable && (!gpsEnabled || inRange);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
            top: BorderSide(color: color.withValues(alpha: 0.4), width: 2)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.2)),
                  child: Icon(markerIcon(challenge), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(challenge.title,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700))),
                IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    onPressed: onClose),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(
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
                if (gpsEnabled && dist != null && isAvailable) ...[
                  const SizedBox(width: 8),
                  _chip(
                    inRange ? Icons.near_me_rounded : Icons.explore_rounded,
                    inRange
                        ? '${GeoUtils.formatDistance(dist)} — In range!'
                        : '${GeoUtils.formatDistance(dist)} away',
                    inRange ? AppColors.neonGreen : AppColors.neonOrange,
                  ),
                ],
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: canAttempt
                    ? NeonButton(
                        text: 'SOLVE CHALLENGE',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          onClose();
                          onChallengeTap(challenge);
                        },
                      )
                    : Opacity(
                        opacity: 0.5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.textMuted.withValues(alpha: 0.15),
                            border: Border.all(
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_rounded,
                                    color: AppColors.textMuted, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'GET CLOSER — ${GeoUtils.formatDistance(dist ?? 0)} away',
                                  style: GoogleFonts.orbitron(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w700),
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

  Widget _chip(IconData icon, String label, Color color) {
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
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// _NativeQuestMap  ── Android / iOS  (google_maps_flutter)
// ═══════════════════════════════════════════════════════
class _NativeQuestMap extends StatefulWidget {
  final List<Challenge> challenges;
  final Set<String> completedIds;
  final Set<String> skippedIds;
  final Position? userPosition;
  final bool gpsEnabled;
  final void Function(Challenge) onChallengeTap;

  const _NativeQuestMap({
    required this.challenges,
    required this.completedIds,
    required this.skippedIds,
    this.userPosition,
    this.gpsEnabled = false,
    required this.onChallengeTap,
  });

  @override
  State<_NativeQuestMap> createState() => _NativeQuestMapState();
}

class _NativeQuestMapState extends State<_NativeQuestMap>
    with _ChallengePanelMixin {
  gmaps.GoogleMapController? _ctrl;
  Challenge? _selected;
  bool _followingUser = true;

  @override
  Set<String> get completedIds => widget.completedIds;
  @override
  Set<String> get skippedIds => widget.skippedIds;
  @override
  bool get gpsEnabled => widget.gpsEnabled;
  @override
  Position? get userPosition => widget.userPosition;
  @override
  void Function(Challenge) get onChallengeTap => widget.onChallengeTap;

  gmaps.BitmapDescriptor _hue(Challenge c) {
    if (completedIds.contains(c.id)) {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueGreen);
    }
    if (skippedIds.contains(c.id)) {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueOrange);
    }
    if (gpsEnabled && isWithinRange(c)) {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueGreen);
    }
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueAzure);
  }

  List<String> get _nextAvailableIds => widget.challenges
      .where((c) => !completedIds.contains(c.id) && !skippedIds.contains(c.id))
      .take(3)
      .map((c) => c.id)
      .toList();

  bool _isVisible(Challenge c) =>
      completedIds.contains(c.id) ||
      skippedIds.contains(c.id) ||
      _nextAvailableIds.contains(c.id);

  Set<gmaps.Marker> get _markers =>
      widget.challenges.where(_isVisible).map((c) {
        final dist = distanceTo(c);
        final snippet = completedIds.contains(c.id)
            ? '✓ Completed'
            : skippedIds.contains(c.id)
                ? 'Skipped'
                : dist != null
                    ? 'Available · ${GeoUtils.formatDistance(dist)}'
                    : 'Available';
        return gmaps.Marker(
          markerId: gmaps.MarkerId(c.id),
          position: gmaps.LatLng(c.latitude, c.longitude),
          icon: _hue(c),
          infoWindow: gmaps.InfoWindow(title: c.title, snippet: snippet),
          onTap: () => setState(() => _selected = c),
        );
      }).toSet();

  gmaps.LatLng get _initialTarget {
    final pos = userPosition;
    if (pos != null) return gmaps.LatLng(pos.latitude, pos.longitude);
    if (widget.challenges.isNotEmpty) {
      return gmaps.LatLng(
          widget.challenges.first.latitude, widget.challenges.first.longitude);
    }
    return const gmaps.LatLng(_campusLat, _campusLng);
  }

  @override
  void didUpdateWidget(_NativeQuestMap old) {
    super.didUpdateWidget(old);
    final pos = widget.userPosition;
    if (pos != null &&
        pos != old.userPosition &&
        _ctrl != null &&
        _followingUser) {
      _ctrl!.animateCamera(gmaps.CameraUpdate.newLatLng(
          gmaps.LatLng(pos.latitude, pos.longitude)));
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        gmaps.GoogleMap(
          initialCameraPosition:
              gmaps.CameraPosition(target: _initialTarget, zoom: 17.5),
          onMapCreated: (c) async {
            _ctrl = c;
            await c.setMapStyle(_darkMapStyle);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _markers,
          mapType: gmaps.MapType.satellite,
          compassEnabled: true,
          zoomControlsEnabled: false,
          tiltGesturesEnabled: false,
          onCameraMove: (_) {
            if (_followingUser) setState(() => _followingUser = false);
          },
          onTap: (_) => setState(() => _selected = null),
        ),
        Positioned(top: 8, right: 8, child: buildLegend()),
        Positioned(
          bottom: _selected != null ? 300 : 20,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: _followingUser
                ? AppColors.neonCyan.withValues(alpha: 0.9)
                : AppColors.card,
            elevation: 4,
            onPressed: () {
              setState(() => _followingUser = true);
              final pos = userPosition;
              if (pos != null && _ctrl != null) {
                _ctrl!.animateCamera(gmaps.CameraUpdate.newCameraPosition(
                  gmaps.CameraPosition(
                    target: gmaps.LatLng(pos.latitude, pos.longitude),
                    zoom: 17.5,
                  ),
                ));
              }
            },
            child: Icon(
              _followingUser
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded,
              color: _followingUser ? Colors.black : AppColors.neonCyan,
              size: 20,
            ),
          ),
        ),
        if (_selected != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildChallengePanel(_selected!,
                onClose: () => setState(() => _selected = null)),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// _WebQuestMap  ── Flutter Web  (flutter_map + OSM tiles
//                 or Google tile layer via API key)
// Live blue dot moves as you walk — uses browser Geolocation API
// ═══════════════════════════════════════════════════════
class _WebQuestMap extends StatefulWidget {
  final List<Challenge> challenges;
  final Set<String> completedIds;
  final Set<String> skippedIds;
  final Position? userPosition;
  final bool gpsEnabled;
  final void Function(Challenge) onChallengeTap;

  const _WebQuestMap({
    required this.challenges,
    required this.completedIds,
    required this.skippedIds,
    this.userPosition,
    this.gpsEnabled = false,
    required this.onChallengeTap,
  });

  @override
  State<_WebQuestMap> createState() => _WebQuestMapState();
}

class _WebQuestMapState extends State<_WebQuestMap> with _ChallengePanelMixin {
  final MapController _mapCtrl = MapController();
  Challenge? _selected;
  bool _followingUser = true;

  @override
  Set<String> get completedIds => widget.completedIds;
  @override
  Set<String> get skippedIds => widget.skippedIds;
  @override
  bool get gpsEnabled => widget.gpsEnabled;
  @override
  Position? get userPosition => widget.userPosition;
  @override
  void Function(Challenge) get onChallengeTap => widget.onChallengeTap;

  List<String> get _nextAvailableIds => widget.challenges
      .where((c) => !completedIds.contains(c.id) && !skippedIds.contains(c.id))
      .take(3)
      .map((c) => c.id)
      .toList();

  bool _isVisible(Challenge c) =>
      completedIds.contains(c.id) ||
      skippedIds.contains(c.id) ||
      _nextAvailableIds.contains(c.id);

  ll.LatLng get _initialCenter {
    final pos = userPosition;
    if (pos != null) return ll.LatLng(pos.latitude, pos.longitude);
    if (widget.challenges.isNotEmpty) {
      return ll.LatLng(
          widget.challenges.first.latitude, widget.challenges.first.longitude);
    }
    return ll.LatLng(_campusLat, _campusLng);
  }

  @override
  void didUpdateWidget(_WebQuestMap old) {
    super.didUpdateWidget(old);
    final pos = widget.userPosition;
    if (pos != null && pos != old.userPosition && _followingUser) {
      _mapCtrl.move(
          ll.LatLng(pos.latitude, pos.longitude), _mapCtrl.camera.zoom);
    }
  }

  Color _webMarkerColor(Challenge c) {
    if (completedIds.contains(c.id)) return AppColors.neonGreen;
    if (skippedIds.contains(c.id)) return AppColors.neonOrange;
    if (gpsEnabled && isWithinRange(c)) return AppColors.neonGreen;
    return AppColors.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── flutter_map with Google Maps tile layer ──
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 16.5,
            minZoom: 14,
            maxZoom: 20,
            // Restrict panning to IIIT Kottayam campus area
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                ll.LatLng(9.7500, 76.6440), // south-west corner
                ll.LatLng(9.7600, 76.6560), // north-east corner
              ),
            ),
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _followingUser) {
                setState(() => _followingUser = false);
              }
            },
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            // Google Maps satellite tiles
            TileLayer(
              urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.applabs.geo_quest',
              maxZoom: 20,
            ),

            // Live location blue dot (uses browser Geolocation API on web)
            CurrentLocationLayer(
              style: LocationMarkerStyle(
                marker: const DefaultLocationMarker(
                  color: Color(0xFF4285F4),
                  child: Icon(Icons.navigation, color: Colors.white, size: 12),
                ),
                markerSize: const Size(20, 20),
                accuracyCircleColor:
                    const Color(0xFF4285F4).withValues(alpha: 0.15),
                headingSectorColor:
                    const Color(0xFF4285F4).withValues(alpha: 0.6),
              ),
            ),

            // Challenge markers
            MarkerLayer(
              markers: [
                // Fixed reference point: 9°45'13.7"N 76°39'27.8"E
                Marker(
                  point: ll.LatLng(9.75381, 76.65772),
                  width: 44,
                  height: 54,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.red.withValues(alpha: 0.6),
                                blurRadius: 10)
                          ],
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Colors.red, size: 20),
                      ),
                      CustomPaint(
                        size: const Size(2, 8),
                        painter: _PinTailPainter(Colors.red),
                      ),
                    ],
                  ),
                ),
                // Quest challenge markers
                ...widget.challenges.where(_isVisible).map((c) {
                final color = _webMarkerColor(c);
                return Marker(
                  point: ll.LatLng(c.latitude, c.longitude),
                  width: 40,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = c),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Icon(markerIcon(c), color: color, size: 16),
                        ),
                        CustomPaint(
                          size: const Size(2, 8),
                          painter: _PinTailPainter(color),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ],
            ),
          ],
        ),

        // ── Legend ──
        Positioned(top: 8, right: 8, child: buildLegend()),

        // ── Re-centre FAB ──
        Positioned(
          bottom: _selected != null ? 300 : 20,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'web_recenter',
            backgroundColor: _followingUser
                ? AppColors.neonCyan.withValues(alpha: 0.9)
                : AppColors.card,
            elevation: 4,
            onPressed: () {
              setState(() => _followingUser = true);
              final pos = userPosition;
              if (pos != null) {
                _mapCtrl.move(ll.LatLng(pos.latitude, pos.longitude), 17.5);
              }
            },
            child: Icon(
              _followingUser
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded,
              color: _followingUser ? Colors.black : AppColors.neonCyan,
              size: 20,
            ),
          ),
        ),

        // ── Challenge panel ──
        if (_selected != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildChallengePanel(_selected!,
                onClose: () => setState(() => _selected = null)),
          ),
      ],
    );
  }
}

// Small triangle tail under web marker
class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ── Dark neon map style (Android/iOS only) ────────────────
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a0e21"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#0c2340"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},
  {"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';

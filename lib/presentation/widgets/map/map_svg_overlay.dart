import 'dart:ui';

import '../../../core/constants/map_grid_config.dart';
import '../../../domain/entities/challenge.dart';

/// Builds an SVG string that is overlaid on top of the map image.
///
/// The SVG contains:
///  1. A subtle grid dividing the map into rows × cols
///  2. Grid cell labels (A1, B2, …)
///  3. Challenge marker circles (colour-coded)
///  4. Geofence rings around unattempted challenges
///  5. A pulsing live-location dot for the user
///
/// All positions are in the coordinate space of the rendered map
/// ([mapWidth] × [mapHeight]).
class MapSvgOverlay {
  MapSvgOverlay._();

  /// Build the complete SVG string for the overlay.
  static String build({
    required double mapWidth,
    required double mapHeight,
    required List<Challenge> challenges,
    required Set<String> completedIds,
    required Set<String> skippedIds,
    required Set<String> visibleIds,
    double? userLat,
    double? userLng,
    String? selectedChallengeId,
  }) {
    final buf = StringBuffer();

    buf.writeln('<svg xmlns="http://www.w3.org/2000/svg" '
        'width="$mapWidth" height="$mapHeight" '
        'viewBox="0 0 $mapWidth $mapHeight">');

    // ── Defs: reusable filters & animations ──
    buf.writeln('<defs>');
    // Glow filter for the user dot
    buf.writeln(
      '<filter id="glow" x="-50%" y="-50%" width="200%" height="200%">'
      '<feGaussianBlur stdDeviation="4" result="blur"/>'
      '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>'
      '</filter>',
    );
    // Pulse animation (used by user dot outer ring)
    buf.writeln(
      '<style>'
      '@keyframes pulse{0%{opacity:0.8;r:12}50%{opacity:0.2;r:22}100%{opacity:0.8;r:12}}'
      '.pulse{animation:pulse 2s ease-in-out infinite;}'
      '@keyframes markerPulse{0%{opacity:0.6;r:18}50%{opacity:0.15;r:26}100%{opacity:0.6;r:18}}'
      '.marker-pulse{animation:markerPulse 2.5s ease-in-out infinite;}'
      '</style>',
    );
    buf.writeln('</defs>');

    // ── 1. Grid lines ──
    _writeGrid(buf, mapWidth, mapHeight);

    // ── 2. Challenge geofence rings + markers ──
    for (final c in challenges) {
      if (!visibleIds.contains(c.id)) continue;
      final pos = MapGridConfig.geoToPixel(c.latitude, c.longitude, mapWidth, mapHeight);
      final isCompleted = completedIds.contains(c.id);
      final isSkipped = skippedIds.contains(c.id);
      final isSelected = c.id == selectedChallengeId;
      _writeChallenge(buf, pos, c, isCompleted, isSkipped, isSelected, userLat, userLng);
    }

    // ── 3. User live-location dot ──
    if (userLat != null && userLng != null) {
      _writeUserDot(buf, mapWidth, mapHeight, userLat, userLng);
    }

    buf.writeln('</svg>');
    return buf.toString();
  }

  // ────────────────────────────────────────────
  // Grid
  // ────────────────────────────────────────────
  static void _writeGrid(StringBuffer buf, double w, double h) {
    const cols = MapGridConfig.gridCols;
    const rows = MapGridConfig.gridRows;
    final cellW = w / cols;
    final cellH = h / rows;

    // Vertical lines
    for (int c = 1; c < cols; c++) {
      final x = c * cellW;
      buf.writeln(
        '<line x1="$x" y1="0" x2="$x" y2="$h" '
        'stroke="rgba(0,255,255,0.12)" stroke-width="0.5" stroke-dasharray="4,6"/>',
      );
    }
    // Horizontal lines
    for (int r = 1; r < rows; r++) {
      final y = r * cellH;
      buf.writeln(
        '<line x1="0" y1="$y" x2="$w" y2="$y" '
        'stroke="rgba(0,255,255,0.12)" stroke-width="0.5" stroke-dasharray="4,6"/>',
      );
    }
    // Cell labels (top-left of each cell, small & faint)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final label = MapGridConfig.gridLabel(c, r);
        final x = c * cellW + 3;
        final y = r * cellH + 11;
        buf.writeln(
          '<text x="$x" y="$y" '
          'font-family="monospace" font-size="8" '
          'fill="rgba(0,255,255,0.18)" font-weight="600">'
          '$label</text>',
        );
      }
    }
  }

  // ────────────────────────────────────────────
  // Challenge markers
  // ────────────────────────────────────────────
  static void _writeChallenge(
    StringBuffer buf,
    Offset pos,
    Challenge c,
    bool isCompleted,
    bool isSkipped,
    bool isSelected,
    double? userLat,
    double? userLng,
  ) {
    final x = pos.dx;
    final y = pos.dy;

    String fill;
    String stroke;
    if (isCompleted) {
      fill = 'rgba(57,255,20,0.85)'; // neonGreen
      stroke = 'rgba(57,255,20,0.5)';
    } else if (isSkipped) {
      fill = 'rgba(255,170,0,0.85)'; // neonOrange
      stroke = 'rgba(255,170,0,0.5)';
    } else {
      fill = 'rgba(0,255,255,0.85)'; // neonCyan
      stroke = 'rgba(0,255,255,0.5)';
    }

    final radius = isSelected ? 10.0 : 7.0;

    // Geofence ring (unattempted only)
    if (!isCompleted && !isSkipped) {
      // Convert geofence meters → pixels (approximate)
      // We draw a subtle ring at a fixed visual radius (not to-scale geofence).
      buf.writeln(
        '<circle cx="$x" cy="$y" r="18" '
        'fill="none" stroke="$stroke" stroke-width="1" '
        'stroke-dasharray="3,3" opacity="0.4"/>',
      );
      // Animated pulse ring for nearby challenges
      if (userLat != null && userLng != null) {
        buf.writeln(
          '<circle cx="$x" cy="$y" class="marker-pulse" '
          'fill="$stroke" stroke="none"/>',
        );
      }
    }

    // Main marker circle
    buf.writeln(
      '<circle cx="$x" cy="$y" r="$radius" '
      'fill="$fill" stroke="${isSelected ? 'white' : stroke}" '
      'stroke-width="${isSelected ? 2.5 : 1.2}"/>',
    );

    // Inner icon — check, skip arrow, or "?"
    if (isCompleted) {
      // Checkmark
      final s = radius * 0.65;
      buf.writeln(
        '<polyline points="${x - s * 0.5},$y ${x - s * 0.1},${y + s * 0.45} ${x + s * 0.6},${y - s * 0.4}" '
        'fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
      );
    } else if (isSkipped) {
      // "»" skip symbol
      buf.writeln(
        '<text x="$x" y="${y + 3}" text-anchor="middle" '
        'font-family="monospace" font-size="8" fill="white" font-weight="700">»</text>',
      );
    } else {
      buf.writeln(
        '<text x="$x" y="${y + 3}" text-anchor="middle" '
        'font-family="monospace" font-size="7" fill="white" font-weight="700">?</text>',
      );
    }
  }

  // ────────────────────────────────────────────
  // User live-location dot
  // ────────────────────────────────────────────
  static void _writeUserDot(
    StringBuffer buf,
    double mapWidth,
    double mapHeight,
    double lat,
    double lng,
  ) {
    final pos = MapGridConfig.geoToPixel(lat, lng, mapWidth, mapHeight);
    final x = pos.dx;
    final y = pos.dy;

    // Outer pulsing ring
    buf.writeln(
      '<circle cx="$x" cy="$y" r="12" class="pulse" '
      'fill="rgba(0,150,255,0.3)" stroke="none" filter="url(#glow)"/>',
    );
    // Accuracy halo
    buf.writeln(
      '<circle cx="$x" cy="$y" r="8" '
      'fill="rgba(0,150,255,0.15)" stroke="rgba(0,150,255,0.4)" stroke-width="1"/>',
    );
    // Core dot
    buf.writeln(
      '<circle cx="$x" cy="$y" r="5" '
      'fill="rgb(0,150,255)" stroke="white" stroke-width="2" filter="url(#glow)"/>',
    );
    // Direction arrow / label
    buf.writeln(
      '<text x="$x" y="${y + 2}" text-anchor="middle" '
      'font-family="sans-serif" font-size="5" fill="white" font-weight="700">⬤</text>',
    );
  }
}

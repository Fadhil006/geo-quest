import 'dart:ui';

/// Defines the mapping between real-world GPS coordinates and the
/// image-map pixel space.
///
/// The image (`assets/map/image.png`, 1117×605) covers a rectangular
/// GPS bounding box around the campus.  Any lat/lng within these bounds
/// can be projected onto image-relative (x, y) in [0, imageWidth] ×
/// [0, imageHeight].
class MapGridConfig {
  MapGridConfig._();

  // ── Image dimensions (native) ──────────────────
  static const double imageWidth = 1117.0;
  static const double imageHeight = 605.0;

  // ── GPS bounding box that the image covers ─────
  // Corners: top-left = (maxLat, minLng), bottom-right = (minLat, maxLng)
  // Centered around (9.754914, 76.649674) with ~600 m extent (IIIT Kottayam, Valavoor)
  static const double minLat = 9.7513; // bottom edge
  static const double maxLat = 9.7585; // top edge
  static const double minLng = 76.6457; // left edge
  static const double maxLng = 76.6537; // right edge

  // ── Grid settings ──────────────────────────────
  static const int gridRows = 8;
  static const int gridCols = 12;

  // ── Coordinate conversion ──────────────────────

  /// Convert GPS (lat, lng) → normalised (0..1, 0..1) within the bounding box.
  /// x grows left→right (longitude), y grows top→bottom (latitude inverted).
  static Offset geoToNorm(double lat, double lng) {
    final nx = (lng - minLng) / (maxLng - minLng);
    // Lat is inverted: higher lat = top = smaller y
    final ny = 1.0 - (lat - minLat) / (maxLat - minLat);
    return Offset(nx.clamp(0.0, 1.0), ny.clamp(0.0, 1.0));
  }

  /// Convert GPS (lat, lng) → pixel position on the rendered map of size
  /// [mapWidth] × [mapHeight].
  static Offset geoToPixel(double lat, double lng, double mapWidth, double mapHeight) {
    final norm = geoToNorm(lat, lng);
    return Offset(norm.dx * mapWidth, norm.dy * mapHeight);
  }

  /// Which grid cell (col, row) a GPS coordinate falls into.
  static (int col, int row) geoToGrid(double lat, double lng) {
    final norm = geoToNorm(lat, lng);
    final col = (norm.dx * gridCols).floor().clamp(0, gridCols - 1);
    final row = (norm.dy * gridRows).floor().clamp(0, gridRows - 1);
    return (col, row);
  }

  /// Grid cell label, e.g. "C4" (column letter + row number).
  static String gridLabel(int col, int row) {
    final letter = String.fromCharCode(65 + col); // A, B, C, …
    return '$letter${row + 1}';
  }
}

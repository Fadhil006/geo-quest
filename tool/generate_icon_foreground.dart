import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Generates a padded adaptive icon foreground from the source icon.
/// Adaptive icons use a 108dp grid with a 72dp safe zone (66.7%).
/// The foreground needs ~17% padding on each side.
void main() {
  final sourceFile = File('assets/images/app_icon.png');
  if (!sourceFile.existsSync()) {
    print('❌ assets/images/app_icon.png not found');
    exit(1);
  }

  final sourceBytes = sourceFile.readAsBytesSync();
  final source = img.decodePng(sourceBytes);
  if (source == null) {
    print('❌ Failed to decode icon');
    exit(1);
  }

  // Create a 1024x1024 canvas (standard adaptive icon size)
  const canvasSize = 1024;
  // The icon should occupy ~66% of the canvas (safe zone)
  final iconSize = (canvasSize * 0.60).round();
  final offset = ((canvasSize - iconSize) / 2).round();

  // Create transparent canvas
  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  // Fill with transparent
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // Resize source icon
  final resized = img.copyResize(source, width: iconSize, height: iconSize, interpolation: img.Interpolation.linear);

  // Paste centered
  img.compositeImage(canvas, resized, dstX: offset, dstY: offset);

  // Save
  final output = File('assets/images/app_icon_foreground.png');
  output.writeAsBytesSync(img.encodePng(canvas));
  print('✅ Generated adaptive icon foreground: ${output.path}');
  print('   Canvas: ${canvasSize}x${canvasSize}, Icon: ${iconSize}x${iconSize}, Offset: $offset');
}


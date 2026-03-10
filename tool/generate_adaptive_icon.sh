#!/bin/bash
# generate_adaptive_icon.sh
# Creates a padded foreground image for Android adaptive icons.
# The original icon gets placed on a transparent 1024x1024 canvas
# at 60% size, centered — giving proper breathing room.

SRC="assets/images/app_icon.png"
DST="assets/images/app_icon_foreground.png"

if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Installing..."
    sudo apt install -y imagemagick
fi

# Create 1024x1024 transparent canvas, resize icon to 60% and center it
convert "$SRC" \
    -resize 614x614 \
    -gravity center \
    -background none \
    -extent 1024x1024 \
    "$DST"

echo "✅ Generated: $DST"
echo "Now run:"
echo "  cd /home/aritra/Programming/geo_quest"
echo "  dart run flutter_launcher_icons"
echo "  flutter run"


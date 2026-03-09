#!/bin/bash
# find_java.sh — Finds Flutter's bundled Java and sets it in gradle.properties
# Run this once: bash find_java.sh

FLUTTER_SDK="/home/aritra/development/flutter"
GRADLE_PROPS="/home/aritra/Programming/geo_quest/android/gradle.properties"

# Possible Java locations within Flutter SDK
CANDIDATES=(
    "$FLUTTER_SDK/jbr"
    "$FLUTTER_SDK/bin/cache/artifacts/java"
    "$FLUTTER_SDK/bin/cache/artifacts/java/openjdk"
)

# Check each candidate
for dir in "${CANDIDATES[@]}"; do
    # Check subdirectories too (e.g., java/openjdk/jdk-21.0.x)
    if [ -d "$dir" ]; then
        JAVA_BIN=$(find "$dir" -name "java" -path "*/bin/java" -type f 2>/dev/null | head -1)
        if [ -n "$JAVA_BIN" ]; then
            JAVA_HOME=$(dirname $(dirname "$JAVA_BIN"))
            echo "Found Java at: $JAVA_HOME"
            echo "$($JAVA_HOME/bin/java -version 2>&1 | head -1)"

            # Remove old java.home line if present
            sed -i '/org.gradle.java.home/d' "$GRADLE_PROPS"
            # Add new one
            echo "org.gradle.java.home=$JAVA_HOME" >> "$GRADLE_PROPS"
            echo ""
            echo "✅ Set org.gradle.java.home=$JAVA_HOME in gradle.properties"
            echo "Now run: cd /home/aritra/Programming/geo_quest && flutter run"
            exit 0
        fi
    fi
done

# Fallback: check system Java
SYSTEM_JAVA=$(which java 2>/dev/null)
if [ -n "$SYSTEM_JAVA" ]; then
    REAL_JAVA=$(readlink -f "$SYSTEM_JAVA")
    JAVA_HOME=$(dirname $(dirname "$REAL_JAVA"))
    echo "Found system Java at: $JAVA_HOME"
    echo "$($JAVA_HOME/bin/java -version 2>&1 | head -1)"

    sed -i '/org.gradle.java.home/d' "$GRADLE_PROPS"
    echo "org.gradle.java.home=$JAVA_HOME" >> "$GRADLE_PROPS"
    echo ""
    echo "✅ Set org.gradle.java.home=$JAVA_HOME in gradle.properties"
    echo "Now run: cd /home/aritra/Programming/geo_quest && flutter run"
    exit 0
fi

echo "❌ Could not find a suitable Java installation."
echo "Run 'flutter doctor -v' and look for the Java path."
echo "Then manually add to $GRADLE_PROPS:"
echo "org.gradle.java.home=/path/to/java/home"
exit 1


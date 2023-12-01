#!/bin/bash

#######################################
# Flutter Version Increment and Build Script
#######################################

# Script Usage:
#   - This script increments the version number in the Flutter project's pubspec.yaml file.
#   - It provides options to increment the MAJOR, MINOR, or PATCH version components.
#   - Release builds for iOS and Android can be disabled using the --no-build option.

# Usage:
#   ./build.sh [OPTIONS]

# Available Options:
#   --major          Increment the MAJOR version component.
#   --minor          Increment the MINOR version component.
#   --patch          Increment the PATCH version component.
#   --no-build       Disable release builds for iOS and Android.

# Function to increment version components in pubspec.yaml
increment_flutter_version() {
    PUBSPEC_FILE="pubspec.yaml"
    CURRENT_VERSION=$(awk '/version:/ {print $2}' "$PUBSPEC_FILE" | tr -d "'")
    MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
    MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
    PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3 | cut -d+ -f1)
    BUILD=$(echo "$CURRENT_VERSION" | cut -d+ -f2)

    if [ "$1" == "--major" ]; then
        NEW_VERSION="$((MAJOR + 1)).0.0+0"
    elif [ "$1" == "--minor" ]; then
        NEW_VERSION="$MAJOR.$((MINOR + 1)).0+0"
    elif [ "$1" == "--patch" ]; then
        NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))+0"
    else
        NEW_VERSION="$MAJOR.$MINOR.$PATCH+$((BUILD + 1))"
    fi

    awk -v current_version="$CURRENT_VERSION" -v new_version="$NEW_VERSION" \
    '$1 == "version:" && $2 == current_version { $2 = new_version } { print }' \
    "$PUBSPEC_FILE" > temp && mv temp "$PUBSPEC_FILE"

    echo "Flutter version incremented to $NEW_VERSION"
}

# Function to execute Flutter release builds for iOS and Android
execute_flutter_release_builds() {
    flutter build ipa --release
    flutter build appbundle --release

    # Ensure release directory exists; create if not present
    mkdir -p ./release

    # Copy IPA file to release directory
    cp build/ios/ipa/*.ipa ./release

    # Copy App Bundle file to release directory
    cp build/app/outputs/bundle/release/*.aab ./release
}

# Increment version based on provided options
if [ "$1" == "--major" ] || [ "$1" == "--minor" ] || [ "$1" == "--patch" ]; then
    increment_flutter_version "$1"
elif [ "$2" == "--major" ] || [ "$2" == "--minor" ] || [ "$2" == "--patch" ]; then
    increment_flutter_version "$2"
else
    increment_flutter_version
fi

# Check for --no-build option to disable release builds
if [[ "$1" == "--no-build" || "$2" == "--no-build" ]]; then
    echo "Release builds disabled."
else
    execute_flutter_release_builds
fi

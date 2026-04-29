#!/bin/bash

# Methane Mayhem - Versioning and Packaging Script
# This script generates versioned build inputs and package artifacts.

set -e

# Get the version from config.json
VERSION=$(grep -o '"version": "[^"]*' config.json | grep -o '[^"]*$')
echo "🎮 Packaging Methane Mayhem v$VERSION"

# Verify required tools
if ! command -v c1541 &> /dev/null; then
    echo "❌ Error: c1541 (from VICE) is required but not found"
    exit 1
fi

# Build the C64 project with version injection
echo "🔨 Building C64 project..."
bash "c64/build-versioned.sh"

PRG_FILE="c64/build/Methane Mayhem.prg"

# Create d64 image from the PRG file
echo "💾 Creating d64 image..."
D64_FILE="c64/build/Methane Mayhem.d64"

if [ ! -f "$PRG_FILE" ]; then
    echo "❌ Error: PRG file not found at $PRG_FILE"
    exit 1
fi

# Use lowercase here so c1541 writes a PETSCII name that BASIC can resolve
# with LOAD "METHANE MAYHEM",8,1 in the default C64 character mode.
c1541 -format "methane,00" d64 "$D64_FILE" -write "$PRG_FILE" "methane"

# Create the zip package using PowerShell
echo "📦 Creating zip package..."
ZIP_FILE="c64/build/methane-mayhem-v${VERSION}.zip"

# Remove old zip if it exists
rm -f "$ZIP_FILE"

# Use PowerShell to create zip (works on Windows)
powershell -Command "Compress-Archive -Path 'c64/build/Methane Mayhem.prg', 'c64/build/Methane Mayhem.d64', 'readme.txt' -DestinationPath '$ZIP_FILE' -Force"

echo ""
echo "✅ Packaging complete!"
echo "📦 Created: $ZIP_FILE"
echo "   - Methane Mayhem.prg"
echo "   - Methane Mayhem.d64"
echo "   - readme.txt"

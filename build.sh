#!/bin/bash

# Build script for botcczz tweak
# This script compiles the tweak into a dylib file

echo "Building botcczz..."

# Check if THEOS is installed
if [ -z "$THEOS" ]; then
    echo "ERROR: THEOS environment variable is not set!"
    echo "Please install Theos first: https://theos.dev/docs/installation"
    exit 1
fi

# Clean previous build
make clean

# Build the tweak
make package

# Copy the dylib to output directory
if [ -f ".theos/obj/debug/botcczz.dylib" ]; then
    cp .theos/obj/debug/botcczz.dylib ./botcczz.dylib
    echo "✓ Build successful! Output: botcczz.dylib"
else
    echo "✗ Build failed!"
    exit 1
fi

echo ""
echo "To inject this dylib into the IPA:"
echo "1. Use inject_dylib.py (in this folder) or insert_dylib"
echo "2. Command example:"
echo "   python3 inject_dylib.py --weak @executable_path/botcczz.dylib 'Payload/Soccer Champs.app/Soccer Champs'"
echo ""
echo "3. Copy botcczz.dylib to 'Payload/Soccer Champs.app/'"
echo "4. Repackage the IPA"
echo "5. Sign with your certificate"

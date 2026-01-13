#!/bin/bash
# Build script for ascii_center workspace
# Compiles shared UI types first, then builds the Vite bundle
#
# Usage:
#   ./build.sh           - Build only (no deployment)
#   ./build.sh --deploy  - Build and deploy to Home Assistant

set -e  # Exit on error

DEPLOY=0
if [ "$1" = "--deploy" ]; then
    DEPLOY=1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "\033[0;36mBuilding ascii_center workspace...\033[0m"
echo ""

# Step 1: Compile shared UI TypeScript declarations
echo -e "\033[0;33mStep 1: Compiling @ascii/shared-ui types...\033[0m"
cd "$SCRIPT_DIR/packages/ascii_shared_ui"
pnpm exec tsc -p tsconfig.json 2>&1 || {
    echo -e "\033[0;31mFailed to compile shared-ui types\033[0m"
    exit 1
}

echo -e "\033[0;32m[OK] Shared UI types compiled\033[0m"
echo ""

# Step 2: Build ascii_center Vite bundle
echo -e "\033[0;33mStep 2: Building @ascii/ascii-center bundle...\033[0m"
cd "$SCRIPT_DIR/packages/ascii_center"
pnpm build || {
    echo -e "\033[0;31mFailed to build ascii-center\033[0m"
    exit 1
}

echo -e "\033[0;32m[OK] Ascii Center built\033[0m"
echo ""

# Return to workspace root
cd "$SCRIPT_DIR"

echo -e "\033[0;32m=== Build completed successfully! ===\033[0m"
echo ""

# Step 3: Deploy to Home Assistant (if requested)
if [ "$DEPLOY" = "1" ]; then
    echo -e "\033[0;33mStep 3: Deploying to Home Assistant...\033[0m"
    SOURCE_DIR="$SCRIPT_DIR/packages/ascii_center/dist"
    TARGET_DIR="//192.168.1.4/config/www/ascii"
    
    if [ -d "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
        cp -r "$SOURCE_DIR"/* "$TARGET_DIR"/ 2>/dev/null && {
            echo -e "\033[0;32m[OK] Files deployed to $TARGET_DIR\033[0m"
            echo -e "\033[0;90m    - ascii-center.js (HA bundle)\033[0m"
            echo -e "\033[0;90m    - index.html (dev preview)\033[0m"
            echo -e "\033[0;90m    - assets/ (dev assets)\033[0m"
        } || {
            echo -e "\033[0;33m[SKIP] Could not deploy to Home Assistant\033[0m"
            echo -e "\033[0;33m       Please manually copy: packages/ascii_center/dist/* -> $TARGET_DIR\033[0m"
        }
    else
        echo -e "\033[0;33m[SKIP] Network path not accessible: $TARGET_DIR\033[0m"
        echo -e "\033[0;33m       Please manually copy: packages/ascii_center/dist/* -> $TARGET_DIR\033[0m"
    fi
    
    echo ""
    echo -e "\033[0;36mDone! Remember to bump cache version (?v=X) in HA panel loader.\033[0m"
else
    echo -e "\033[0;36mTo deploy, copy: packages/ascii_center/dist/* -> //192.168.1.4/config/www/ascii\033[0m"
    echo -e "\033[0;36mOr run: ./build.sh --deploy\033[0m"
fi

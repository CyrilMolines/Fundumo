#!/bin/bash
# Build configuration script for iOS
# Similar to EAS build configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Fundumo iOS Build Configuration${NC}"
echo ""

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -n 1)${NC}"

# Check Xcode installation
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Xcode found: $(xcodebuild -version | head -n 1)${NC}"

# Navigate to project directory
cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)

echo ""
echo -e "${YELLOW}📦 Installing Flutter dependencies...${NC}"
flutter pub get

echo ""
echo -e "${YELLOW}📦 Installing CocoaPods dependencies...${NC}"
cd ios
pod install

echo ""
echo -e "${YELLOW}🔧 Configuring build settings...${NC}"

# Set build configuration based on environment
BUILD_TYPE=${1:-release}

case $BUILD_TYPE in
  debug)
    BUILD_CONFIG="Debug"
    FLUTTER_BUILD_ARGS="--debug"
    ;;
  profile)
    BUILD_CONFIG="Profile"
    FLUTTER_BUILD_ARGS="--profile"
    ;;
  release)
    BUILD_CONFIG="Release"
    FLUTTER_BUILD_ARGS="--release"
    ;;
  *)
    echo -e "${RED}❌ Invalid build type: $BUILD_TYPE${NC}"
    echo "Usage: ./build-config.sh [debug|profile|release]"
    exit 1
    ;;
esac

echo -e "${GREEN}✅ Build type: $BUILD_CONFIG${NC}"

# Set environment variables for Supabase and Sentry
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${YELLOW}⚠️  SUPABASE_URL not set, using default${NC}"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${YELLOW}⚠️  SUPABASE_ANON_KEY not set, using default${NC}"
fi

if [ -z "$SENTRY_DSN" ]; then
    echo -e "${YELLOW}⚠️  SENTRY_DSN not set (optional)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuration complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Run: flutter build ios $FLUTTER_BUILD_ARGS"
echo "  2. Or use Fastlane: cd ios && fastlane beta"
echo "  3. Or use Xcode: open ios/Runner.xcworkspace"


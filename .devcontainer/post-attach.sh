#!/bin/bash
set -e

echo "🔧 Setting up Flutter project..."

# Get Flutter dependencies
flutter pub get

# Clean and prepare the project
flutter clean
flutter pub get

# Pre-compile for web to speed up first run
echo "🌐 Pre-compiling for web..."
flutter build web --debug || echo "Web build failed, but continuing..."

# Check if Android emulator is available and start virtual display
if command -v Xvfb &> /dev/null; then
    echo "🖥️  Starting virtual display for web debugging..."
    Xvfb :99 -screen 0 1024x768x24 &
fi

# Show Flutter configuration
echo "📋 Flutter configuration:"
flutter doctor -v

echo "✅ Project setup complete!"
echo "🚀 You can now run:"
echo "   - flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"
echo "   - flutter run -d chrome (for web debugging)"
echo "   - flutter run (for Android if emulator is available)"

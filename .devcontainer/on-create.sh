#!/bin/bash
set -e

# Disable analytics
dart --disable-analytics
flutter --disable-analytics

# Enable web and configure Flutter for Codespaces
flutter config --enable-web
flutter config --no-enable-linux-desktop
flutter config --no-enable-macos-desktop
flutter config --no-enable-windows-desktop

# Set Chrome executable for web debugging
flutter config --web-browser-flag "--disable-web-security"
flutter config --web-browser-flag "--disable-features=VizDisplayCompositor"

# Run flutter doctor to check setup
flutter doctor

# Configure bashrc
echo '' >> $HOME/.bashrc
echo 'eval -- "$(/usr/local/bin/starship init bash --print-full-init)"' >> $HOME/.bashrc
echo '' >> $HOME/.bashrc
echo 'source ~/.bashrc.1' >> $HOME/.bashrc

# Set up environment for web development
echo 'export CHROME_EXECUTABLE=/usr/bin/chromium' >> $HOME/.bashrc
echo 'export DISPLAY=:99' >> $HOME/.bashrc

# Start virtual display for web debugging
export TERM=xterm-256color

# Run onboarding if task command exists
if command -v task &> /dev/null; then
    task onboarding | while IFS= read -r line; do
      # Loop over each character in the current line.
      for (( i=0; i<${#line}; i++ )); do
        echo -n "${line:$i:1}"
        sleep 0.003
      done
      # Print a newline after finishing the line.
      echo
    done
fi

echo "✅ Flutter development environment configured for Android and Web debugging!"
echo "🌐 Web debugging is enabled with Chromium"
echo "📱 Android development tools are ready"

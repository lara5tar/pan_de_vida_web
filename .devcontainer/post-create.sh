#!/bin/bash
set -e

echo "🔧 Configurando proyecto Flutter..."

# Asegurar que las variables de entorno están disponibles
export PATH="$PATH:/home/vscode/flutter/bin:/home/vscode/android-sdk/cmdline-tools/latest/bin:/home/vscode/android-sdk/platform-tools"
export ANDROID_SDK_ROOT="/home/vscode/android-sdk"
export CHROME_EXECUTABLE="/usr/bin/chromium-browser"

# Navegar al directorio del proyecto
cd /workspaces/$(basename "$PWD")

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Iniciar display virtual para web
echo "🖥️ Iniciando display virtual..."
Xvfb :99 -screen 0 1024x768x24 &

# Verificar que todo esté funcionando
echo "🔍 Verificando configuración..."
flutter doctor

# Mostrar dispositivos disponibles
echo "📱 Dispositivos disponibles:"
flutter devices

echo "✅ ¡Proyecto listo!"
echo ""
echo "🌐 Para debugging web, ejecuta:"
echo "   flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"
echo ""
echo "🤖 Para debugging con Chrome:"
echo "   flutter run -d chrome --web-port 3000"
echo ""
echo "📋 El puerto 3000 será automáticamente forwarded por Codespaces"
#!/bin/bash
set -e

echo "🚀 Configurando Flutter para Codespaces..."

# Instalar dependencias básicas
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip wget openjdk-11-jdk

# Instalar Flutter (versión estable más reciente)
cd /home/vscode
if [ ! -d "flutter" ]; then
    echo "📱 Descargando Flutter stable..."
    wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz
    tar xf flutter.tar.xz
    rm flutter.tar.xz
fi

# Configurar PATH
echo 'export PATH="$PATH:/home/vscode/flutter/bin"' >> ~/.bashrc
export PATH="$PATH:/home/vscode/flutter/bin"

# Configurar Flutter
flutter config --no-analytics
flutter config --enable-web

# Verificar versión de Dart
echo "📋 Verificando versión de Dart..."
dart --version

# Verificar que Flutter esté funcionando
flutter doctor

# Instalar dependencias del proyecto
cd /workspaces/pan_de_vida_web
echo "📦 Instalando dependencias del proyecto..."
flutter pub get

echo "✅ Flutter configurado correctamente!"
echo "🌐 Para ejecutar en web: flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"
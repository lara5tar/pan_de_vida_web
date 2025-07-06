#!/bin/bash
set -e

echo "🚀 Configurando Flutter para GitHub Codespaces..."

# Actualizar paquetes del sistema
sudo apt-get update

# Instalar dependencias necesarias
sudo apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    chromium-browser \
    xvfb

# Crear directorios
mkdir -p /home/vscode/android-sdk
mkdir -p /home/vscode/flutter

# Descargar e instalar Flutter
echo "📱 Instalando Flutter..."
cd /home/vscode
wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter.tar.xz
rm flutter.tar.xz

# Descargar e instalar Android SDK
echo "🤖 Instalando Android SDK..."
cd /home/vscode/android-sdk
wget -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip cmdline-tools.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/cmdline-tools/* cmdline-tools/latest/
rm -rf cmdline-tools.zip

# Configurar PATH
echo 'export PATH="$PATH:/home/vscode/flutter/bin:/home/vscode/android-sdk/cmdline-tools/latest/bin:/home/vscode/android-sdk/platform-tools"' >> /home/vscode/.bashrc
echo 'export ANDROID_SDK_ROOT="/home/vscode/android-sdk"' >> /home/vscode/.bashrc
echo 'export CHROME_EXECUTABLE="/usr/bin/chromium-browser"' >> /home/vscode/.bashrc

# Aplicar variables de entorno
export PATH="$PATH:/home/vscode/flutter/bin:/home/vscode/android-sdk/cmdline-tools/latest/bin:/home/vscode/android-sdk/platform-tools"
export ANDROID_SDK_ROOT="/home/vscode/android-sdk"
export CHROME_EXECUTABLE="/usr/bin/chromium-browser"

# Aceptar licencias de Android
echo "📋 Aceptando licencias de Android..."
yes | /home/vscode/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses

# Instalar componentes de Android
echo "🛠️ Instalando componentes de Android..."
/home/vscode/android-sdk/cmdline-tools/latest/bin/sdkmanager "build-tools;34.0.0" "platforms;android-34" "platform-tools"

# Configurar Flutter
echo "⚙️ Configurando Flutter..."
/home/vscode/flutter/bin/flutter config --no-analytics
/home/vscode/flutter/bin/flutter config --enable-web
/home/vscode/flutter/bin/flutter precache

# Verificar instalación
echo "✅ Verificando instalación..."
/home/vscode/flutter/bin/flutter doctor

echo "🎉 ¡Configuración completada! Flutter está listo para Codespaces."

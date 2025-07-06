# Flutter Development in GitHub Codespaces

## 🚀 Configuración para Debugging en Android y Web

Esta configuración de devcontainer está optimizada para desarrollo Flutter en GitHub Codespaces, con soporte completo para debugging en **Android** y **Web**, especialmente útil para trabajar desde tablets.

## 📱 Cómo usar en una Tablet

### 1. Abrir en Codespaces
- Ve a tu repositorio en GitHub
- Haz clic en "Code" → "Codespaces" → "Create codespace"
- El contenedor se configurará automáticamente

### 2. Debugging Web (Recomendado para tablets)
```bash
# Método 1: Usar el servidor web (mejor para tablets)
flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

# Método 2: Usar Chrome headless
flutter run -d chrome --web-port 3000
```

### 3. Acceder desde tu tablet
- Una vez que la app esté corriendo, Codespaces te mostrará una notificación de puerto disponible
- Haz clic en "Open in Browser" o ve a la pestaña "Ports"
- La URL será algo como: `https://xxx-3000.app.github.dev`
- Abre esta URL en el navegador de tu tablet

## 🎯 Configuraciones de Launch Disponibles

En VS Code, ve a "Run and Debug" (Ctrl+Shift+D) y selecciona:

- **Flutter Web (Debug)**: Para debugging web con servidor local
- **Flutter Web (Chrome)**: Para debugging web con Chrome
- **Flutter Android**: Para debugging Android (si tienes emulador)
- **Flutter Web (Release)**: Para versión optimizada
- **Flutter Web (Profile)**: Para análisis de rendimiento

## 🔧 Comandos Útiles

```bash
# Verificar configuración
flutter doctor

# Limpiar y reconstruir
flutter clean && flutter pub get

# Ejecutar en web con hot reload
flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

# Ver dispositivos disponibles
flutter devices

# Construir para web
flutter build web
```

## 🌐 Características Incluidas

- ✅ Flutter SDK con soporte completo para web
- ✅ Android SDK con herramientas de desarrollo
- ✅ Chromium para debugging web
- ✅ Configuración automática de puertos
- ✅ Extensiones de VS Code preinstaladas
- ✅ Hot reload habilitado
- ✅ Formateo automático de código

## 📋 Puertos Configurados

- **3000**: Puerto principal para Flutter web
- **8080**: Puerto alternativo
- **5000**: Puerto por defecto de Flutter
- **8000**: Puerto adicional

## 💡 Tips para Tablets

1. **Usa el modo web**: Es más eficiente que tratar de emular Android
2. **Aprovecha el hot reload**: Los cambios se reflejan instantáneamente
3. **Usa la vista responsive**: Puedes simular diferentes tamaños de pantalla
4. **Debugging remoto**: Puedes depurar desde la tablet mientras el código está en Codespaces

## 🔥 Hot Reload Automático

El hot reload está configurado para activarse automáticamente cuando guardas archivos. Esto significa que verás los cambios en tiempo real en tu tablet mientras editas el código en Codespaces.

## 🆘 Solución de Problemas

Si no puedes acceder a la aplicación web:
1. Verifica que el puerto 3000 esté forwarded
2. Asegúrate de usar `--web-hostname 0.0.0.0`
3. Revisa la pestaña "Ports" en Codespaces
4. Intenta con otro puerto si es necesario

## 🎨 Desarrollo Responsive

Para optimizar tu app para tablets, puedes usar:
```dart
// Detectar si es tablet
bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width > 768;
}

// Usar layouts adaptativos
Widget build(BuildContext context) {
  return isTablet(context) 
    ? TabletLayout() 
    : PhoneLayout();
}
```

¡Listo para desarrollar desde cualquier lugar! 🚀
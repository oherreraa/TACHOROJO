# TachoRojo · Android (APK)

Envoltorio nativo mínimo (WebView) que empaqueta la app web de `../frontend`. Sin Capacitor ni dependencias de terceros salvo `androidx.webkit`.

## Compilar el APK de prueba

Requisitos: JDK 17 o superior y Android SDK (plataforma 34, build-tools 34).

```bash
cd android
echo "sdk.dir=/ruta/al/Android/Sdk" > local.properties
gradle assembleDebug          # o ./gradlew si se genera el wrapper
# resultado: app/build/outputs/apk/debug/app-debug.apk
```

`copyWeb` copia `../frontend` dentro del APK en cada compilación. El APK de depuración se firma con la clave de depuración: sirve para probar, no para Play Store.

## Instalar
Copia el APK al celular y ábrelo (permite "instalar apps de orígenes desconocidos"), o `adb install app-debug.apk`.

## Notas
- La foto usa la cámara del sistema (`ACTION_IMAGE_CAPTURE`) o la galería; no pide permiso de cámara.
- Modo demo por defecto (sin IA). Para conectar n8n, pon `n8nBaseUrl` en `frontend/js/config.js` y recompila.
- El dictado por voz no funciona dentro de WebView; el botón solo aparece si el motor lo soporta.
- Para Play Store hay que firmar un `release` con clave propia y generar un AAB (`bundleRelease`).

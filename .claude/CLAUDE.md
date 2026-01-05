# Merge Town - Contexto para Claude

## Resumen del proyecto
Juego mobile de merge buildings desarrollado en Godot 4.2. El jugador combina edificios iguales para crear edificios de nivel superior que generan más monedas.

## Estado actual
Ver `PROGRESS.md` para estado detallado y historial de versiones.
- **Versión actual**: v1.0.4
- **Estado**: Funcional en local y Android

## Estructura clave
```
scripts/
├── autoload/
│   ├── game_manager.gd    # Estado global, edificios, monedas
│   ├── save_manager.gd    # Persistencia (juego, audio, quests)
│   ├── quest_manager.gd   # Sistema de misiones
│   └── audio_manager.gd   # Música y efectos procedurales
├── effects/
│   └── particle_effects.gd
├── ui/
│   ├── quest_panel.gd
│   └── settings_panel.gd
├── building.gd
├── game_grid.gd
└── ui_manager.gd
```

## Comandos frecuentes

### Godot
```bash
# Ejecutar juego en local
/home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --path .

# Test headless (sin ventana)
timeout 5 /home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --path . --headless
```

### Android (ADB)
```bash
# Ver dispositivos/emuladores
/home/os_uis/Android/Sdk/platform-tools/adb devices

# Instalar APK
/home/os_uis/Android/Sdk/platform-tools/adb install -r /tmp/merge-town.apk

# Lanzar app
/home/os_uis/Android/Sdk/platform-tools/adb shell monkey -p com.mergetowngame.app -c android.intent.category.LAUNCHER 1

# Ver logs de Godot
/home/os_uis/Android/Sdk/platform-tools/adb logcat -d | grep -i godot

# Cerrar app
/home/os_uis/Android/Sdk/platform-tools/adb shell am force-stop com.mergetowngame.app

# Cerrar emulador
/home/os_uis/Android/Sdk/platform-tools/adb emu kill

# Screenshot
/home/os_uis/Android/Sdk/platform-tools/adb exec-out screencap -p > /tmp/screenshot.png
```

### Git y Releases
```bash
# Crear release
gh release create vX.X.X --title "Merge Town vX.X.X" --notes "changelog..."

# Descargar APK de release
gh release download vX.X.X --pattern "*.apk" -O /tmp/merge-town.apk
```

## Convenciones
- Commits sin "Co-Authored-By" ni "Generated with Claude"
- Versión en `scripts/ui/settings_panel.gd` (APP_VERSION)
- Actualizar PROGRESS.md con cada release

## Autonomía
El agente puede ejecutar sin confirmación:
- Comandos git (status, add, commit, push, diff, log)
- Godot para testing
- ADB para deploy y testing en Android
- gh para releases
- Edición de archivos en el proyecto

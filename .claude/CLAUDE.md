# Merge Town - Contexto para Claude

## Resumen del proyecto
Juego mobile de merge buildings desarrollado en Godot 4.2. El jugador combina edificios iguales para crear edificios de nivel superior que generan más monedas.

## Estado actual
Ver `PROGRESS.md` para estado detallado y historial de versiones.
- **Package**: com.mergetowngame.app
- **Estado**: Publicado en Google Play (pruebas internas)

## Estructura clave
```
scripts/
├── autoload/
│   ├── game_manager.gd    # Estado global, edificios, monedas
│   ├── save_manager.gd    # Persistencia (juego, audio, quests)
│   ├── quest_manager.gd   # Sistema de misiones
│   ├── audio_manager.gd   # Música y efectos procedurales
│   ├── shop_manager.gd    # Sistema de tienda
│   ├── daily_reward_manager.gd # Recompensas diarias
│   ├── iap_manager.gd     # In-App Purchases
│   └── ads_manager.gd     # Publicidad (AdMob)
├── effects/
│   └── particle_effects.gd
├── ui/
│   ├── quest_panel.gd
│   ├── settings_panel.gd
│   ├── shop_panel.gd
│   ├── daily_reward_panel.gd
│   └── iap_panel.gd
├── building.gd
├── game_grid.gd
└── ui_manager.gd
```

## Publicar en Google Play

### Prerrequisitos
- Archivo `google-play-credentials.json` en la raíz del proyecto (cuenta de servicio)
- AAB generado en `builds/merge-town-release.aab`

### Generar AAB
1. Abrir Godot con UI:
   ```bash
   /home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --editor --path /home/os_uis/projects/mobile-civ-merging-game
   ```
2. Proyecto → Exportar → Android Release
3. **IMPORTANTE**: Incrementar Version Code (ver último en Google Play Console)
4. Exportar como AAB a `builds/merge-town-release.aab`

### Publicar AAB
```bash
# Publicar a pruebas internas
python3 publish_to_play.py internal

# Publicar a producción (pide confirmación)
python3 publish_to_play.py production
```

### Tracks disponibles
- `internal` - Pruebas internas (status: draft, requiere promoción manual en consola)
- `alpha` - Alpha testing
- `beta` - Beta testing
- `production` - Producción pública

### Después de publicar
- La app está en estado "draft" hasta que se publique a producción
- Para pruebas internas: ir a Google Play Console y promover el draft manualmente
- URL: https://play.google.com/console

## Comandos frecuentes

### Godot
```bash
# Ejecutar juego en local (con UI)
/home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --editor --path .

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
# Crear release en GitHub
gh release create vX.X.X --title "Merge Town vX.X.X" --notes "changelog..."

# Descargar APK de release
gh release download vX.X.X --pattern "*.apk" -O /tmp/merge-town.apk
```

## Archivos sensibles (NO SUBIR A GIT)
- `release.keystore` - Keystore para firmar
- `keystore-credentials.txt` - Credenciales del keystore
- `google-play-credentials.json` - Cuenta de servicio para publicación

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
- `python3 publish_to_play.py` para publicar a Google Play
- Edición de archivos en el proyecto

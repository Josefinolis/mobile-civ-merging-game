# Merge Town - Progress Log

## Estado actual: FUNCIONAL

El juego funciona correctamente en local y la APK se genera via GitHub Actions.

## Repositorio
- **URL**: https://github.com/Josefinolis/mobile-civ-merging-game
- **Última versión**: v1.0.4
- **Release**: https://github.com/Josefinolis/mobile-civ-merging-game/releases

## Lo que está implementado

### Core Game
- [x] Estructura del proyecto Godot 4.2
- [x] Sistema de grid 5x7 para edificios
- [x] Mecánica de drag & drop
- [x] Lógica de merge (fusión de edificios iguales)
- [x] 10 niveles de edificios (Tent → Wonder)
- [x] Sistema de energía (10 max, regenera cada 30s)
- [x] Generación pasiva de monedas
- [x] Auto-guardado al cerrar
- [x] Ganancias offline (50% eficiencia, max 8h)

### UI y Visual
- [x] UI con stats (monedas, energía, ingresos/s)
- [x] Edificios con gráficos detallados (techo, ventanas, puerta, chimenea)
- [x] Efectos de partículas (merge, spawn, coins)
- [x] Animaciones juicy (spawn, merge, pickup, drop)
- [x] Panel de quests colapsable
- [x] Panel de settings modal

### Audio
- [x] Efectos de sonido procedurales
- [x] Música de fondo ambiental
- [x] Controles de volumen (music/SFX)
- [x] Persistencia de preferencias de audio

### Quest System
- [x] 13 tipos de quests diferentes
- [x] Rewards de monedas y energía
- [x] 3 quests activas simultáneas
- [x] Auto-reemplazo al completar
- [x] Persistencia de progreso

### CI/CD
- [x] Workflow para generar APK automáticamente
- [x] Debug keystore generado en CI
- [x] Release automático al crear tag

## Estructura del proyecto

```
mobile-civ-merging-game/
├── project.godot              # Configuración del proyecto
├── scenes/
│   ├── main.tscn              # Escena principal
│   └── building.tscn          # Prefab de edificio
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd    # Estado global del juego
│   │   ├── save_manager.gd    # Guardado/carga
│   │   ├── quest_manager.gd   # Sistema de misiones
│   │   └── audio_manager.gd   # Audio y música
│   ├── effects/
│   │   └── particle_effects.gd # Efectos visuales
│   ├── ui/
│   │   ├── quest_panel.gd     # Panel de misiones
│   │   └── settings_panel.gd  # Panel de ajustes
│   ├── building.gd            # Comportamiento de edificio
│   ├── game_grid.gd           # Gestión del grid
│   └── ui_manager.gd          # UI y botones
├── .github/workflows/
│   └── release.yml            # CI/CD para APK
├── README.md
├── LICENSE
└── PROGRESS.md                # Este archivo
```

## Comandos útiles

```bash
# Ver dispositivos conectados
/home/os_uis/Android/Sdk/platform-tools/adb devices

# Instalar APK
/home/os_uis/Android/Sdk/platform-tools/adb install -r merge-town-debug.apk

# Ver logs de la app
/home/os_uis/Android/Sdk/platform-tools/adb logcat | grep -i godot

# Ejecutar Godot en local
/home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --path .

# Crear nuevo release
git tag v1.0.X && git push --tags
```

## Historial de versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| v1.0.0 | 2026-01-03 | Primera versión, workflow configurado |
| v1.0.1 | 2026-01-04 | Fix rutas de nodos, UIDs removidos |
| v1.0.2 | 2026-01-04 | Import de recursos antes de exportar |
| v1.0.3 | 2026-01-05 | Background music y settings menu |
| v1.0.4 | 2026-01-05 | Docs update, persistencia audio/quests, bug fixes |

## Notas técnicas

- El token de GitHub necesita el scope `workflow` para subir cambios a `.github/workflows/`
- El contenedor Docker usado es `barichello/godot-ci:4.2.2`
- El debug keystore se genera automáticamente en CI
- La app usa orientación portrait (vertical)
- Audio generado proceduralmente (sin archivos externos)

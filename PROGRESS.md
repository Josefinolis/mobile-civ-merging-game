# Merge Town - Progress Log

## Estado actual: FUNCIONAL

El juego funciona correctamente en local y la APK se genera via GitHub Actions.

## Repositorio
- **URL**: https://github.com/Josefinolis/mobile-civ-merging-game
- **Última versión**: v1.3.0
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

### Shop System (v1.1.0)
- [x] 6 tipos de mejoras comprables
  - Coin Boost: Multiplicador de generación de monedas
  - Energy Tank: Aumenta energía máxima
  - Fast Charge: Regeneración de energía más rápida
  - Lucky Spawn: Chance de spawnear edificios de mayor nivel
  - Idle Income: Mejora ganancias offline
  - Super Merge: Chance de saltar un nivel al hacer merge
- [x] Costos que escalan exponencialmente
- [x] Persistencia de upgrades compradas

### Daily Rewards (v1.1.0)
- [x] Sistema de recompensas diarias de 7 días
- [x] Ciclo que se repite cada semana
- [x] Recompensas crecientes (monedas + energía)
- [x] Bonus x2 monedas temporales en día 7
- [x] Persistencia del streak y estado

### Monetización (v1.3.0)

#### In-App Purchases (Google Play Billing)
- [x] Integración con Google Play Billing Library
- [x] Detección automática de entorno (SIMULATED en editor, REAL en Android)
- [x] 5 paquetes de monedas ($0.99 - $19.99)
- [x] 3 paquetes de energía ($0.99 - $2.99)
- [x] Bundles especiales (Starter Pack, Pro Pack)
- [x] Suscripciones VIP (semanal y mensual)
- [x] Opción "Remove Ads" ($2.99)
- [x] Documentación completa: GOOGLE_PLAY_SETUP.md

#### Publicidad (AdMob)
- [x] Integración con AdMob
- [x] Banner ads (parte inferior)
- [x] Interstitial ads (cada 3 acciones, cooldown 60s)
- [x] Rewarded video ads (+10 energía por video)
- [x] Botón "Ver anuncio" junto al contador de energía
- [x] Compra "Remove Ads" elimina banners e interstitials
- [x] Scripts de instalación: setup_billing.sh, setup_ads.sh
- [x] Documentación completa: ADMOB_SETUP.md

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
│   │   ├── audio_manager.gd   # Audio y música
│   │   ├── shop_manager.gd    # Sistema de tienda y upgrades
│   │   ├── daily_reward_manager.gd # Recompensas diarias
│   │   ├── iap_manager.gd     # In-App Purchases (Google Play)
│   │   └── ads_manager.gd     # Publicidad (AdMob)
│   ├── effects/
│   │   └── particle_effects.gd # Efectos visuales
│   ├── ui/
│   │   ├── quest_panel.gd     # Panel de misiones
│   │   ├── settings_panel.gd  # Panel de ajustes
│   │   ├── shop_panel.gd      # Panel de tienda
│   │   └── daily_reward_panel.gd # Panel de recompensas
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
| v1.1.0 | 2026-01-07 | Shop system con 6 upgrades, daily rewards de 7 días |
| v1.1.1 | 2026-01-07 | Mejora visual: edificios detallados, fondo mejorado, celdas con estilo |
| v1.1.2 | 2026-01-07 | Edificios centrados y escalados, UI con estilos mejorados |
| v1.3.0 | 2026-01-09 | Sistema de monetización: IAP (Google Play Billing) + Ads (AdMob) |

## Notas técnicas

- El token de GitHub necesita el scope `workflow` para subir cambios a `.github/workflows/`
- El contenedor Docker usado es `barichello/godot-ci:4.2.2`
- El debug keystore se genera automáticamente en CI
- La app usa orientación portrait (vertical)
- Audio generado proceduralmente (sin archivos externos)

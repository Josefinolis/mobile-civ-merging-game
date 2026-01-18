# Merge Town - Progress Log

## Estado actual: PUBLICADO EN GOOGLE PLAY (Pruebas Internas)

El juego esta publicado en Google Play para pruebas internas. Listo para produccion.

## Repositorio
- **URL**: https://github.com/Josefinolis/mobile-civ-merging-game
- **Ultima version**: v1.3.0
- **Release**: https://github.com/Josefinolis/mobile-civ-merging-game/releases

---

## Publicacion en Google Play

### Estado
- **App**: Merge Town
- **Package**: com.mergetowngame.app
- **Version actual**: 1.0.0 (Version Code 7)
- **Track**: Pruebas internas (completado)
- **Produccion**: Pendiente

### Configuracion completada
- [x] Cuenta de desarrollador de Google Play
- [x] Ficha de Play Store (icono, capturas, descripcion)
- [x] Clasificacion de contenido
- [x] Politica de privacidad
- [x] Keystore de release configurado
- [x] AAB firmado y subido
- [x] Cuenta de servicio para publicacion CLI

### Publicar desde linea de comandos
```bash
# Publicar a pruebas internas
python3 publish_to_play.py internal

# Publicar a produccion
python3 publish_to_play.py production
```

### Archivos importantes (NO SUBIR A GIT)
| Archivo | Descripcion |
|---------|-------------|
| `release.keystore` | Keystore para firmar |
| `keystore-credentials.txt` | Credenciales del keystore |
| `google-play-credentials.json` | Cuenta de servicio para publicacion |

---

## Lo que esta implementado

### Core Game
- [x] Estructura del proyecto Godot 4.2
- [x] Sistema de grid 5x7 para edificios
- [x] Mecanica de drag & drop
- [x] Logica de merge (fusion de edificios iguales)
- [x] 10 niveles de edificios (Tent -> Wonder)
- [x] Sistema de energia (10 max, regenera cada 30s)
- [x] Generacion pasiva de monedas
- [x] Auto-guardado al cerrar
- [x] Ganancias offline (50% eficiencia, max 8h)

### UI y Visual
- [x] UI con stats (monedas, energia, ingresos/s)
- [x] Edificios con graficos detallados
- [x] Efectos de particulas (merge, spawn, coins)
- [x] Animaciones juicy
- [x] Panel de quests colapsable
- [x] Panel de settings modal

### Audio
- [x] Efectos de sonido procedurales
- [x] Musica de fondo ambiental
- [x] Controles de volumen (music/SFX)
- [x] Persistencia de preferencias de audio

### Quest System
- [x] 13 tipos de quests diferentes
- [x] Rewards de monedas y energia
- [x] 3 quests activas simultaneas
- [x] Auto-reemplazo al completar
- [x] Persistencia de progreso

### Shop System
- [x] 6 tipos de mejoras comprables
- [x] Costos que escalan exponencialmente
- [x] Persistencia de upgrades compradas

### Daily Rewards
- [x] Sistema de recompensas diarias de 7 dias
- [x] Ciclo que se repite cada semana
- [x] Recompensas crecientes (monedas + energia)
- [x] Bonus x2 monedas temporales en dia 7

### Monetizacion

#### In-App Purchases (Google Play Billing)
- [x] Integracion con Google Play Billing Library
- [x] Deteccion automatica de entorno
- [x] 5 paquetes de monedas ($0.99 - $19.99)
- [x] 3 paquetes de energia ($0.99 - $2.99)
- [x] Bundles especiales (Starter Pack, Pro Pack)
- [x] Suscripciones VIP (semanal y mensual)
- [x] Opcion "Remove Ads" ($2.99)

#### Publicidad (AdMob)
- [x] Integracion con AdMob
- [x] Banner ads (parte inferior)
- [x] Interstitial ads (cada 3 acciones, cooldown 60s)
- [x] Rewarded video ads (+10 energia por video)
- [x] Boton "Ver anuncio" junto al contador de energia

### CI/CD
- [x] Workflow para generar APK automaticamente
- [x] Workflow para generar AAB firmado
- [x] Release automatico al crear tag

---

## Estructura del proyecto

```
mobile-civ-merging-game/
├── project.godot              # Configuracion del proyecto
├── scenes/
│   ├── main.tscn              # Escena principal
│   └── building.tscn          # Prefab de edificio
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd    # Estado global del juego
│   │   ├── save_manager.gd    # Guardado/carga
│   │   ├── quest_manager.gd   # Sistema de misiones
│   │   ├── audio_manager.gd   # Audio y musica
│   │   ├── shop_manager.gd    # Sistema de tienda
│   │   ├── daily_reward_manager.gd # Recompensas diarias
│   │   ├── iap_manager.gd     # In-App Purchases
│   │   └── ads_manager.gd     # Publicidad (AdMob)
│   ├── effects/
│   │   └── particle_effects.gd
│   ├── ui/
│   │   ├── quest_panel.gd
│   │   ├── settings_panel.gd
│   │   ├── shop_panel.gd
│   │   ├── daily_reward_panel.gd
│   │   └── iap_panel.gd
│   ├── building.gd
│   ├── game_grid.gd
│   └── ui_manager.gd
├── .github/workflows/
│   ├── release.yml            # CI/CD para APK
│   └── build-aab.yml          # CI/CD para AAB
├── publish_to_play.py         # Script de publicacion
├── README.md
├── PROGRESS.md                # Este archivo
├── GOOGLE_PLAY_SETUP.md       # Guia de configuracion IAP
└── ADMOB_SETUP.md             # Guia de configuracion AdMob
```

---

## Comandos utiles

```bash
# Ejecutar Godot en local
/home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --path .

# Ver dispositivos conectados
/home/os_uis/Android/Sdk/platform-tools/adb devices

# Instalar APK
/home/os_uis/Android/Sdk/platform-tools/adb install -r builds/merge-town.apk

# Ver logs de la app
/home/os_uis/Android/Sdk/platform-tools/adb logcat | grep -i godot

# Crear nuevo release
git tag v1.0.X && git push --tags

# Publicar a Google Play
python3 publish_to_play.py internal
```

---

## Historial de versiones

| Version | Fecha | Cambios |
|---------|-------|---------|
| v1.0.0 | 2026-01-03 | Primera version, workflow configurado |
| v1.0.1 | 2026-01-04 | Fix rutas de nodos, UIDs removidos |
| v1.0.2 | 2026-01-04 | Import de recursos antes de exportar |
| v1.0.3 | 2026-01-05 | Background music y settings menu |
| v1.0.4 | 2026-01-05 | Persistencia audio/quests, bug fixes |
| v1.1.0 | 2026-01-07 | Shop system, daily rewards |
| v1.1.1 | 2026-01-07 | Mejora visual: edificios detallados |
| v1.1.2 | 2026-01-07 | Edificios centrados y escalados |
| v1.3.0 | 2026-01-09 | Monetizacion: IAP + AdMob |

---

## Notas tecnicas

- El token de GitHub necesita el scope `workflow` para subir cambios a `.github/workflows/`
- El contenedor Docker usado es `barichello/godot-ci:4.2.2`
- La app usa orientacion portrait (vertical)
- Audio generado proceduralmente (sin archivos externos)
- Para generar AAB: usar Godot con UI (WSLg), no headless

# Merge Town - Progress Log

## Estado actual: EN PRUEBAS

La APK se genera correctamente pero muestra pantalla vacía al ejecutar.

## Repositorio
- **URL**: https://github.com/Josefinolis/mobile-civ-merging-game
- **Última versión**: v1.0.2
- **Release**: https://github.com/Josefinolis/mobile-civ-merging-game/releases/tag/v1.0.2

## Lo que está implementado

### Juego (Godot 4.2)
- [x] Estructura del proyecto Godot
- [x] Sistema de grid 5x7 para edificios
- [x] Mecánica de drag & drop
- [x] Lógica de merge (fusión de edificios iguales)
- [x] 10 niveles de edificios (Tent → Wonder)
- [x] Sistema de energía (10 max, regenera cada 30s)
- [x] Generación pasiva de monedas
- [x] Auto-guardado al cerrar
- [x] Ganancias offline (50% eficiencia, max 8h)
- [x] UI básica (monedas, energía, ingresos/s)

### CI/CD (GitHub Actions)
- [x] Workflow para generar APK automáticamente
- [x] Debug keystore generado en CI
- [x] Importación de recursos antes de exportar
- [x] Release automático al crear tag

## Problema pendiente

**La APK muestra pantalla vacía al ejecutar.**

### Posibles causas a investigar:
1. Las escenas .tscn pueden tener problemas de formato
2. Los scripts pueden tener errores que no se ven en CI
3. Los autoloads (GameManager, SaveManager) pueden fallar al cargar

### Próximo paso recomendado:
Conectar teléfono Android por USB para:
1. Instalar APK via ADB
2. Ver logs en tiempo real con `adb logcat`
3. Identificar el error exacto

### Cómo conectar el teléfono:
1. Habilitar "Depuración USB":
   - Configuración → Acerca del teléfono → Toca "Número de compilación" 7 veces
   - Configuración → Opciones de desarrollador → Habilitar "Depuración USB"
2. Conectar por USB
3. Ejecutar: `/home/os_uis/Android/Sdk/platform-tools/adb devices`

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
│   │   └── save_manager.gd    # Guardado/carga
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

# Crear nuevo release
git tag v1.0.3 && git push --tags
```

## Historial de versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| v1.0.0 | 2026-01-03 | Primera versión, workflow configurado |
| v1.0.1 | 2026-01-04 | Fix rutas de nodos, UIDs removidos |
| v1.0.2 | 2026-01-04 | Import de recursos antes de exportar |

## Notas técnicas

- El token de GitHub necesita el scope `workflow` para subir cambios a `.github/workflows/`
- El contenedor Docker usado es `barichello/godot-ci:4.2.2`
- El debug keystore se genera automáticamente en CI
- La app usa orientación portrait (vertical)

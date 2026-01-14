# Progreso de Publicación - Merge Town

## Estado actual: PRUEBAS INTERNAS COMPLETADAS
**Fecha**: 14 de enero de 2026

---

## Completado

### 1. Keystore de Release (firmado)
- **Archivo**: `release.keystore`
- **Credenciales**: `keystore-credentials.txt`
- **Alias**: `merge_town`
- **IMPORTANTE**: Hacer backup de estos archivos, son necesarios para actualizar la app

### 2. IDs de AdMob configurados
```
App ID:        ca-app-pub-9924441769526161~3498220200
Banner:        ca-app-pub-9924441769526161/4001439626
Intersticial:  ca-app-pub-9924441769526161/6601868023
Bonificado:    ca-app-pub-9924441769526161/6823221699
```
Archivo actualizado: `scripts/autoload/ads_manager.gd`

### 3. Política de Privacidad
- **URL**: https://josefinolis.github.io/mobile-civ-merging-game/privacy-policy.html
- **Archivo**: `docs/privacy-policy.html`

### 4. Google Play Console
- App creada: **Merge Town**
- Cuenta: joseluismc81@gmail.com
- Ficha de Play Store completada:
  - Icono subido (512x512)
  - Gráfico de funciones subido (1024x500)
  - 2 capturas de pantalla subidas
  - Descripción breve y completa
- Contenido de la aplicación completado:
  - Política de privacidad
  - Clasificación del contenido
  - Público objetivo
  - Anuncios
  - Seguridad de datos

### 5. AAB generado y listo
- **Archivo**: `builds/merge-town-release.aab`
- **Version Code**: 7
- **Target SDK**: 35
- **Min SDK**: 21
- Firmado con keystore de release
- Contiene IDs de AdMob reales
- Permiso `AD_ID` incluido para AdMob
- **Probado en emulador**: Botones funcionan correctamente

### 6. Configuración de Android corregida
- `AndroidManifest.xml`: Añadido permiso `com.google.android.gms.permission.AD_ID`
- `config.gradle`: Target SDK y Compile SDK actualizados a 35

---

## Pendiente

### 1. Aprobación de cuenta de desarrollador
- Google está revisando la cuenta de desarrollador
- Tiempo estimado: 1-7 días
- Una vez aprobada, se podrá publicar a pruebas internas

### 2. Configurar testers
- Ir a: Pruebas internas → Testers
- Crear lista de testers
- Añadir emails de testers

### 3. (Opcional) Configurar productos IAP
Productos definidos en `scripts/autoload/iap_manager.gd`:
- coins_small, coins_medium, coins_large
- energy_small, energy_medium, energy_full
- no_ads, starter_pack, pro_pack
- vip_week, vip_month

---

## Archivos importantes

| Archivo | Descripción |
|---------|-------------|
| `release.keystore` | Keystore para firmar (NO SUBIR A GIT) |
| `keystore-credentials.txt` | Contraseñas del keystore (NO SUBIR A GIT) |
| `export_presets.cfg` | Configuración de exportación Android |
| `builds/merge-town-release.aab` | AAB firmado actual (v7) |
| `builds/merge-town-test.apk` | APK para testing local (v7) |
| `android/build/AndroidManifest.xml` | Manifest con permiso AD_ID |

---

## Notas técnicas

### Generación de AAB
- **Problema encontrado**: Godot en modo headless no puede generar AAB con gradle build (bug conocido)
- **Solución**: Usar Godot con interfaz gráfica (WSLg en WSL2)
- **Comando para abrir editor**:
```bash
/home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --editor --path /home/os_uis/projects/mobile-civ-merging-game
```

### Exportar AAB desde Godot GUI
1. Proyecto → Exportar
2. Seleccionar "Android Release"
3. Configurar:
   - Gradle Build: ✓
   - Export Format: AAB
   - Target SDK: 35
   - Version Code: incrementar cada vez
4. Keystore Release: `/home/os_uis/projects/mobile-civ-merging-game/release.keystore`
5. Release User: `merge_town`
6. Desmarcar "Export With Debug"
7. Exportar proyecto

### Acceder a archivos desde Windows
```
\\wsl$\Ubuntu\home\os_uis\projects\mobile-civ-merging-game\builds\
```

### Solución a problemas de botones/scripts (2026-01-14)
**Problema**: Los botones no funcionaban en el APK/AAB exportado.

**Causa**: Caché corrupta en `.godot/` y `android/build/` causando errores:
```
SCRIPT ERROR: Class "UIManager" hides a global script class.
SCRIPT ERROR: Class "GameGrid" hides a global script class.
```

**Solución**:
1. Cerrar Godot
2. Eliminar directorios: `rm -rf .godot android/build`
3. Abrir Godot de nuevo
4. Proyecto → Instalar plantilla de compilación de Android
5. Configurar keystore en opciones de exportación
6. Exportar AAB/APK

---

## Historial de versiones subidas

| Version Code | Version Name | Fecha | Notas |
|--------------|--------------|-------|-------|
| 4 | 1.0.0 | 2026-01-11 | Primera versión con Target SDK 35 y AD_ID |
| 6 | 1.0.0 | 2026-01-14 | Intento de fix (falló por caché corrupta) |
| 7 | 1.0.0 | 2026-01-14 | Fix completo: limpieza de caché, botones funcionan |

---

## Próximos pasos
1. ~~Subir `merge-town-release.aab` a Google Play Console~~ ✓
2. ~~Configurar testers en Google Play Console~~ ✓
3. ~~Probar la app desde Play Store (pruebas internas)~~ ✓ Botones funcionan
4. Publicar a producción

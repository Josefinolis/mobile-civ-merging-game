# Progreso de Publicación - Merge Town

## Estado actual: PENDIENTE APROBACIÓN DE CUENTA
**Fecha**: 11 de enero de 2026

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

### 5. AAB generado y subido
- **Archivo**: `builds/merge-town-release.aab`
- **Version Code**: 4
- **Target SDK**: 35
- **Min SDK**: 21
- Firmado con keystore de release
- Contiene IDs de AdMob reales
- Permiso `AD_ID` incluido para AdMob
- **Subido a Google Play Console** (Pruebas internas)

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
| `builds/merge-town-release.aab` | AAB firmado actual |
| `builds/merge-town-release.apk` | APK firmado (backup) |
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

---

## Historial de versiones subidas

| Version Code | Version Name | Fecha | Notas |
|--------------|--------------|-------|-------|
| 4 | 1.0.0 | 2026-01-11 | Primera versión con Target SDK 35 y AD_ID |

---

## Próximos pasos
1. Esperar aprobación de cuenta de Google
2. Configurar testers en Google Play Console
3. Probar la app desde Play Store (pruebas internas)
4. Corregir bugs si los hay
5. Publicar a producción

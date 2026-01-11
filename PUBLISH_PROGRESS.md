# Progreso de Publicación - Merge Town

## Estado actual: EN PROGRESO
**Fecha**: 10 de enero de 2026

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

### 5. APK firmado generado
- **Archivo**: `builds/merge-town-release.apk`
- Firmado con keystore de release
- Contiene IDs de AdMob reales

---

## Pendiente

### 1. Generar AAB (Android App Bundle)
Google Play requiere AAB, no APK. El problema actual:
- Godot no detecta el archivo `.build_version` del template de gradle
- Error: "Trying to build from a gradle built template, but no version info"

**Soluciones posibles**:
1. Usar GitHub Actions para generar el AAB (modificar workflow)
2. Abrir Godot con interfaz gráfica y reinstalar el template desde "Proyecto > Exportar > Gestionar plantillas de exportación"
3. Usar bundletool de Google para convertir APK a AAB (investigar)

### 2. Subir AAB a Google Play Console
- Ir a: Probar y publicar → Pruebas internas → Crear versión
- Subir el archivo .aab
- Nombre de versión: 1.0.0

### 3. Configurar testers
- Añadir joseluismc81@gmail.com como tester
- Crear lista de testers

### 4. (Opcional) Configurar productos IAP
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
| `builds/merge-town-release.apk` | APK firmado actual |
| `builds/icon_512x512.png` | Icono para Play Store |
| `builds/feature_graphic.png` | Gráfico de funciones |
| `builds/screenshot_1.png` | Captura 1 |
| `builds/screenshot_2.png` | Captura 2 |

---

## Comandos útiles

```bash
# Generar APK (funciona)
/home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --headless --export-release "Android Release" builds/merge-town-release.apk

# Intentar generar AAB (actualmente falla)
xvfb-run -a /home/os_uis/Godot_v4.2.2-stable_linux.x86_64 --path . --export-release "Android Release" builds/merge-town-release.aab

# Acceder a archivos desde Windows
\\wsl$\Ubuntu\home\os_uis\projects\mobile-civ-merging-game\builds\
```

---

## Commits realizados hoy
1. `aa89fa0` - Add privacy policy and fix billing plugin
2. `379bd00` - Update AdMob IDs to production values

---

## Próximos pasos mañana
1. Resolver el problema del AAB (template de gradle)
2. Subir AAB a Google Play Console
3. Iniciar pruebas internas
4. Revisar y publicar

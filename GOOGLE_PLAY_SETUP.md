# Guia de Configuracion de Google Play Billing

Esta guia te explica como configurar pagos reales en tu juego Merge Town.

## Tabla de Contenidos
1. [Crear Cuenta de Google Play Developer](#1-crear-cuenta-de-google-play-developer)
2. [Instalar Plugin de Godot](#2-instalar-plugin-de-godot-google-play-billing)
3. [Configurar Exportacion Android](#3-configurar-exportacion-android-en-godot)
4. [Crear App en Google Play Console](#4-crear-app-en-google-play-console)
5. [Configurar Productos IAP](#5-configurar-productos-iap)
6. [Configurar Suscripciones](#6-configurar-suscripciones)
7. [Testing con Testers](#7-testing-con-testers)
8. [Publicar en Produccion](#8-publicar-en-produccion)
9. [Recibir Pagos](#9-configurar-pagos-y-cobrar)

---

## 1. Crear Cuenta de Google Play Developer

### Paso 1.1: Registrarse
1. Ve a: https://play.google.com/console/signup
2. Inicia sesion con tu cuenta de Google
3. Acepta los terminos del desarrollador
4. Paga la cuota unica de **$25 USD**
5. Completa tu perfil de desarrollador

### Paso 1.2: Verificar Identidad (Requerido para pagos)
1. Ve a **Setup > Developer account > Account details**
2. Completa la verificacion de identidad
3. Proporciona datos fiscales (requerido para recibir pagos)

**Importante**: Sin verificacion no podras recibir dinero.

---

## 2. Instalar Plugin de Godot Google Play Billing

### Paso 2.1: Descargar el plugin
1. Ve a: https://github.com/nickg111/godot-google-play-billing/releases
2. Descarga la ultima version compatible con Godot 4.2
3. Descomprime el archivo

### Paso 2.2: Instalar en el proyecto
```bash
# Crear carpeta de plugins Android si no existe
mkdir -p android/plugins

# Copiar el plugin (ajusta la ruta segun donde descargaste)
cp -r ~/Downloads/GodotGooglePlayBilling android/plugins/
```

Estructura final:
```
mobile-civ-merging-game/
├── android/
│   └── plugins/
│       └── GodotGooglePlayBilling/
│           ├── GodotGooglePlayBilling.gdap
│           └── GodotGooglePlayBilling.aar
├── scripts/
└── ...
```

### Paso 2.3: Habilitar el plugin en Godot
1. Abre Godot
2. Ve a **Project > Project Settings > Plugins**
3. Busca "Godot Google Play Billing"
4. Activa el plugin (checkbox)

---

## 3. Configurar Exportacion Android en Godot

### Paso 3.1: Configurar Android Export Template
1. En Godot: **Editor > Manage Export Templates**
2. Descarga los templates de Android si no los tienes

### Paso 3.2: Crear preset de exportacion
1. Ve a **Project > Export**
2. Click en "Add..." y selecciona "Android"
3. Configura:

```
Export Path: /tmp/merge-town.aab  (usa .aab para Google Play)

# Opciones principales
Unique Name: com.mergetowngame.app
Name: Merge Town
Version Code: 1
Version Name: 1.0.0

# Permisos (marcar BILLING)
[x] BILLING  <-- IMPORTANTE!
[x] INTERNET
[x] ACCESS_NETWORK_STATE

# Plugins (debe aparecer si instalaste bien)
[x] Godot Google Play Billing
```

### Paso 3.3: Firmar la app
Necesitas crear un keystore para firmar tu APK/AAB:

```bash
# Crear keystore (guarda la contrasena de forma segura!)
keytool -genkey -v -keystore ~/merge-town-release.keystore \
  -alias merge_town -keyalg RSA -keysize 2048 -validity 10000
```

En Godot Export:
- **Release Keystore**: ~/merge-town-release.keystore
- **Release User**: merge_town
- **Release Password**: [tu contrasena]

**IMPORTANTE**: Guarda el keystore y contrasena en un lugar seguro. Si los pierdes, no podras actualizar tu app en Google Play.

---

## 4. Crear App en Google Play Console

### Paso 4.1: Crear nueva app
1. Ve a: https://play.google.com/console
2. Click "Create app"
3. Completa:
   - **App name**: Merge Town
   - **Default language**: English (US) o Spanish
   - **App or game**: Game
   - **Free or paid**: Free (las compras son in-app)

### Paso 4.2: Configurar ficha de la tienda
1. Ve a **Grow > Store presence > Main store listing**
2. Completa:
   - Descripcion corta (80 caracteres)
   - Descripcion completa (4000 caracteres)
   - Screenshots (minimo 2)
   - Icono de app (512x512 px)
   - Feature graphic (1024x500 px)

### Paso 4.3: Clasificacion de contenido
1. Ve a **Policy > App content**
2. Completa el cuestionario de clasificacion
3. Obtendras clasificacion PEGI/ESRB automaticamente

### Paso 4.4: Configurar precios
1. Ve a **Monetize > Products > App pricing**
2. Selecciona "Free" (el juego es gratis, cobra por IAP)

---

## 5. Configurar Productos IAP

### Paso 5.1: Habilitar monetizacion
1. Ve a **Monetize > Monetization setup**
2. Acepta los terminos de monetizacion

### Paso 5.2: Crear productos In-App
Ve a **Monetize > Products > In-app products** y crea cada producto:

#### Paquetes de Monedas (Consumables)

| Product ID | Nombre | Descripcion | Precio |
|------------|--------|-------------|--------|
| `coins_tiny` | Coin Pouch | Get 300 coins instantly | $0.99 |
| `coins_small` | Coin Bag | Get 800 coins (+33% bonus) | $1.99 |
| `coins_medium` | Coin Chest | Get 2,500 coins (+65% bonus) | $4.99 |
| `coins_large` | Coin Vault | Get 6,000 coins (+100% bonus) | $9.99 |
| `coins_mega` | Coin Treasury | Get 15,000 coins (+150% bonus) | $19.99 |

#### Paquetes de Energia (Consumables)

| Product ID | Nombre | Descripcion | Precio |
|------------|--------|-------------|--------|
| `energy_small` | Energy Drink | +15 energy instantly | $0.99 |
| `energy_medium` | Energy Pack | +40 energy (+33% bonus) | $1.99 |
| `energy_full` | Full Recharge | Full energy + 10 extra | $2.99 |

#### Bundles Especiales (Non-consumables / Managed products)

| Product ID | Nombre | Descripcion | Precio |
|------------|--------|-------------|--------|
| `starter_pack` | Starter Bundle | 2000 coins + 30 energy + 2x coins 30min | $2.99 |
| `pro_pack` | Pro Bundle | 5000 coins + 50 energy + 2x coins 1hr | $6.99 |
| `no_ads` | Remove Ads | Remove all banner and interstitial ads forever | $2.99 |

### Paso 5.3: Configurar cada producto
Para cada producto:
1. Click "Create product"
2. **Product ID**: Usa exactamente el ID de la tabla (ej: `coins_tiny`)
3. **Name**: Nombre del producto
4. **Description**: Descripcion
5. **Default price**: Precio base en USD
6. Click "Save"
7. Click "Activate" para activar el producto

**Nota sobre precios locales**: Google convierte automaticamente los precios a monedas locales, pero puedes personalizarlos manualmente.

---

## 6. Configurar Suscripciones

### Paso 6.1: Crear suscripciones
Ve a **Monetize > Products > Subscriptions** y crea:

#### VIP Week
1. **Product ID**: `vip_week`
2. **Name**: VIP Week
3. **Description**: 1.5x coins + 30% faster energy regen for 7 days
4. **Billing period**: Weekly
5. **Default price**: $3.99/week
6. Click "Save" y "Activate"

#### VIP Month
1. **Product ID**: `vip_month`
2. **Name**: VIP Month
3. **Description**: 2x coins + 50% faster energy regen for 30 days
4. **Billing period**: Monthly
5. **Default price**: $9.99/month
6. Click "Save" y "Activate"

### Paso 6.2: Configurar grace period y recovery
- Grace period: 7 dias (permite pago si falla la tarjeta)
- Account hold: Hasta 30 dias

---

## 7. Testing con Testers

### Paso 7.1: Crear track de testing
1. Ve a **Testing > Internal testing**
2. Click "Create new release"
3. Sube tu AAB firmado
4. Completa release notes

### Paso 7.2: Agregar testers
1. Ve a **Testing > Internal testing > Testers**
2. Click "Create email list"
3. Agrega emails de testers (incluyendo el tuyo)

### Paso 7.3: Configurar License Testing
**MUY IMPORTANTE** para probar compras sin cobrar:

1. Ve a **Setup > License testing**
2. Agrega los emails de tus testers
3. Selecciona "RESPOND_NORMALLY" para simular compras reales

### Paso 7.4: Probar
1. Los testers reciben un link de Google Play
2. Instalan la app desde el link
3. Las compras se procesan pero NO se cobra dinero real

### Paso 7.5: Modo de pagos (automatico)
El sistema detecta automaticamente el entorno:

| Entorno | Modo |
|---------|------|
| Godot Editor | SIMULATED (gratis) |
| Desktop (Windows/Mac/Linux) | SIMULATED (gratis) |
| Android SIN plugin | SIMULATED (gratis) |
| Android CON plugin | REAL (Google Play) |

**Para forzar simulacion en Android** (testing sin Google Play):
```gdscript
# En iap_manager.gd linea 43:
const FORCE_SIMULATE: bool = true  # Cambiar a true para forzar simulacion
```

**Para produccion**: Asegurate de que `FORCE_SIMULATE = false` (valor por defecto).

---

## 8. Publicar en Produccion

### Paso 8.1: Completar todos los requisitos
Google Play Console te mostrara una lista de requisitos pendientes:
- [ ] Ficha de tienda completa
- [ ] Clasificacion de contenido
- [ ] Politica de privacidad (URL requerida)
- [ ] App bundle firmado
- [ ] Declaraciones de contenido

### Paso 8.2: Crear politica de privacidad
Crea una pagina web simple con tu politica de privacidad. Puedes usar:
- GitHub Pages (gratis)
- Notion (gratis)
- Tu propio dominio

Ejemplo minimo de politica:
```
Privacy Policy for Merge Town

This game collects:
- Game progress (saved locally)
- Purchase history (via Google Play)

We do not collect personal information beyond what Google Play provides for purchases.

Contact: [tu email]
Last updated: [fecha]
```

### Paso 8.3: Enviar a revision
1. Ve a **Production > Create new release**
2. Sube tu AAB firmado
3. Click "Start rollout to Production"
4. Google revisara tu app (1-3 dias normalmente)

---

## 9. Configurar Pagos y Cobrar

### Paso 9.1: Configurar perfil de pagos
1. Ve a **Setup > Payments profile**
2. Crea o vincula un perfil de Google Payments
3. Agrega una cuenta bancaria para recibir pagos

### Paso 9.2: Datos fiscales
1. Completa la informacion fiscal
2. Si estas fuera de USA, completa el formulario W-8BEN
3. Esto es obligatorio para recibir pagos

### Paso 9.3: Comisiones de Google
- **15%** para los primeros $1M USD anuales
- **30%** despues de $1M USD
- **15%** para suscripciones despues del primer ano del usuario

### Paso 9.4: Calendario de pagos
- Google paga mensualmente
- Umbral minimo: $100 USD
- Los pagos se procesan alrededor del dia 15 del mes siguiente

### Paso 9.5: Ver ingresos
1. Ve a **Financial reports > Revenue**
2. Puedes ver:
   - Ventas por producto
   - Ventas por pais
   - Reembolsos
   - Ingresos netos

---

## Resumen de IDs de Productos

Asegurate de que los IDs en Google Play Console coincidan EXACTAMENTE con los de `iap_manager.gd`:

```
PRODUCTOS IN-APP (consumables):
- coins_tiny
- coins_small
- coins_medium
- coins_large
- coins_mega
- energy_small
- energy_medium
- energy_full

PRODUCTOS IN-APP (managed/one-time):
- starter_pack
- pro_pack
- no_ads

SUSCRIPCIONES:
- vip_week
- vip_month
```

---

## Troubleshooting

### "Billing not available"
- Verifica que el plugin esta instalado y habilitado
- Verifica que BILLING permission esta marcado en export
- Solo funciona en dispositivos Android con Google Play

### "Item not found"
- Verifica que el Product ID es exactamente igual en Google Play Console
- El producto debe estar "Activo" en Google Play Console
- Espera 15-30 minutos despues de crear productos

### "Purchase failed"
- En testing: verifica que el email esta en License Testing
- El dispositivo debe tener la app instalada desde Google Play (no sideloaded)

### Compras no se restauran
- Llama a `IAPManager.restore_purchases()` al iniciar la app
- Los consumables no se restauran (es normal)
- Solo se restauran non-consumables y suscripciones activas

---

## Checklist Final

- [ ] Cuenta de Google Play Developer creada y verificada
- [ ] Plugin GodotGooglePlayBilling instalado
- [ ] Export configurado con BILLING permission
- [ ] Keystore creado y guardado de forma segura
- [ ] App creada en Google Play Console
- [ ] Todos los productos IAP creados y activados
- [ ] Suscripciones configuradas
- [ ] License Testing configurado con testers
- [ ] Testing completado exitosamente
- [ ] FORCE_SIMULATE = false en iap_manager.gd (valor por defecto, no tocar)
- [ ] Politica de privacidad publicada
- [ ] Perfil de pagos configurado
- [ ] App enviada a produccion

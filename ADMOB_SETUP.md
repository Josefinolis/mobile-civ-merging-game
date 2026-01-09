# Guia de Configuracion de AdMob

Esta guia te explica como configurar publicidad real con AdMob en Merge Town.

## Tabla de Contenidos
1. [Crear Cuenta de AdMob](#1-crear-cuenta-de-admob)
2. [Crear App en AdMob](#2-crear-app-en-admob)
3. [Crear Ad Units](#3-crear-ad-units)
4. [Instalar Plugin en Godot](#4-instalar-plugin-en-godot)
5. [Configurar IDs en el Codigo](#5-configurar-ids-en-el-codigo)
6. [Testing](#6-testing)
7. [Mejores Practicas](#7-mejores-practicas)

---

## 1. Crear Cuenta de AdMob

### Paso 1.1: Registrarse
1. Ve a: https://admob.google.com
2. Inicia sesion con tu cuenta de Google
3. Acepta los terminos de servicio
4. Completa la informacion de pago

### Paso 1.2: Verificar Cuenta
- AdMob puede requerir verificacion de identidad
- Necesitas proporcionar informacion fiscal para recibir pagos

---

## 2. Crear App en AdMob

### Paso 2.1: Añadir nueva app
1. En AdMob, ve a **Apps > Add app**
2. Selecciona **Android**
3. Si ya esta publicada en Google Play:
   - Selecciona "Yes"
   - Busca tu app por nombre
4. Si aun no esta publicada:
   - Selecciona "No"
   - Ingresa el nombre: "Merge Town"

### Paso 2.2: Obtener App ID
Despues de crear la app, obtendras un **App ID** como:
```
ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```
**Guarda este ID**, lo necesitaras en el codigo.

---

## 3. Crear Ad Units

Necesitas crear 3 tipos de ad units:

### 3.1: Banner Ad
1. Ve a **Apps > Merge Town > Ad units > Add ad unit**
2. Selecciona **Banner**
3. Nombre: "merge_town_banner"
4. Guarda el **Ad Unit ID**

### 3.2: Interstitial Ad
1. **Add ad unit > Interstitial**
2. Nombre: "merge_town_interstitial"
3. Guarda el **Ad Unit ID**

### 3.3: Rewarded Ad
1. **Add ad unit > Rewarded**
2. Nombre: "merge_town_rewarded"
3. Configura la recompensa:
   - Reward amount: 10
   - Reward type: "energy"
4. Guarda el **Ad Unit ID**

### Resumen de IDs necesarios

| Tipo | ID de Prueba (ya configurado) | Tu ID Real |
|------|-------------------------------|------------|
| App ID | ca-app-pub-3940256099942544~3347511713 | ca-app-pub-XXXX~YYYY |
| Banner | ca-app-pub-3940256099942544/6300978111 | ca-app-pub-XXXX/ZZZZ |
| Interstitial | ca-app-pub-3940256099942544/1033173712 | ca-app-pub-XXXX/ZZZZ |
| Rewarded | ca-app-pub-3940256099942544/5224354917 | ca-app-pub-XXXX/ZZZZ |

---

## 4. Instalar Plugin en Godot

### Paso 4.1: Ejecutar script de instalacion
```bash
./setup_ads.sh
```

### Paso 4.2: Habilitar plugin en Godot
1. Abre Godot
2. Ve a **Project > Project Settings > Plugins**
3. Busca "AdMob" y habilita el plugin

### Paso 4.3: Configurar Android Export
1. Ve a **Project > Export > Android**
2. Asegurate de que el plugin de AdMob esta marcado
3. Configura los permisos:
   - [x] INTERNET
   - [x] ACCESS_NETWORK_STATE

---

## 5. Configurar IDs en el Codigo

### Paso 5.1: Editar ads_manager.gd

Abre `scripts/autoload/ads_manager.gd` y reemplaza los IDs de prueba:

```gdscript
# ANTES (IDs de prueba)
const ADMOB_APP_ID_ANDROID: String = "ca-app-pub-3940256099942544~3347511713"
const BANNER_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/6300978111"
const INTERSTITIAL_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/1033173712"
const REWARDED_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/5224354917"

# DESPUES (tus IDs reales)
const ADMOB_APP_ID_ANDROID: String = "ca-app-pub-TUAPPID~XXXXXXXXXX"
const BANNER_AD_UNIT_ID: String = "ca-app-pub-TUAPPID/XXXXXXXXXX"
const INTERSTITIAL_AD_UNIT_ID: String = "ca-app-pub-TUAPPID/XXXXXXXXXX"
const REWARDED_AD_UNIT_ID: String = "ca-app-pub-TUAPPID/XXXXXXXXXX"
```

### Paso 5.2: Configurar recompensa de video

En `ads_manager.gd`, puedes ajustar la cantidad de energia por ver un video:

```gdscript
const REWARDED_ENERGY_AMOUNT: int = 10  # Energia por video
```

---

## 6. Testing

### 6.1: Modo automatico

El AdsManager detecta automaticamente el entorno:

| Entorno | Modo |
|---------|------|
| Godot Editor | SIMULATED (sin anuncios reales) |
| Desktop | SIMULATED |
| Android sin plugin | SIMULATED |
| Android con plugin | REAL (AdMob) |

### 6.2: IDs de prueba de Google

Los IDs configurados por defecto son **IDs de prueba oficiales de Google**:
- Siempre muestran anuncios de prueba
- No generan ingresos
- Seguros para desarrollo

**IMPORTANTE**: Usar IDs reales durante desarrollo puede resultar en **ban de tu cuenta AdMob**.

### 6.3: Probar en dispositivo

1. Compila el APK con el plugin de AdMob
2. Instala en un dispositivo Android real
3. Los anuncios de prueba apareceran con etiqueta "Test Ad"

### 6.4: Forzar modo simulado en Android

Para testing sin anuncios reales en Android:

```gdscript
# En ads_manager.gd linea 27:
const FORCE_SIMULATE: bool = true
```

---

## 7. Mejores Practicas

### 7.1: Frecuencia de anuncios

La configuracion actual es conservadora para no molestar al usuario:

```gdscript
# Tiempo minimo entre intersticiales
const INTERSTITIAL_COOLDOWN_SECONDS: float = 60.0

# Numero de acciones entre intersticiales
const GAMES_BETWEEN_INTERSTITIALS: int = 3
```

### 7.2: Cuando mostrar cada tipo

| Tipo | Cuando mostrar |
|------|----------------|
| **Banner** | Siempre visible en la parte inferior |
| **Interstitial** | Despues de completar un nivel, cada 3 merges grandes |
| **Rewarded** | Cuando el usuario quiere energia gratis (boton opcional) |

### 7.3: Implementar en la UI

Para mostrar el boton de "Ver video por energia":

```gdscript
# En tu UI panel
func _on_watch_ad_button_pressed():
    if AdsManager.is_rewarded_ad_ready():
        AdsManager.show_rewarded_ad()
    else:
        # Mostrar mensaje "Anuncio no disponible"
        pass

# Conectar señal para actualizar UI cuando se gana recompensa
func _ready():
    AdsManager.rewarded_earned.connect(_on_reward_earned)

func _on_reward_earned(reward_type: String, amount: int):
    # Actualizar UI mostrando la energia ganada
    show_reward_popup("+%d Energy!" % amount)
```

### 7.4: Opcion "Remove Ads"

La compra "no_ads" ($2.99) elimina:
- Banner ads
- Interstitial ads

**NO elimina**: Rewarded ads (porque el usuario los ve voluntariamente)

---

## 8. Ingresos Esperados

### eCPM tipico (ingresos por 1000 impresiones)

| Tipo | eCPM aproximado |
|------|-----------------|
| Banner | $0.10 - $0.50 |
| Interstitial | $1.00 - $5.00 |
| Rewarded | $5.00 - $15.00 |

### Ejemplo de calculo

Con 1000 usuarios activos diarios:
- Banners: ~$0.30/dia
- Intersticiales (3/usuario): ~$10/dia
- Rewarded (1/usuario, 30% ven): ~$4/dia
- **Total estimado**: ~$14/dia = ~$420/mes

*Nota: Estos son estimados muy aproximados. Los ingresos reales varian mucho.*

---

## 9. Checklist Final

- [ ] Cuenta de AdMob creada y verificada
- [ ] App creada en AdMob Console
- [ ] 3 Ad Units creados (banner, interstitial, rewarded)
- [ ] Plugin de AdMob instalado en Godot (./setup_ads.sh)
- [ ] Plugin habilitado en Project Settings
- [ ] IDs de prueba probados en dispositivo
- [ ] IDs reales configurados en ads_manager.gd
- [ ] FORCE_SIMULATE = false para produccion
- [ ] Probado que "no_ads" elimina banners e intersticiales

---

## 10. Politicas de AdMob

### Requisitos importantes

1. **No hagas clic en tus propios anuncios** - Causa ban permanente
2. **No pidas a usuarios que hagan clic** - Viola politicas
3. **Declara el uso de ads en la politica de privacidad**
4. **No muestres ads a menores de 13 años sin consentimiento parental**

### Cumplimiento GDPR/CCPA

Para usuarios de EU/California, debes:
1. Mostrar dialogo de consentimiento antes de mostrar ads personalizados
2. Permitir optar por ads no personalizados

El plugin de AdMob incluye soporte para esto, pero requiere configuracion adicional.

---

## Troubleshooting

### "Ad failed to load"
- Verifica conexion a internet
- Los IDs de prueba siempre funcionan
- Si usas IDs reales, espera 1-2 horas despues de crear el ad unit

### "No fill"
- Normal con trafico bajo
- AdMob no siempre tiene anuncios para todos los usuarios
- Implementa retry logic (ya incluido en AdsManager)

### Banners no aparecen
- Verifica que `ads_removed` no sea true
- Verifica que el plugin este habilitado
- Revisa los logs: `adb logcat | grep -i admob`

### Rewarded no da recompensa
- La recompensa solo se da si el usuario ve el video completo
- Si cierra antes, no hay recompensa (es normal)

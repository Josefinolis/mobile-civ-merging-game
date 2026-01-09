#!/bin/bash
# Script para configurar Google Play Billing en el proyecto
# Ejecutar desde la raiz del proyecto: ./setup_billing.sh

set -e

echo "=== Configuracion de Google Play Billing para Merge Town ==="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${YELLOW}Paso 1: Creando estructura de directorios...${NC}"
mkdir -p android/plugins
mkdir -p android/build
echo -e "${GREEN}OK${NC}"

echo ""
echo -e "${YELLOW}Paso 2: Descargando plugin Godot Google Play Billing...${NC}"

# URL del plugin oficial (Godot 4.x)
# Repo: https://github.com/godot-sdk-integrations/godot-google-play-billing
PLUGIN_URL="https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/download/3.1.0/GodotGooglePlayBilling.zip"
PLUGIN_ZIP="/tmp/GodotGooglePlayBilling.zip"

if [ -f "android/plugins/GodotGooglePlayBilling/plugin.cfg" ]; then
    echo -e "${GREEN}Plugin ya instalado, saltando descarga${NC}"
else
    echo "Descargando desde $PLUGIN_URL..."
    curl -L -o "$PLUGIN_ZIP" "$PLUGIN_URL" 2>/dev/null || wget -O "$PLUGIN_ZIP" "$PLUGIN_URL"

    echo "Extrayendo plugin..."
    unzip -o "$PLUGIN_ZIP" -d android/plugins/
    rm -f "$PLUGIN_ZIP"
    echo -e "${GREEN}Plugin instalado correctamente${NC}"
fi

echo ""
echo -e "${YELLOW}Paso 3: Verificando estructura...${NC}"

# Verificar archivos del plugin
if [ -f "android/plugins/GodotGooglePlayBilling/plugin.cfg" ]; then
    echo -e "${GREEN}[OK] plugin.cfg${NC}"
else
    echo -e "${RED}[FALTA] plugin.cfg${NC}"
fi

if [ -f "android/plugins/GodotGooglePlayBilling/bin/release/GodotGooglePlayBilling-release.aar" ]; then
    echo -e "${GREEN}[OK] GodotGooglePlayBilling-release.aar${NC}"
else
    echo -e "${RED}[FALTA] GodotGooglePlayBilling-release.aar${NC}"
fi

if [ -f "android/plugins/GodotGooglePlayBilling/BillingClient.gd" ]; then
    echo -e "${GREEN}[OK] BillingClient.gd${NC}"
else
    echo -e "${RED}[FALTA] BillingClient.gd${NC}"
fi

echo ""
echo -e "${YELLOW}Paso 4: Creando archivo de configuracion de build...${NC}"

# Crear build.gradle si no existe
if [ ! -f "android/build/build.gradle" ]; then
    cat > android/build/build.gradle << 'EOF'
// Este archivo se genera automaticamente
// Configuracion adicional para Android build

android {
    defaultConfig {
        // Configuracion IAP
        multiDexEnabled true
    }
}

dependencies {
    // Google Play Billing Library
    implementation 'com.android.billingclient:billing:6.0.1'
}
EOF
    echo -e "${GREEN}build.gradle creado${NC}"
else
    echo "build.gradle ya existe"
fi

echo ""
echo "=== Configuracion completada ==="
echo ""
echo -e "${YELLOW}Proximos pasos:${NC}"
echo "1. Abre Godot y ve a Project > Project Settings > Plugins"
echo "2. Habilita 'Godot Google Play Billing'"
echo "3. Ve a Project > Export y configura Android:"
echo "   - Marca el permiso BILLING"
echo "   - Marca el plugin 'Godot Google Play Billing'"
echo "4. Sigue la guia en GOOGLE_PLAY_SETUP.md para configurar Google Play Console"
echo ""
echo -e "${GREEN}Estructura creada:${NC}"
find android -type f 2>/dev/null | head -20

echo ""
echo -e "${YELLOW}IMPORTANTE: Antes de publicar, cambia DEBUG_MODE a false en:${NC}"
echo "scripts/autoload/iap_manager.gd linea 34"

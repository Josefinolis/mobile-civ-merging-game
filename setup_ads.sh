#!/bin/bash
# Script para configurar AdMob en el proyecto
# Ejecutar desde la raiz del proyecto: ./setup_ads.sh

set -e

echo "=== Configuracion de AdMob para Merge Town ==="
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
mkdir -p addons
echo -e "${GREEN}OK${NC}"

echo ""
echo -e "${YELLOW}Paso 2: Descargando plugin Godot AdMob...${NC}"

# Plugin de Poing Studios (el mas usado para Godot 4)
# Repo: https://github.com/poing-studios/godot-admob-plugin
PLUGIN_VERSION="3.1.3"
PLUGIN_URL="https://github.com/poing-studios/godot-admob-plugin/archive/refs/tags/v${PLUGIN_VERSION}.zip"
PLUGIN_ZIP="/tmp/godot-admob-plugin.zip"

if [ -d "addons/admob" ]; then
    echo -e "${GREEN}Plugin ya instalado, saltando descarga${NC}"
else
    echo "Descargando desde $PLUGIN_URL..."
    curl -L -o "$PLUGIN_ZIP" "$PLUGIN_URL" 2>/dev/null || wget -O "$PLUGIN_ZIP" "$PLUGIN_URL"

    echo "Extrayendo plugin..."
    unzip -o "$PLUGIN_ZIP" -d /tmp/

    # Copiar el addon
    if [ -d "/tmp/godot-admob-plugin-${PLUGIN_VERSION}/addons/admob" ]; then
        cp -r "/tmp/godot-admob-plugin-${PLUGIN_VERSION}/addons/admob" addons/
        echo -e "${GREEN}Addon copiado a addons/admob${NC}"
    fi

    # Copiar los plugins de Android si existen
    if [ -d "/tmp/godot-admob-plugin-${PLUGIN_VERSION}/android/plugins" ]; then
        cp -r /tmp/godot-admob-plugin-${PLUGIN_VERSION}/android/plugins/* android/plugins/ 2>/dev/null || true
        echo -e "${GREEN}Plugins de Android copiados${NC}"
    fi

    # Limpiar
    rm -f "$PLUGIN_ZIP"
    rm -rf "/tmp/godot-admob-plugin-${PLUGIN_VERSION}"

    echo -e "${GREEN}Plugin instalado correctamente${NC}"
fi

echo ""
echo -e "${YELLOW}Paso 3: Verificando estructura...${NC}"

# Verificar archivos
if [ -d "addons/admob" ]; then
    echo -e "${GREEN}[OK] addons/admob/${NC}"
else
    echo -e "${RED}[FALTA] addons/admob/${NC}"
fi

echo ""
echo "=== Configuracion completada ==="
echo ""
echo -e "${YELLOW}Proximos pasos:${NC}"
echo "1. Abre Godot y ve a Project > Project Settings > Plugins"
echo "2. Habilita 'AdMob'"
echo "3. Configura tu App ID de AdMob en las opciones del plugin"
echo "4. Sigue la guia en ADMOB_SETUP.md para configurar AdMob Console"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "- Los Ad Unit IDs en ads_manager.gd son IDs de PRUEBA"
echo "- Reemplazalos con tus IDs reales antes de publicar"
echo ""
echo -e "${GREEN}Estructura creada:${NC}"
find addons -type f 2>/dev/null | head -10 || echo "No addons found"
find android/plugins -type f 2>/dev/null | head -10 || echo "No android plugins found"

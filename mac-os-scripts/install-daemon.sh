#!/bin/bash
# Script de instalación del Focus Daemon
# Este script configura el daemon para que se ejecute automáticamente al iniciar macOS

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLIST_NAME="com.focus.daemon.plist"
PLIST_SOURCE="$SCRIPT_DIR/$PLIST_NAME"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "🔧 Instalando Focus Daemon..."
echo ""

# Verificar que el archivo plist existe
if [ ! -f "$PLIST_SOURCE" ]; then
    echo "❌ Error: No se encuentra el archivo $PLIST_NAME"
    exit 1
fi

# Crear el directorio LaunchAgents si no existe
if [ ! -d "$LAUNCH_AGENTS_DIR" ]; then
    echo "📁 Creando directorio LaunchAgents..."
    mkdir -p "$LAUNCH_AGENTS_DIR"
fi

# Detener el daemon si ya está corriendo
if launchctl list | grep -q "com.focus.daemon"; then
    echo "🛑 Deteniendo daemon existente..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Copiar el archivo plist
echo "📋 Copiando archivo de configuración..."
cp "$PLIST_SOURCE" "$PLIST_DEST"

# Hacer ejecutables los scripts
echo "🔐 Configurando permisos..."
chmod +x "$SCRIPT_DIR/daemon.py"
chmod +x "$SCRIPT_DIR/toggle-focus.sh"
chmod +x "$SCRIPT_DIR/get-token.sh"

# Cargar el daemon
echo "🚀 Iniciando daemon..."
launchctl load "$PLIST_DEST"

# Esperar un momento para que el daemon inicie
sleep 2

# Obtener el token generado
TOKEN_FILE="$SCRIPT_DIR/.focus_token"
if [ -f "$TOKEN_FILE" ]; then
    AUTH_TOKEN=$(cat "$TOKEN_FILE")
fi

# Verificar que está corriendo
if launchctl list | grep -q "com.focus.daemon"; then
    echo ""
    echo "✅ ¡Focus Daemon instalado correctamente!"
    echo ""
    echo "📍 El daemon está corriendo en: http://0.0.0.0:23126"
    echo "🔒 Autenticación: Requerida"
    echo ""
    if [ -n "$AUTH_TOKEN" ]; then
        echo "🔑 TOKEN DE AUTENTICACIÓN:"
        echo "   $AUTH_TOKEN"
        echo ""
        echo "⚠️  IMPORTANTE: Guarda este token de forma segura."
        echo "   Lo necesitarás para hacer peticiones al daemon."
        echo ""
    fi
    echo "📝 Logs: /tmp/focus-daemon.log"
    echo "❌ Errores: /tmp/focus-daemon.error.log"
    echo ""
    echo "Comandos útiles:"
    echo "  • Ver token: ./get-token.sh"
    echo "  • Ver logs: tail -f /tmp/focus-daemon.log"
    echo "  • Reiniciar: launchctl unload \"$PLIST_DEST\" && launchctl load \"$PLIST_DEST\""
    echo "  • Detener: launchctl unload \"$PLIST_DEST\""
    echo "  • Estado: launchctl list | grep focus"
    echo ""
    echo "Endpoints disponibles (requieren token):"
    echo "  • GET  http://localhost:23126/status"
    echo "  • POST http://localhost:23126/toggle"
    echo "  • POST http://localhost:23126/on"
    echo "  • POST http://localhost:23126/off"
    echo ""
    echo "Ejemplo de uso:"
    if [ -n "$AUTH_TOKEN" ]; then
        echo "  curl -H \"Authorization: Bearer $AUTH_TOKEN\" http://localhost:23126/status"
    else
        echo "  curl -H \"Authorization: Bearer <TOKEN>\" http://localhost:23126/status"
    fi
else
    echo ""
    echo "⚠️  El daemon no se inició correctamente."
    echo "Revisa los logs en /tmp/focus-daemon.error.log"
    exit 1
fi

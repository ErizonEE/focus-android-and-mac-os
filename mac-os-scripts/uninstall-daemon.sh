#!/bin/bash
# Script de desinstalación del Focus Daemon

set -e

PLIST_NAME="com.focus.daemon.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "🗑️  Desinstalando Focus Daemon..."
echo ""

# Verificar si el daemon está instalado
if [ ! -f "$PLIST_DEST" ]; then
    echo "⚠️  El daemon no está instalado."
    exit 0
fi

# Detener el daemon
if launchctl list | grep -q "com.focus.daemon"; then
    echo "🛑 Deteniendo daemon..."
    launchctl unload "$PLIST_DEST"
fi

# Eliminar el archivo plist
echo "🗑️  Eliminando archivo de configuración..."
rm -f "$PLIST_DEST"

# Limpiar archivos temporales (opcional)
read -p "¿Eliminar archivos de logs? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Limpiando logs..."
    rm -f /tmp/focus-daemon.log
    rm -f /tmp/focus-daemon.error.log
    rm -f /tmp/focus_mode_state
fi

echo ""
echo "✅ Focus Daemon desinstalado correctamente."

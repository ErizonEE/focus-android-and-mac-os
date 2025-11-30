#!/bin/bash
# Toggle Focus Mode usando shortcuts CLI y tracking de estado
STATE_FILE="/tmp/focus_mode_state"

# Verifica si shortcuts CLI está disponible
if ! command -v shortcuts &> /dev/null; then
    echo "Error: El comando 'shortcuts' no está disponible"
    exit 1
fi

# Lee el estado anterior (si existe)
if [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(cat "$STATE_FILE")
else
    CURRENT_STATE="off"
fi

# Alterna el estado
if [ "$CURRENT_STATE" = "on" ]; then
    shortcuts run "FocusOff" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "off" > "$STATE_FILE"
        echo "✓ Modo Enfoque DESACTIVADO"
        osascript -e 'display notification "Modo Enfoque desactivado" with title "Focus Toggle"' 2>/dev/null
    else
        echo "Error al ejecutar FocusOff"
        exit 1
    fi
else
    shortcuts run "FocusOn" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "on" > "$STATE_FILE"
        echo "✓ Modo Enfoque ACTIVADO"
        osascript -e 'display notification "Modo Enfoque activado" with title "Focus Toggle"' 2>/dev/null
    else
        echo "Error al ejecutar FocusOn"
        exit 1
    fi
fi

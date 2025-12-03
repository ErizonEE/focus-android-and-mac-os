#!/bin/bash
# Script para obtener el token de autenticación del daemon

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOKEN_FILE="$SCRIPT_DIR/.focus_token"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "❌ Error: El token no existe."
    echo "Ejecuta ./install-daemon.sh primero para generar el token."
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

echo "🔑 Token de autenticación:"
echo ""
echo "   $TOKEN"
echo ""
echo "Úsalo en tus peticiones HTTP:"
echo "   Authorization: Bearer $TOKEN"
echo ""
echo "Ejemplo con curl:"
echo "   curl -H \"Authorization: Bearer $TOKEN\" http://localhost:23126/status"

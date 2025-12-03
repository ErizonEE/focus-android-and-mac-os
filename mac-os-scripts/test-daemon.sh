#!/bin/bash
# Script de prueba para el daemon con autenticación

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOKEN_FILE="$SCRIPT_DIR/.focus_token"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "❌ Error: El token no existe."
    echo "Ejecuta ./install-daemon.sh primero."
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")
BASE_URL="http://localhost:23126"

echo "🧪 Probando Focus Daemon con autenticación"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Función para hacer peticiones
make_request() {
    local method=$1
    local endpoint=$2
    local description=$3
    
    echo "📍 $description"
    echo "   Endpoint: $method $endpoint"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo "   ✅ Status: $http_code"
        echo "   Response: $body"
    else
        echo "   ❌ Status: $http_code"
        echo "   Response: $body"
    fi
    echo ""
}

# Prueba 1: Sin autenticación (debería fallar)
echo "🔒 Prueba 1: Sin autenticación (debería fallar)"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/status")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" = "401" ]; then
    echo "   ✅ Correctamente rechazada (401)"
else
    echo "   ❌ Error: debería ser 401, fue $http_code"
fi
echo "   Response: $body"
echo ""

# Prueba 2: Con token correcto
echo "🔓 Prueba 2: Con autenticación válida"
echo ""

make_request "GET" "/status" "Obtener estado actual"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Pruebas completadas"
echo ""
echo "Para probar toggle/on/off, ejecuta manualmente:"
echo "  curl -X POST -H \"Authorization: Bearer $TOKEN\" $BASE_URL/toggle"
echo "  curl -X POST -H \"Authorization: Bearer $TOKEN\" $BASE_URL/on"
echo "  curl -X POST -H \"Authorization: Bearer $TOKEN\" $BASE_URL/off"

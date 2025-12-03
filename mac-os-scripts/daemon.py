#!/usr/bin/env python3
"""
Daemon para controlar el modo Focus de macOS desde Android Auto
Escucha en 0.0.0.0:23126 y ejecuta los shortcuts de macOS
"""

import http.server
import socketserver
import subprocess
import json
import os
import secrets
from pathlib import Path

PORT = 23126
HOST = "0.0.0.0"
STATE_FILE = "/tmp/focus_mode_state"
SCRIPT_DIR = Path(__file__).parent
TOGGLE_SCRIPT = SCRIPT_DIR / "toggle-focus.sh"
TOKEN_FILE = SCRIPT_DIR / ".focus_token"

# Generar o cargar el token de autenticación
def load_or_generate_token():
    """Carga el token existente o genera uno nuevo"""
    if TOKEN_FILE.exists():
        with open(TOKEN_FILE, "r") as f:
            token = f.read().strip()
            if token:
                return token
    
    # Generar nuevo token seguro
    token = secrets.token_urlsafe(32)
    with open(TOKEN_FILE, "w") as f:
        f.write(token)
    os.chmod(TOKEN_FILE, 0o600)  # Solo lectura/escritura para el propietario
    return token

AUTH_TOKEN = load_or_generate_token()


class FocusHandler(http.server.BaseHTTPRequestHandler):
    """Manejador de peticiones HTTP para controlar Focus Mode"""
    
    def _set_headers(self, status=200, content_type="application/json"):
        """Configura los headers de la respuesta"""
        self.send_response(status)
        self.send_header("Content-type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
    
    def _check_auth(self):
        """Verifica el token de autenticación"""
        auth_header = self.headers.get("Authorization")
        if not auth_header:
            return False
        
        # Soporta formato: "Bearer <token>" o solo "<token>"
        token = auth_header.replace("Bearer ", "").strip()
        return token == AUTH_TOKEN
    
    def _send_unauthorized(self):
        """Envía respuesta de no autorizado"""
        self._set_headers(401)
        response = {
            "error": "Unauthorized",
            "message": "Token de autenticación inválido o faltante"
        }
        self.wfile.write(json.dumps(response).encode())
    
    def do_OPTIONS(self):
        """Maneja peticiones OPTIONS para CORS"""
        self._set_headers(204)
    
    def do_GET(self):
        """Maneja peticiones GET - retorna el estado actual"""
        if self.path == "/status":
            # Verificar autenticación
            if not self._check_auth():
                self._send_unauthorized()
                return
            
            state = self._get_current_state()
            self._set_headers()
            response = {"status": "ok", "focus_mode": state}
            self.wfile.write(json.dumps(response).encode())
        elif self.path == "/":
            # Página de información (sin autenticación)
            self._set_headers(200, "text/html")
            html = """
            <html>
            <head><title>Focus Daemon</title></head>
            <body>
                <h1>Focus Mode Daemon</h1>
                <p>🔒 Este servidor requiere autenticación mediante token</p>
                <p>Endpoints disponibles:</p>
                <ul>
                    <li>GET /status - Obtener estado actual (requiere auth)</li>
                    <li>POST /toggle - Alternar modo Focus (requiere auth)</li>
                    <li>POST /on - Activar modo Focus (requiere auth)</li>
                    <li>POST /off - Desactivar modo Focus (requiere auth)</li>
                </ul>
                <p>Incluye el header: <code>Authorization: Bearer &lt;token&gt;</code></p>
            </body>
            </html>
            """
            self.wfile.write(html.encode())
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "Not found"}).encode())
    
    def do_POST(self):
        """Maneja peticiones POST - ejecuta acciones"""
        # Verificar autenticación para todos los endpoints POST
        if not self._check_auth():
            self._send_unauthorized()
            return
        
        if self.path == "/toggle":
            result = self._toggle_focus()
            self._set_headers()
            self.wfile.write(json.dumps(result).encode())
        elif self.path == "/on":
            result = self._set_focus("on")
            self._set_headers()
            self.wfile.write(json.dumps(result).encode())
        elif self.path == "/off":
            result = self._set_focus("off")
            self._set_headers()
            self.wfile.write(json.dumps(result).encode())
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "Not found"}).encode())
    
    def _get_current_state(self):
        """Lee el estado actual del archivo de estado"""
        try:
            if os.path.exists(STATE_FILE):
                with open(STATE_FILE, "r") as f:
                    return f.read().strip()
            return "off"
        except Exception as e:
            print(f"Error leyendo estado: {e}")
            return "unknown"
    
    def _toggle_focus(self):
        """Alterna el estado del modo Focus"""
        try:
            result = subprocess.run(
                [str(TOGGLE_SCRIPT)],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            new_state = self._get_current_state()
            
            if result.returncode == 0:
                return {
                    "status": "ok",
                    "action": "toggle",
                    "focus_mode": new_state,
                    "message": result.stdout.strip()
                }
            else:
                return {
                    "status": "error",
                    "message": result.stderr.strip() or "Error ejecutando toggle"
                }
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def _set_focus(self, desired_state):
        """Establece el modo Focus a un estado específico"""
        current_state = self._get_current_state()
        
        if current_state == desired_state:
            return {
                "status": "ok",
                "action": "none",
                "focus_mode": current_state,
                "message": f"Modo Focus ya está {desired_state}"
            }
        
        # Si el estado es diferente, hacer toggle
        return self._toggle_focus()
    
    def log_message(self, format, *args):
        """Sobrescribe el log para formato personalizado"""
        print(f"[{self.log_date_time_string()}] {format % args}")


def main():
    """Inicia el servidor daemon"""
    # Hacer el script toggle-focus.sh ejecutable
    if TOGGLE_SCRIPT.exists():
        os.chmod(TOGGLE_SCRIPT, 0o755)
    
    with socketserver.TCPServer((HOST, PORT), FocusHandler) as httpd:
        print(f"🚀 Focus Daemon iniciado en http://{HOST}:{PORT}")
        print(f"🔒 Token de autenticación: {AUTH_TOKEN}")
        print(f"📂 Script de toggle: {TOGGLE_SCRIPT}")
        print(f"📄 Archivo de estado: {STATE_FILE}")
        print(f"🔑 Token guardado en: {TOKEN_FILE}")
        print("\n⚠️  IMPORTANTE: Guarda este token de forma segura.")
        print("    Úsalo en el header: Authorization: Bearer <token>\n")
        print("Presiona Ctrl+C para detener el servidor\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n👋 Deteniendo el servidor...")
            httpd.shutdown()


if __name__ == "__main__":
    main()


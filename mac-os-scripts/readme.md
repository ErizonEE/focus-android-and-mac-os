# Focus Mode Daemon para macOS

Este daemon permite controlar el modo Focus de macOS desde aplicaciones externas (como Android Auto) mediante una API HTTP simple.

## 📋 Requisitos Previos

### 1. Configurar Shortcuts de macOS

Es necesario crear 2 shortcuts en la app Shortcuts de macOS:

- **FocusOn** → Activa el modo enfoque
- **FocusOff** → Desactiva el modo enfoque

Para crearlos:
1. Abre la app **Shortcuts** (Atajos)
2. Crea un nuevo shortcut llamado exactamente `FocusOn`
3. Agrega la acción: "Set Focus" → Activar el modo que desees
4. Crea otro shortcut llamado exactamente `FocusOff`
5. Agrega la acción: "Set Focus" → Desactivar

### 2. Python 3

El daemon requiere Python 3, que viene preinstalado en macOS.

## 🚀 Instalación

Para instalar el daemon y configurarlo para que se ejecute automáticamente al iniciar tu Mac:

```bash
cd /Users/naranjax/AndroidStudioProjects/Focus/mac-os-scripts
chmod +x install-daemon.sh
./install-daemon.sh
```

El daemon comenzará a ejecutarse inmediatamente y se iniciará automáticamente cada vez que arranques tu Mac.

**⚠️ IMPORTANTE:** Durante la instalación se generará un **token de autenticación** único. Guárdalo de forma segura, lo necesitarás para hacer peticiones al daemon.

### 🔑 Obtener el token de autenticación

Si necesitas ver el token nuevamente:

```bash
./get-token.sh
```

O manualmente:

```bash
cat .focus_token
```

## 🌐 API Endpoints

El daemon escucha en `http://0.0.0.0:23126` (accesible desde cualquier dispositivo en tu red local).

**🔒 Todos los endpoints requieren autenticación mediante token en el header:**

```
Authorization: Bearer <tu-token-aquí>
```

### GET /status
Obtiene el estado actual del modo Focus.

**Request:**
```bash
curl -H "Authorization: Bearer <TOKEN>" http://localhost:23126/status
```

**Respuesta:**
```json
{
  "status": "ok",
  "focus_mode": "on"
}
```

### POST /toggle
Alterna el estado del modo Focus (on ↔ off).

**Request:**
```bash
curl -X POST -H "Authorization: Bearer <TOKEN>" http://localhost:23126/toggle
```

**Respuesta:**
```json
{
  "status": "ok",
  "action": "toggle",
  "focus_mode": "on",
  "message": "✓ Modo Enfoque ACTIVADO"
}
```

### POST /on
Activa el modo Focus (si no está activado).

**Request:**
```bash
curl -X POST -H "Authorization: Bearer <TOKEN>" http://localhost:23126/on
```

**Respuesta:**
```json
{
  "status": "ok",
  "action": "toggle",
  "focus_mode": "on",
  "message": "✓ Modo Enfoque ACTIVADO"
}
```

### POST /off
Desactiva el modo Focus (si está activado).

**Request:**
```bash
curl -X POST -H "Authorization: Bearer <TOKEN>" http://localhost:23126/off
```

**Respuesta:**
```json
{
  "status": "ok",
  "action": "toggle",
  "focus_mode": "off",
  "message": "✓ Modo Enfoque DESACTIVADO"
}
```

### Respuesta de error (sin autenticación)

**Respuesta:**
```json
{
  "error": "Unauthorized",
  "message": "Token de autenticación inválido o faltante"
}
```

## 🧪 Pruebas

Primero obtén tu token:

```bash
./get-token.sh
```

### Script de prueba automático

Ejecuta el script de prueba para verificar que todo funciona:

```bash
./test-daemon.sh
```

Este script probará:
- ✅ Que las peticiones sin autenticación son rechazadas (401)
- ✅ Que las peticiones con autenticación funcionan correctamente (200)

### Pruebas manuales

Luego puedes probar el daemon con curl (reemplaza `<TOKEN>` con tu token real):

```bash
# Ver estado actual
curl -H "Authorization: Bearer <TOKEN>" http://localhost:23126/status

# Alternar modo Focus
curl -X POST -H "Authorization: Bearer <TOKEN>" http://localhost:23126/toggle

# Activar modo Focus
curl -X POST -H "Authorization: Bearer <TOKEN>" http://localhost:23126/on

# Desactivar modo Focus
curl -X POST -H "Authorization: Bearer <TOKEN>" http://localhost:23126/off
```

## 📊 Logs y Monitoreo

Ver los logs en tiempo real:
```bash
tail -f /tmp/focus-daemon.log
```

Ver errores:
```bash
tail -f /tmp/focus-daemon.error.log
```

Verificar estado del daemon:
```bash
launchctl list | grep focus
```

## 🔧 Gestión del Daemon

### Reiniciar el daemon
```bash
launchctl unload ~/Library/LaunchAgents/com.focus.daemon.plist
launchctl load ~/Library/LaunchAgents/com.focus.daemon.plist
```

### Detener temporalmente
```bash
launchctl unload ~/Library/LaunchAgents/com.focus.daemon.plist
```

### Iniciar manualmente
```bash
launchctl load ~/Library/LaunchAgents/com.focus.daemon.plist
```

### Desinstalar completamente
```bash
chmod +x uninstall-daemon.sh
./uninstall-daemon.sh
```

## 📱 Integración con Android Auto

Desde tu app de Android, puedes hacer peticiones HTTP a:
- `http://<IP-DE-TU-MAC>:23126/toggle`
- `http://<IP-DE-TU-MAC>:23126/on`
- `http://<IP-DE-TU-MAC>:23126/off`

**⚠️ No olvides incluir el token de autenticación en el header:**
```
Authorization: Bearer <tu-token>
```

Para encontrar la IP de tu Mac: `ifconfig | grep "inet " | grep -v 127.0.0.1`

## 🔒 Seguridad

### Token de autenticación

- El daemon genera automáticamente un token seguro de 32 bytes
- El token se guarda en `.focus_token` (permisos 600 - solo lectura/escritura para el propietario)
- Todas las peticiones requieren el header: `Authorization: Bearer <token>`
- Si pierdes el token, puedes verlo con `./get-token.sh` o regenerarlo reinstalando el daemon

### Red local

El daemon escucha en todas las interfaces (`0.0.0.0`), lo que significa que cualquier dispositivo en tu red local puede acceder a él **si tiene el token**. 

Si quieres restringir el acceso solo a localhost, edita `daemon.py` y cambia:

```python
HOST = "0.0.0.0"  # Accesible desde la red
```

por:

```python
HOST = "127.0.0.1"  # Solo accesible localmente
```

### Buenas prácticas

- No compartas tu token públicamente
- No expongas el puerto 23126 a Internet
- Si necesitas acceso remoto, usa una VPN
- El archivo `.focus_token` está en el `.gitignore` para evitar commits accidentales

## 📁 Archivos

- `daemon.py` - Servidor HTTP que maneja las peticiones
- `toggle-focus.sh` - Script que ejecuta los shortcuts de macOS
- `com.focus.daemon.plist` - Configuración de LaunchAgent
- `install-daemon.sh` - Script de instalación
- `uninstall-daemon.sh` - Script de desinstalación
- `get-token.sh` - Script para ver el token de autenticación
- `test-daemon.sh` - Script para probar el daemon con autenticación
- `.focus_token` - Archivo que almacena el token (no se debe subir a git)
- `.gitignore` - Evita que el token se suba a git


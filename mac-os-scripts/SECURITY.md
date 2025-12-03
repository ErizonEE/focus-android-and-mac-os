# 🔒 Seguridad del Focus Daemon

## Resumen de las medidas de seguridad implementadas

### 1. Autenticación mediante Token Bearer

- **Token seguro**: Se genera automáticamente usando `secrets.token_urlsafe(32)` de Python
- **32 bytes de entropía**: Token criptográficamente seguro con 256 bits de entropía
- **Verificación en cada petición**: Todos los endpoints POST y GET (excepto `/`) requieren autenticación
- **Formato estándar**: Usa el formato Bearer Token según RFC 6750

### 2. Protección del Token

- **Archivo protegido**: `.focus_token` tiene permisos 600 (solo lectura/escritura para el propietario)
- **No se sube a git**: Incluido en `.gitignore` para evitar exposición accidental
- **Almacenamiento local**: El token solo existe en tu Mac, nunca se transmite a servidores externos

### 3. Validación de Peticiones

El daemon valida:
- ✅ Presencia del header `Authorization`
- ✅ Formato correcto del token (soporta `Bearer <token>` o solo `<token>`)
- ✅ Comparación segura del token
- ❌ Rechaza peticiones sin token con HTTP 401
- ❌ Rechaza tokens inválidos con HTTP 401

### 4. Respuestas de Error

Las respuestas 401 son genéricas y no revelan información sensible:

```json
{
  "error": "Unauthorized",
  "message": "Token de autenticación inválido o faltante"
}
```

### 5. Limitaciones de Red

- **Red local únicamente**: El daemon escucha en `0.0.0.0:23126` pero solo es accesible desde tu red local
- **Sin exposición pública**: No hay forwarding de puertos ni acceso desde Internet
- **Firewall de macOS**: macOS protege automáticamente el puerto

## ⚠️ Consideraciones de Seguridad

### Lo que PROTEGE este sistema:

✅ Acceso no autorizado desde dispositivos en tu red local sin el token  
✅ Exposición accidental del token en repositorios git  
✅ Ejecución no autorizada de comandos desde apps sin el token  
✅ Ataques de fuerza bruta (el token tiene 256 bits de entropía)

### Lo que NO PROTEGE este sistema:

❌ **Malware en tu Mac**: Si tu Mac está comprometida, el atacante puede leer el token  
❌ **Apps maliciosas en Android con el token**: Si compartes el token con una app maliciosa  
❌ **Ataques man-in-the-middle**: Las comunicaciones van en HTTP sin cifrado (solo red local)  
❌ **Acceso físico a tu Mac**: Cualquiera con acceso puede leer `.focus_token`

## 🛡️ Mejores Prácticas

### Para uso personal (recomendado):

1. **Mantén el token privado**: No lo compartas ni lo publiques
2. **Usa solo en tu red confiable**: WiFi de casa o trabajo
3. **Verifica los logs**: Revisa `/tmp/focus-daemon.log` periódicamente
4. **Regenera el token si hay sospecha**: Reinstala el daemon si crees que fue comprometido

### Para uso en producción (si aplica):

1. **Considera HTTPS**: Usa un reverse proxy con certificados SSL/TLS
2. **Rate limiting**: Implementa límites de peticiones por IP
3. **Logging mejorado**: Registra todas las peticiones con IP y timestamp
4. **Rotación de tokens**: Implementa expiración y renovación de tokens
5. **VPN**: Accede solo a través de VPN si necesitas acceso remoto

## 🔄 Regenerar el Token

Si sospechas que tu token fue comprometido:

```bash
# 1. Detener el daemon
launchctl unload ~/Library/LaunchAgents/com.focus.daemon.plist

# 2. Eliminar el token antiguo
rm .focus_token

# 3. Reiniciar el daemon (generará un nuevo token)
launchctl load ~/Library/LaunchAgents/com.focus.daemon.plist

# 4. Obtener el nuevo token
./get-token.sh
```

## 📊 Niveles de Amenaza

| Amenaza | Riesgo | Mitigación |
|---------|--------|------------|
| Acceso no autorizado en red local | **Bajo** | Token requerido para todas las operaciones |
| Robo del token del archivo | **Medio** | Permisos 600, requiere acceso físico o malware |
| Interceptación de tráfico | **Bajo** | Solo red local confiable |
| Exposición en git | **Muy Bajo** | .gitignore protege el archivo |
| Fuerza bruta del token | **Muy Bajo** | 256 bits de entropía = imposible de adivinar |

## 🎯 Conclusión

Este sistema proporciona un nivel de seguridad adecuado para:
- ✅ Uso personal en red doméstica
- ✅ Automatización entre dispositivos propios
- ✅ Protección contra acceso casual no autorizado

No es adecuado para:
- ❌ Servicios expuestos a Internet
- ❌ Ambientes empresariales con requisitos de compliance
- ❌ Manejo de datos sensibles más allá del control del modo Focus

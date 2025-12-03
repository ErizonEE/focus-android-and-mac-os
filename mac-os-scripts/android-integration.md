# Ejemplo de uso desde Android

Para integrar el daemon con tu app de Android, aquí hay ejemplos de código:

## Kotlin (Android)

```kotlin
import okhttp3.*
import kotlinx.coroutines.*

class FocusController(
    private val macIp: String,
    private val authToken: String  // Token de autenticación del daemon
) {
    private val client = OkHttpClient()
    private val baseUrl = "http://$macIp:23126"
    
    // Crear request con autenticación
    private fun buildRequest(url: String, method: String = "GET"): Request {
        val builder = Request.Builder()
            .url(url)
            .addHeader("Authorization", "Bearer $authToken")
        
        if (method == "POST") {
            builder.post(RequestBody.create(null, ByteArray(0)))
        }
        
        return builder.build()
    }
    
    // Obtener estado actual
    suspend fun getStatus(): String? = withContext(Dispatchers.IO) {
        try {
            val request = buildRequest("$baseUrl/status")
            
            client.newCall(request).execute().use { response ->
                if (response.isSuccessful) {
                    response.body?.string()
                } else null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    // Alternar modo Focus
    suspend fun toggleFocus(): String? = withContext(Dispatchers.IO) {
        try {
            val request = buildRequest("$baseUrl/toggle", "POST")
            
            client.newCall(request).execute().use { response ->
                if (response.isSuccessful) {
                    response.body?.string()
                } else null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    // Activar modo Focus
    suspend fun turnOnFocus(): String? = withContext(Dispatchers.IO) {
        try {
            val request = buildRequest("$baseUrl/on", "POST")
            
            client.newCall(request).execute().use { response ->
                if (response.isSuccessful) {
                    response.body?.string()
                } else null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    // Desactivar modo Focus
    suspend fun turnOffFocus(): String? = withContext(Dispatchers.IO) {
        try {
            val request = buildRequest("$baseUrl/off", "POST")
            
            client.newCall(request).execute().use { response ->
                if (response.isSuccessful) {
                    response.body?.string()
                } else null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

// Uso en Android Auto
class FocusService {
    // IMPORTANTE: Reemplaza estos valores con los tuyos
    private val MAC_IP = "192.168.0.3"  // IP de tu Mac
    private val AUTH_TOKEN = "tu-token-aqui"  // Token del daemon
    
    private val focusController = FocusController(MAC_IP, AUTH_TOKEN)
    
    fun handleAndroidAutoConnection() {
        // Cuando Android Auto se conecta
        CoroutineScope(Dispatchers.Main).launch {
            val result = focusController.turnOnFocus()
            Log.d("Focus", "Focus activado: $result")
        }
    }
    
    fun handleAndroidAutoDisconnection() {
        // Cuando Android Auto se desconecta
        CoroutineScope(Dispatchers.Main).launch {
            val result = focusController.turnOffFocus()
            Log.d("Focus", "Focus desactivado: $result")
        }
    }
}
```

## Dependencias necesarias en build.gradle

```gradle
dependencies {
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
}
```

## Permisos en AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Encontrar la IP de tu Mac

En tu Mac, ejecuta:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Busca la línea que muestra algo como: `inet 192.168.1.100 netmask...`
Esa es la IP que debes usar en tu app de Android.

## Obtener el token de autenticación

En tu Mac, ejecuta:
```bash
cd /Users/naranjax/AndroidStudioProjects/Focus/mac-os-scripts
./get-token.sh
```

Este comando te mostrará el token que debes usar en tu app de Android.

## Probando la conexión

Antes de integrar en tu app, prueba manualmente desde un navegador en tu teléfono:
1. Conecta tu teléfono a la misma red WiFi que tu Mac
2. Abre en el navegador: `http://192.168.0.3:23126` (reemplaza con tu IP)
3. Deberías ver la página de información del daemon

Para probar con autenticación, usa una app como Postman o HTTP Request Shortcut:
- URL: `http://192.168.0.3:23126/status`
- Method: GET
- Header: `Authorization: Bearer <tu-token>`

## Consejos de seguridad

- El daemon solo funciona en tu red local
- **Nunca** hagas commit del token en tu código fuente
- Guarda el token en una constante privada o usa SharedPreferences/DataStore
- No expongas el puerto 23126 a Internet
- Si necesitas acceso remoto, considera usar una VPN
- Verifica siempre que estás en la misma red antes de hacer peticiones

## Almacenamiento seguro del token en Android

```kotlin
// Opción 1: Usar BuildConfig (no recomendado para producción)
// En build.gradle.kts:
android {
    buildTypes {
        debug {
            buildConfigField("String", "FOCUS_TOKEN", "\"tu-token-aqui\"")
            buildConfigField("String", "MAC_IP", "\"192.168.0.3\"")
        }
    }
}

// En tu código:
val token = BuildConfig.FOCUS_TOKEN
val macIp = BuildConfig.MAC_IP

// Opción 2: Usar EncryptedSharedPreferences (recomendado)
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

fun saveToken(context: Context, token: String) {
    val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    
    val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        "focus_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    
    sharedPreferences.edit()
        .putString("auth_token", token)
        .apply()
}

fun getToken(context: Context): String? {
    val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    
    val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        "focus_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    
    return sharedPreferences.getString("auth_token", null)
}
```

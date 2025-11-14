# 🧪 Guía de Pruebas para Notificaciones Push

## 📱 Requisitos Previos

- ✅ Dispositivo Android físico (emulador tiene limitaciones con FCM)
- ✅ Google Play Services instalado
- ✅ Conexión a internet
- ✅ App compilada y ejecutándose

---

## 🚀 Pasos para Probar

### 1. Compilar y Ejecutar la App

```bash
# Navegar al directorio del proyecto
cd "c:\Users\RAFAEL CORREDOR G\Desktop\app\FD_monitorUnicor_Universidad_De_Cordoba-main"

# Conectar dispositivo Android via USB
# Habilitar depuración USB en el dispositivo

# Verificar dispositivo conectado
flutter devices

# Ejecutar la app en modo debug
flutter run

# O compilar APK de release
flutter build apk --release
```

### 2. Verificar Inicialización

Al arrancar la app, busca estos logs en la consola:

```
✅ FCM Service initialized successfully
🔑 FCM Token: eICCc5K6zvMYOlldkYSlkG:APA91b...
📤 Registering token with backend: {token: ..., deviceId: ..., platform: android}
✅ Token registered successfully
🔌 Connecting to WebSocket: ws://ec2-98-86-100-220...
✅ WebSocket connected successfully
📤 WebSocket message sent: {type: registerToken, ...}
```

**Si todo está OK, continúa. Si hay errores, verifica la configuración.**

### 3. Obtener el Token FCM

Hay dos formas:

#### Opción A: Desde la UI
1. Abre la app
2. En la pantalla principal hay un botón "Mostrar token FCM"
3. Presiona el botón
4. Aparecerá un SnackBar con el token
5. Copia el token

#### Opción B: Desde los Logs
1. Busca en los logs de Flutter:
   ```
   🔑 FCM Token: eICCc5K6zvMYOlldkYSlkG:APA91b...
   ```
2. Copia todo el texto después de "FCM Token: "

**⚠️ IMPORTANTE:** El token es largo (~150-200 caracteres), asegúrate de copiarlo completo.

---

## 🎯 Pruebas por Estado de la App

### Prueba 1: App en Foreground (Abierta y Visible)

**Configuración:**
- App abierta y visible en la pantalla

**Enviar Notificación:**

Usa uno de estos métodos:

#### A) Desde Firebase Console (Más fácil)

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona `monitoring-system-f50e6`
3. **Messaging** → **Send your first message**
4. En "Notification text": `Temperatura fuera de rango`
5. En "Notification title": `Alerta de Sensor`
6. Click **Send test message**
7. Pega tu token FCM
8. Click **Test**

**⚠️ Importante:** Para que funcione con data, usa curl (método B)

#### B) Con curl (Recomendado)

**Necesitas la Server Key de Firebase:**
1. Firebase Console → Project Settings → Cloud Messaging
2. Copia la "Server key" (legacy)

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=TU_SERVER_KEY_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "TU_TOKEN_FCM_AQUI",
    "priority": "high",
    "data": {
      "event": "sensorAlert",
      "deviceId": "ESP321",
      "plantName": "Lavanda demo",
      "sensorType": "temperature",
      "value": "32.5",
      "unit": "C",
      "message": "Temperatura fuera de rango",
      "timestamp": "2025-11-14T15:34:00Z",
      "thresholdType": "max",
      "thresholdValue": "35"
    }
  }'
```

**Resultado Esperado:**
- ✅ Debería aparecer una notificación en la barra de estado
- ✅ En los logs verás:
  ```
  📩 Foreground message received: ...
  📦 Data: {event: sensorAlert, deviceId: ESP321, ...}
  ```
- ✅ La notificación muestra: "sensorAlert" como título y "Temperatura fuera de rango" como mensaje

**Tocar la Notificación:**
- Al tocar, verás en los logs:
  ```
  👆 Notification tapped: {...}
  🎯 Handling notification action: {...}
  ```

---

### Prueba 2: App en Background (Minimizada)

**Configuración:**
1. Abre la app
2. Presiona el botón Home (minimizar)
3. La app debe estar en segundo plano

**Enviar Notificación:**
Usa el mismo comando curl de la Prueba 1.

**Resultado Esperado:**
- ✅ Notificación aparece en la barra de estado
- ✅ Sonido/vibración
- ✅ Al tocar la notificación, la app se abre

**En los logs verás:**
```
🔔 Background message: ...
📦 Data: {event: sensorAlert, ...}
```

**Al tocar la notificación:**
```
🚀 App opened from notification: ...
📦 Data: {event: sensorAlert, ...}
```

---

### Prueba 3: App Terminada (Cerrada Completamente)

**Configuración:**
1. Cierra la app completamente (swipe desde recientes)
2. O usa: `adb shell am force-stop com.example.iot`

**Enviar Notificación:**
Usa el mismo comando curl.

**Resultado Esperado:**
- ✅ Notificación aparece aunque la app esté cerrada
- ✅ Al tocar la notificación, la app se abre

**Al abrir la app, en los logs verás:**
```
🚀 App opened from terminated state: ...
📦 Data: {event: sensorAlert, ...}
```

---

## 🌐 Pruebas de WebSocket

### Verificar Conexión

**En los logs busca:**
```
🔌 Connecting to WebSocket: ws://ec2-98-86-100-220...
✅ WebSocket connected successfully
📤 WebSocket message sent: {type: registerToken, ...}
```

### Probar Desconexión/Reconexión

1. Desactiva WiFi/datos móviles por 10 segundos
2. Reactiva la conexión

**Deberías ver:**
```
❌ WebSocket error: ...
🔌 WebSocket connection closed
🔄 Scheduling reconnect attempt 1 in 5s
🔌 Connecting to WebSocket: ...
✅ WebSocket connected successfully
```

### Enviar Mensaje desde el Backend

Si tienes acceso al backend WebSocket, envía:

```json
{
  "type": "sensorAlert",
  "data": {
    "event": "sensorAlert",
    "deviceId": "ESP321",
    "plantName": "Lavanda demo",
    "sensorType": "temperature",
    "value": "32.5",
    "unit": "C",
    "message": "Temperatura fuera de rango"
  }
}
```

**La app debería mostrar una notificación local.**

---

## 🔍 Verificar en el Backend

### Endpoint HTTP

Verifica que el token llegó al backend:

```bash
# Si tienes acceso al backend, revisa logs
# Deberías ver algo como:
POST /api/notifications/tokens
Body: {
  "token": "eICCc5K6zvMYOlldkYSlkG:...",
  "deviceId": "google_pixel_9_pro",
  "platform": "android"
}
```

### WebSocket

```bash
# En el servidor WebSocket deberías ver:
🔌 New WebSocket connection
✅ Token registered via WebSocket: google_pixel_9_pro
```

---

## 🐛 Troubleshooting Común

### ❌ No recibo notificaciones

**Checklist:**

1. **Permisos de Notificaciones:**
   - Ve a Configuración → Apps → AgroCordIot → Notificaciones
   - Asegúrate que estén habilitadas

2. **Google Play Services:**
   - Verifica que esté actualizado
   - `adb shell dumpsys package com.google.android.gms | grep version`

3. **Token válido:**
   - El token debe empezar con caracteres como `eICCc5K6...` o similar
   - Debe tener 150+ caracteres

4. **Server Key correcta:**
   - Verifica que usaste la Server Key correcta de Firebase Console

5. **Formato del mensaje:**
   - Debe usar `data` (no solo `notification`)
   - Todos los valores en `data` deben ser strings

6. **Conexión a internet:**
   - FCM requiere internet
   - Verifica que el dispositivo tenga conexión

### ❌ Error: "MismatchSenderId"

- El proyecto de Firebase no coincide con el `google-services.json`
- Verifica que usaste el archivo correcto

### ❌ Error: "Invalid Registration Token"

- El token expiró o es inválido
- Desinstala y reinstala la app
- Obtén un nuevo token

### ❌ Notificación llega pero no se muestra

- Verifica que el canal de notificaciones esté creado
- Revisa los logs en `fcm_service.dart:_showLocalNotification`

### ❌ WebSocket no conecta

- Verifica la URL: `ws://ec2-98-86-100-220.compute-1.amazonaws.com:3000`
- Asegúrate que el servidor WebSocket esté corriendo
- Prueba con `wscat`: `wscat -c ws://ec2-98-86-100-220...`

---

## 📊 Comandos Útiles de Depuración

### Logs de Flutter

```bash
# Ver logs en tiempo real
flutter logs

# Filtrar solo logs de FCM
flutter logs | grep -i fcm

# Filtrar logs de notificaciones
flutter logs | grep -i notification
```

### Logs de Android (adb)

```bash
# Ver todos los logs de la app
adb logcat | grep com.example.iot

# Ver logs de Firebase Messaging
adb logcat | grep FirebaseMessaging

# Limpiar cache de la app
adb shell pm clear com.example.iot

# Forzar cierre de la app
adb shell am force-stop com.example.iot

# Ver permisos otorgados
adb shell dumpsys package com.example.iot | grep permission
```

### Verificar Token en el Dispositivo

```bash
# Ver SharedPreferences (donde se podría guardar el token)
adb shell run-as com.example.iot cat shared_prefs/*.xml
```

---

## ✅ Checklist de Pruebas Completas

Marca cada prueba cuando la completes:

- [ ] **Inicialización**
  - [ ] Firebase se inicializa correctamente
  - [ ] Token FCM se obtiene
  - [ ] Token se registra en el backend HTTP
  - [ ] Token se registra por WebSocket

- [ ] **Foreground (App Abierta)**
  - [ ] Notificación se recibe
  - [ ] Notificación se muestra en barra de estado
  - [ ] Al tocar, se ejecuta el callback

- [ ] **Background (App Minimizada)**
  - [ ] Notificación se recibe
  - [ ] Notificación se muestra
  - [ ] Al tocar, app se abre

- [ ] **Terminated (App Cerrada)**
  - [ ] Notificación se recibe
  - [ ] Notificación se muestra
  - [ ] Al tocar, app se abre

- [ ] **WebSocket**
  - [ ] Conexión exitosa
  - [ ] Token se envía
  - [ ] Mensajes se reciben
  - [ ] Reconexión automática funciona

- [ ] **Edge Cases**
  - [ ] Sin internet → reconexión al volver internet
  - [ ] Token refresh → nuevo token se registra
  - [ ] Reinstalar app → nuevo token se genera

---

## 🎉 Test Exitoso

Si todas las pruebas pasaron:

✅ **Firebase está configurado correctamente**
✅ **La app recibe notificaciones en todos los estados**
✅ **El backend puede enviar notificaciones**
✅ **WebSocket está funcionando**

**¡Tu implementación de notificaciones push está completa!** 🚀

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa los logs detalladamente
2. Verifica la configuración en Firebase Console
3. Asegúrate que el `google-services.json` sea el correcto
4. Prueba con el mensaje de ejemplo exacto
5. Verifica que el backend esté corriendo

**Recursos útiles:**
- [Firebase Console](https://console.firebase.google.com/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Testing FCM](https://firebase.google.com/docs/cloud-messaging/flutter/first-message)

---

¡Buena suerte con las pruebas! 🍀

# Configuración de Notificaciones Push con Firebase Cloud Messaging (FCM)

## 📋 Resumen de la Implementación

Se ha implementado completamente el sistema de notificaciones push usando Firebase Cloud Messaging (FCM) para la aplicación AgroCordIot. La app ahora puede recibir notificaciones en tres estados:

- **Foreground** (app abierta y visible)
- **Background** (app abierta pero en segundo plano)
- **Terminated** (app completamente cerrada)

---

## ✅ Cambios Realizados

### 1. Dependencias Agregadas ([pubspec.yaml](pubspec.yaml))

```yaml
dependencies:
  # Firebase
  firebase_core: ^3.8.0
  firebase_messaging: ^15.1.4

  # WebSocket
  web_socket_channel: ^3.0.1

  # Notificaciones locales (ya estaba instalado)
  flutter_local_notifications: ^17.0.0
```

### 2. Configuración de Android

#### [android/build.gradle.kts](android/build.gradle.kts)
Se agregó el plugin de Google Services en el buildscript.

#### [android/app/build.gradle.kts](android/app/build.gradle.kts)
Se aplicó el plugin `com.google.gms.google-services`.

#### [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
Se agregaron:
- Permisos para notificaciones (POST_NOTIFICATIONS, VIBRATE, WAKE_LOCK)
- Metadata de Firebase para icono, color y canal de notificaciones

#### [android/app/google-services.json](android/app/google-services.json)
Ya estaba configurado correctamente.

### 3. Servicios Creados

#### [lib/src/services/fcm_service.dart](lib/src/services/fcm_service.dart)
Servicio completo de FCM que maneja:
- ✅ Inicialización de Firebase y notificaciones locales
- ✅ Solicitud de permisos de notificaciones
- ✅ Obtención y registro del token FCM
- ✅ Manejo de mensajes en foreground, background y terminated
- ✅ Registro del token con el backend HTTP
- ✅ Notificaciones locales personalizadas
- ✅ Subscripción/desubscripción a topics
- ✅ Manejo de refreshed tokens

#### [lib/src/services/websocket_service.dart](lib/src/services/websocket_service.dart)
Servicio de WebSocket para:
- ✅ Conexión persistente con el backend
- ✅ Registro del token FCM via WebSocket
- ✅ Reconexión automática en caso de desconexión
- ✅ Ping periódico para mantener la conexión viva
- ✅ Subscripción a dispositivos específicos

### 4. Integración en Main

#### [lib/main.dart](lib/main.dart)
- ✅ Inicialización de Firebase con opciones de plataforma
- ✅ Registro del handler de mensajes en background
- ✅ Inicialización del servicio FCM
- ✅ Conexión y registro de token via WebSocket

#### [lib/firebase_options.dart](lib/firebase_options.dart)
Configuración generada con las credenciales de Firebase para Android.

---

## 🚀 Cómo Funciona

### Flujo de Registro de Token

1. **Inicio de la App**
   - Firebase se inicializa
   - Se solicitan permisos de notificaciones
   - Se obtiene el token FCM

2. **Registro del Token**
   - Se envía por HTTP POST a: `http://ec2-98-86-100-220.compute-1.amazonaws.com:3000/api/notifications/tokens`
   - Se envía también por WebSocket para registro en tiempo real

3. **Token Payload**
   ```json
   {
     "token": "eICCc5K6zvMYOlldkYSlkG:APA91b...",
     "deviceId": "google_pixel_9_pro",
     "platform": "android"
   }
   ```

### Flujo de Recepción de Notificaciones

#### Formato de Mensaje del Backend

El backend debe enviar mensajes **data-only** a FCM con esta estructura:

```json
{
  "to": "<FCM_DEVICE_TOKEN>",
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
}
```

**IMPORTANTE:** Usar `data` (no `notification`) para asegurar que el mensaje llegue en todos los estados de la app.

#### Estados de la App

1. **Foreground (App Abierta)**
   - `FirebaseMessaging.onMessage` recibe el mensaje
   - Se muestra notificación local personalizada
   - Logs en consola

2. **Background (App en Segundo Plano)**
   - El sistema Android maneja la notificación
   - Se puede procesar en `_firebaseMessagingBackgroundHandler`
   - Al tocar la notificación: `FirebaseMessaging.onMessageOpenedApp`

3. **Terminated (App Cerrada)**
   - El sistema muestra la notificación automáticamente
   - Al abrir la app desde la notificación: `FirebaseMessaging.getInitialMessage()`

---

## 🔧 Configuración del Backend

### Endpoint HTTP para Registro de Tokens

```
POST http://ec2-98-86-100-220.compute-1.amazonaws.com:3000/api/notifications/tokens
Content-Type: application/json

{
  "token": "string",
  "deviceId": "string",
  "platform": "android" | "ios"
}
```

### WebSocket

```
ws://ec2-98-86-100-220.compute-1.amazonaws.com:3000
```

Mensajes WebSocket:

**Registro de Token:**
```json
{
  "type": "registerToken",
  "token": "string",
  "deviceId": "string",
  "platform": "android",
  "timestamp": "2025-11-14T15:34:00Z"
}
```

**Subscripción a Dispositivo:**
```json
{
  "type": "subscribe",
  "deviceId": "ESP32_1",
  "timestamp": "2025-11-14T15:34:00Z"
}
```

---

## 🧪 Pruebas

### 1. Verificar Token FCM

Ejecuta la app y busca en los logs:
```
🔑 FCM Token: eICCc5K6zvMYOlldkYSlkG:APA91b...
```

O presiona el botón "Mostrar token FCM" en la pantalla principal.

### 2. Enviar Notificación de Prueba con curl

Si tienes la Server Key de Firebase (se obtiene en la consola de Firebase):

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" \
 -H "Content-Type: application/json" \
 -d '{
   "to": "DEVICE_FCM_TOKEN",
   "priority": "high",
   "data": {
      "event":"sensorAlert",
      "deviceId":"ESP321",
      "plantName":"Lavanda demo",
      "sensorType":"temperature",
      "value":"32.5",
      "unit":"C",
      "message":"Temperatura fuera de rango",
      "timestamp":"2025-11-14T15:34:00Z",
      "thresholdType":"max",
      "thresholdValue":"35"
   }
 }' https://fcm.googleapis.com/fcm/send
```

### 3. Desde Firebase Console

1. Ve a Firebase Console → Cloud Messaging
2. Selecciona "Send test message"
3. Pega el token del dispositivo
4. Envía la notificación

---

## 📱 Uso en la Aplicación

### Inicialización Automática

Los servicios se inicializan automáticamente al arrancar la app en [main.dart:30-57](lib/main.dart#L30-L57).

### Métodos Disponibles

#### FCMService

```dart
// Obtener instancia
final fcmService = FCMService();

// Obtener token actual
String? token = fcmService.currentToken;

// Subscribirse a un topic
await fcmService.subscribeToTopic('all_alerts');

// Desubscribirse de un topic
await fcmService.unsubscribeFromTopic('all_alerts');

// Eliminar token (útil para logout)
await fcmService.deleteToken();
```

#### WebSocketService

```dart
// Obtener instancia
final wsService = WebSocketService();

// Conectar
await wsService.connect();

// Registrar token
await wsService.registerToken('FCM_TOKEN');

// Subscribirse a dispositivo
wsService.subscribeToDevice('ESP32_1');

// Enviar mensaje personalizado
wsService.sendMessage({
  'type': 'custom',
  'data': 'value'
});

// Desconectar
await wsService.disconnect();
```

---

## ⚙️ Configuración Adicional

### Android 13+ (API 33+)

El permiso `POST_NOTIFICATIONS` se solicita automáticamente en tiempo de ejecución. Si el usuario lo deniega, no recibirá notificaciones.

### Personalizar Notificaciones

Edita [lib/src/services/fcm_service.dart](lib/src/services/fcm_service.dart) en el método `_showLocalNotification` para personalizar:
- Icono
- Color
- Sonido
- Vibración
- Acciones
- Estilo (BigText, BigPicture, etc.)

### Canal de Notificaciones

El canal predeterminado es `sensor_alerts_channel`. Puedes agregar más canales en [fcm_service.dart:92](lib/src/services/fcm_service.dart#L92).

---

## 🐛 Troubleshooting

### No recibo notificaciones

1. **Verificar permisos:** Asegúrate de que los permisos de notificaciones estén otorgados en Configuración → Apps → AgroCordIot → Notificaciones

2. **Verificar token:** Confirma que el token se está registrando correctamente:
   ```
   ✅ Token registered successfully
   ```

3. **Verificar formato del mensaje:** El backend debe enviar `data` (no solo `notification`)

4. **Logs:** Revisa los logs de la app para ver si los mensajes están llegando:
   ```
   📩 Foreground message received: ...
   ```

### App en background/terminated no muestra notificación

- Asegúrate de que el mensaje tenga `priority: high`
- Verifica que estás usando mensajes `data-only`
- En algunos dispositivos, debes desactivar optimización de batería para la app

### WebSocket se desconecta constantemente

- Verifica conectividad de red
- El servicio tiene reconexión automática con hasta 5 intentos
- Revisa logs:
  ```
  🔄 Scheduling reconnect attempt X in 5s
  ```

---

## 📚 Recursos Adicionales

- [Documentación Firebase Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [WebSocket Channel](https://pub.dev/packages/web_socket_channel)

---

## ✨ Próximos Pasos Opcionales

1. **iOS Support:** Configurar APNs y agregar `GoogleService-Info.plist`
2. **Topics:** Implementar subscripción a topics para notificaciones grupales
3. **Analytics:** Rastrear aperturas de notificaciones con Firebase Analytics
4. **Rich Notifications:** Agregar imágenes, botones de acción, etc.
5. **Notificaciones Programadas:** Alertas locales basadas en tiempo
6. **Deep Links:** Navegar a pantallas específicas al tocar notificación

---

## 🎉 Implementación Completada

Tu aplicación AgroCordIot ahora está completamente configurada para:

✅ Recibir notificaciones push en todos los estados
✅ Registrar tokens automáticamente con el backend
✅ Mantener conexión WebSocket para comunicación en tiempo real
✅ Manejar alertas de sensores IoT
✅ Mostrar notificaciones personalizadas al usuario

**Todo está listo para probar en un dispositivo real!** 🚀

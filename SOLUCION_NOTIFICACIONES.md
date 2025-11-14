# 🔧 Solución: Notificaciones no Aparecen

## ✅ Problema Identificado

El **WebSocket estaba recibiendo mensajes correctamente**, pero estos **no se convertían en notificaciones**.

## 🛠️ Cambios Aplicados

### 1. Agregado Método Público en FCMService

**Archivo:** `lib/src/services/fcm_service.dart`

Se agregó el método `showNotificationFromData()` que permite mostrar notificaciones desde cualquier fuente (WebSocket, HTTP, etc.):

```dart
/// Mostrar notificación desde datos (para WebSocket u otras fuentes)
Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data['event']?.toString() ?? 'Alerta de Sensor';
  final body = data['message']?.toString() ?? _buildMessageFromData(data);

  // ... muestra la notificación local
}
```

### 2. Configurado Handler de WebSocket en main.dart

**Archivo:** `lib/main.dart`

Se agregaron callbacks al WebSocket para procesar mensajes entrantes:

```dart
// Configurar callback para mostrar notificaciones cuando lleguen mensajes
wsService.onMessageReceived = (data) async {
  print('📨 WebSocket message received: $data');

  // Mostrar notificación local cuando llegue un mensaje
  if (data['event'] == 'sensorAlert') {
    await fcmService.showNotificationFromData(data);
  }
};
```

### 3. Creada Pantalla de Pruebas

**Archivo:** `lib/src/presentation/screens/test_notifications_screen.dart`

Nueva pantalla accesible desde el botón de notificaciones (🔔) en el Dashboard que permite:

- ✅ Probar notificaciones locales directamente
- ✅ Ver y copiar el token FCM
- ✅ Reinicializar FCM si es necesario
- ✅ Probar conexión WebSocket
- ✅ Ver estado de servicios

---

## 🚀 Cómo Probar Ahora

### Opción 1: Esperar Alerta Real del Backend

1. La app está corriendo
2. El WebSocket está conectado
3. Cuando el backend detecte una alerta de sensor, **automáticamente verás la notificación**

**Ejemplo del mensaje que recibiste:**
```json
{
  "event": "sensorAlert",
  "deviceId": "ESP32_1",
  "sensorType": "temperature",
  "value": 36.18,
  "unit": "°C",
  "message": "¡Alerta en ESP32_1! La Temperatura ha superado el máximo: 36.18 °C",
  "plantName": "Frijol"
}
```

### Opción 2: Probar Notificación Local

1. Abre la app
2. En el Dashboard, presiona el botón de notificaciones (🔔) en la parte superior
3. Se abrirá la pantalla de **Prueba de Notificaciones**
4. Presiona **"Probar Notificación Local"**
5. Deberías ver una notificación inmediatamente ✅

### Opción 3: Simular Mensaje desde el Backend

Si tienes acceso al servidor WebSocket, puedes enviar un mensaje de prueba:

```json
{
  "event": "sensorAlert",
  "deviceId": "ESP32_TEST",
  "plantName": "Planta de Prueba",
  "sensorType": "temperature",
  "value": "99.9",
  "unit": "°C",
  "message": "PRUEBA: Notificación de prueba desde WebSocket",
  "timestamp": "2025-11-14T21:00:00Z"
}
```

---

## 🔍 Verificar que Funciona

### En los Logs deberías ver:

```
📨 WebSocket message received: {event: sensorAlert, ...}
✅ Notification shown: sensorAlert - ¡Alerta en ESP32_1! ...
```

### En el dispositivo:

- 🔔 Notificación aparece en la barra de estado
- 📱 Sonido/vibración
- 📝 Título: "sensorAlert" (o lo que esté en `event`)
- 📝 Mensaje: El contenido del campo `message`

---

## 🎯 Qué Cambió vs. Antes

| Antes | Ahora |
|-------|-------|
| ❌ WebSocket recibía mensajes pero no hacía nada | ✅ WebSocket muestra notificación al recibir mensaje |
| ❌ Solo funcionaba con FCM (que no estaba llegando) | ✅ Funciona con WebSocket + FCM |
| ❌ No había forma de probar | ✅ Pantalla de pruebas integrada |

---

## 📱 Acceso Rápido a Pruebas

1. **Dashboard** → Botón 🔔 (arriba a la derecha)
2. Aparece **"Prueba de Notificaciones"**
3. Botones disponibles:
   - 🔔 **Probar Notificación Local** - Prueba inmediata
   - 🔑 **Ver/Copiar Token FCM** - Para pruebas con FCM
   - 🔄 **Reinicializar FCM** - Si hay problemas
   - 📡 **Probar WebSocket** - Verificar conexión

---

## ⚠️ Notas Importantes

### Permisos de Notificaciones

En Android 13+, asegúrate de que los permisos estén otorgados:

1. **Configuración** → **Apps** → **AgroCordIot** → **Notificaciones**
2. Activar **"Permitir notificaciones"**

### Si aún no ves notificaciones:

1. **Prueba la notificación local** desde la pantalla de pruebas
2. Si la local funciona pero la de WebSocket no:
   - Verifica que `event` sea `"sensorAlert"`
   - Revisa los logs para ver si el callback se ejecuta
3. Si ninguna funciona:
   - Verifica permisos de notificaciones
   - Reinstala la app
   - Revisa que Google Play Services esté actualizado

---

## 🎉 Estado Actual

✅ **WebSocket:** Conectado y recibiendo mensajes
✅ **Handler:** Configurado para procesar mensajes
✅ **Notificaciones:** Listas para mostrarse
✅ **Pruebas:** Pantalla de debug disponible

**La próxima alerta que envíe el backend debería aparecer como notificación!** 🚀

---

## 📞 Debug Rápido

Si tienes dudas, ejecuta estos comandos y revisa el output:

```bash
# Ver logs en tiempo real
flutter logs

# Ver solo mensajes de WebSocket y notificaciones
flutter logs | grep -E "(WebSocket|Notification|🔔|📨|✅)"

# Verificar permisos
adb shell dumpsys package com.example.iot | grep permission
```

---

¡Listo para recibir notificaciones! 📬✨

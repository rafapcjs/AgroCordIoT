# Integración del Backend con FCM

## 📡 Configuración del Servidor Firebase

### 1. Obtener Server Key

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: `monitoring-system-f50e6`
3. Ve a **Project Settings** → **Cloud Messaging**
4. Copia la **Server Key** (legacy)

O usa **Firebase Admin SDK** (recomendado para producción):
- Ve a **Project Settings** → **Service Accounts**
- Click en "Generate new private key"
- Descarga el archivo JSON

---

## 🔧 Implementación en Node.js/Express

### Opción 1: Usando HTTP Legacy API (más simple)

```javascript
const axios = require('axios');

// Configuración
const FCM_SERVER_KEY = 'AAAA...'; // Tu Server Key de Firebase
const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

// Almacenar tokens (en producción usar base de datos)
const deviceTokens = new Map(); // deviceId -> fcmToken

// Endpoint para registrar tokens
app.post('/api/notifications/tokens', (req, res) => {
  const { token, deviceId, platform } = req.body;

  if (!token || !deviceId) {
    return res.status(400).json({ error: 'Token and deviceId are required' });
  }

  // Guardar el token asociado al dispositivo
  deviceTokens.set(deviceId, {
    token,
    platform,
    registeredAt: new Date(),
  });

  console.log(`✅ Token registered for device ${deviceId} (${platform})`);
  res.status(201).json({
    success: true,
    message: 'Token registered successfully',
    deviceId,
  });
});

// Función para enviar notificación a un dispositivo específico
async function sendNotificationToDevice(deviceId, alertData) {
  const device = deviceTokens.get(deviceId);

  if (!device) {
    console.error(`❌ No token found for device: ${deviceId}`);
    return { success: false, error: 'Device not registered' };
  }

  const message = {
    to: device.token,
    priority: 'high',
    data: {
      event: alertData.event || 'sensorAlert',
      deviceId: alertData.deviceId,
      plantName: alertData.plantName,
      sensorType: alertData.sensorType,
      value: String(alertData.value),
      unit: alertData.unit,
      message: alertData.message,
      timestamp: alertData.timestamp || new Date().toISOString(),
      thresholdType: alertData.thresholdType,
      thresholdValue: String(alertData.thresholdValue),
    },
  };

  try {
    const response = await axios.post(FCM_URL, message, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
    });

    console.log('✅ Notification sent successfully:', response.data);
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error sending notification:', error.response?.data || error.message);
    return { success: false, error: error.response?.data || error.message };
  }
}

// Endpoint para enviar notificación (ejemplo)
app.post('/api/notifications/send', async (req, res) => {
  const { deviceId, alertData } = req.body;

  const result = await sendNotificationToDevice(deviceId, alertData);

  if (result.success) {
    res.json({ success: true, message: 'Notification sent' });
  } else {
    res.status(500).json({ success: false, error: result.error });
  }
});

// Ejemplo de uso cuando se detecta una alerta de sensor
function onSensorAlert(sensorData) {
  const alertData = {
    event: 'sensorAlert',
    deviceId: sensorData.deviceId,
    plantName: sensorData.plantName,
    sensorType: sensorData.sensorType,
    value: sensorData.value,
    unit: sensorData.unit,
    message: `${sensorData.sensorType} fuera de rango`,
    thresholdType: sensorData.thresholdType,
    thresholdValue: sensorData.thresholdValue,
  };

  // Enviar a todos los dispositivos registrados (o filtrar por usuario)
  deviceTokens.forEach((device, deviceId) => {
    sendNotificationToDevice(deviceId, alertData);
  });
}
```

### Opción 2: Usando Firebase Admin SDK (recomendado)

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

// Inicializar Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Almacenar tokens
const deviceTokens = new Map();

// Endpoint para registrar tokens
app.post('/api/notifications/tokens', (req, res) => {
  const { token, deviceId, platform } = req.body;

  if (!token || !deviceId) {
    return res.status(400).json({ error: 'Token and deviceId are required' });
  }

  deviceTokens.set(deviceId, {
    token,
    platform,
    registeredAt: new Date(),
  });

  console.log(`✅ Token registered for device ${deviceId} (${platform})`);
  res.status(201).json({
    success: true,
    message: 'Token registered successfully',
    deviceId,
  });
});

// Función para enviar notificación usando Admin SDK
async function sendNotificationToDevice(deviceId, alertData) {
  const device = deviceTokens.get(deviceId);

  if (!device) {
    console.error(`❌ No token found for device: ${deviceId}`);
    return { success: false, error: 'Device not registered' };
  }

  const message = {
    token: device.token,
    android: {
      priority: 'high',
    },
    data: {
      event: alertData.event || 'sensorAlert',
      deviceId: alertData.deviceId,
      plantName: alertData.plantName,
      sensorType: alertData.sensorType,
      value: String(alertData.value),
      unit: alertData.unit,
      message: alertData.message,
      timestamp: alertData.timestamp || new Date().toISOString(),
      thresholdType: alertData.thresholdType || '',
      thresholdValue: String(alertData.thresholdValue || ''),
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent successfully:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    return { success: false, error: error.message };
  }
}

// Enviar a múltiples dispositivos (multicast)
async function sendNotificationToMultipleDevices(deviceIds, alertData) {
  const tokens = deviceIds
    .map(id => deviceTokens.get(id)?.token)
    .filter(token => token);

  if (tokens.length === 0) {
    return { success: false, error: 'No valid tokens found' };
  }

  const message = {
    tokens,
    android: {
      priority: 'high',
    },
    data: {
      event: alertData.event || 'sensorAlert',
      deviceId: alertData.deviceId,
      plantName: alertData.plantName,
      sensorType: alertData.sensorType,
      value: String(alertData.value),
      unit: alertData.unit,
      message: alertData.message,
      timestamp: alertData.timestamp || new Date().toISOString(),
      thresholdType: alertData.thresholdType || '',
      thresholdValue: String(alertData.thresholdValue || ''),
    },
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(`✅ ${response.successCount} notifications sent successfully`);

    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`❌ Failed to send to ${tokens[idx]}:`, resp.error);
          // Eliminar tokens inválidos
          if (resp.error.code === 'messaging/invalid-registration-token' ||
              resp.error.code === 'messaging/registration-token-not-registered') {
            // Remover token de la base de datos
            console.log(`🗑️ Removing invalid token: ${tokens[idx]}`);
          }
        }
      });
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('❌ Error sending notifications:', error);
    return { success: false, error: error.message };
  }
}

// Enviar a un topic
async function sendNotificationToTopic(topic, alertData) {
  const message = {
    topic,
    android: {
      priority: 'high',
    },
    data: {
      event: alertData.event || 'sensorAlert',
      deviceId: alertData.deviceId,
      plantName: alertData.plantName,
      sensorType: alertData.sensorType,
      value: String(alertData.value),
      unit: alertData.unit,
      message: alertData.message,
      timestamp: alertData.timestamp || new Date().toISOString(),
      thresholdType: alertData.thresholdType || '',
      thresholdValue: String(alertData.thresholdValue || ''),
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Topic notification sent:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending topic notification:', error);
    return { success: false, error: error.message };
  }
}
```

---

## 🌐 Integración con WebSocket

```javascript
const WebSocket = require('ws');

// Crear servidor WebSocket
const wss = new WebSocket.Server({ port: 3000 });

// Almacenar conexiones
const wsConnections = new Map(); // deviceId -> WebSocket connection

wss.on('connection', (ws) => {
  console.log('🔌 New WebSocket connection');

  ws.on('message', async (message) => {
    try {
      const data = JSON.parse(message);

      switch (data.type) {
        case 'registerToken':
          // Registrar token FCM
          deviceTokens.set(data.deviceId, {
            token: data.token,
            platform: data.platform,
            registeredAt: new Date(),
          });
          wsConnections.set(data.deviceId, ws);

          console.log(`✅ Token registered via WebSocket: ${data.deviceId}`);

          ws.send(JSON.stringify({
            type: 'registerToken',
            status: 'success',
            message: 'Token registered successfully',
          }));
          break;

        case 'subscribe':
          // Subscribir a un dispositivo IoT específico
          wsConnections.set(data.deviceId, ws);
          console.log(`✅ Device subscribed: ${data.deviceId}`);
          break;

        case 'ping':
          ws.send(JSON.stringify({ type: 'pong', timestamp: new Date().toISOString() }));
          break;

        default:
          console.log('⚠️ Unknown message type:', data.type);
      }
    } catch (error) {
      console.error('❌ Error processing WebSocket message:', error);
    }
  });

  ws.on('close', () => {
    console.log('🔌 WebSocket connection closed');
    // Remover de conexiones
    wsConnections.forEach((conn, deviceId) => {
      if (conn === ws) {
        wsConnections.delete(deviceId);
      }
    });
  });

  ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error);
  });
});

// Función para enviar alerta por WebSocket (opcional, además de FCM)
function sendWebSocketAlert(deviceId, alertData) {
  const ws = wsConnections.get(deviceId);

  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({
      type: 'sensorAlert',
      data: alertData,
    }));
    console.log(`✅ Alert sent via WebSocket to ${deviceId}`);
  }
}
```

---

## 🎯 Ejemplo Completo de Flujo

```javascript
// Simulación de alerta de sensor IoT
const sensorAlert = {
  deviceId: 'ESP321',
  plantName: 'Lavanda demo',
  sensorType: 'temperature',
  value: 32.5,
  unit: 'C',
  message: 'Temperatura fuera de rango',
  thresholdType: 'max',
  thresholdValue: 35,
  timestamp: new Date().toISOString(),
};

// 1. Enviar notificación push FCM a todos los dispositivos móviles registrados
deviceTokens.forEach((device, deviceId) => {
  sendNotificationToDevice(deviceId, sensorAlert);
});

// 2. Enviar también por WebSocket a dispositivos conectados (opcional)
wsConnections.forEach((ws, deviceId) => {
  sendWebSocketAlert(deviceId, sensorAlert);
});

// 3. Guardar en base de datos para historial (opcional)
// await saveAlertToDatabase(sensorAlert);
```

---

## 📊 Monitoreo y Logs

### Logs Importantes

```javascript
// Éxito
✅ Token registered for device pixel_9_pro (android)
✅ Notification sent successfully: { success: 1, failure: 0 }

// Errores comunes
❌ No token found for device: ESP321
❌ Error sending notification: messaging/invalid-registration-token
❌ Error sending notification: messaging/registration-token-not-registered
```

### Manejo de Tokens Inválidos

```javascript
async function cleanInvalidTokens() {
  const invalidTokens = [];

  for (const [deviceId, device] of deviceTokens.entries()) {
    try {
      // Intentar enviar mensaje de prueba
      await admin.messaging().send({
        token: device.token,
        data: { type: 'ping' },
        dryRun: true, // No envía realmente, solo valida
      });
    } catch (error) {
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        invalidTokens.push(deviceId);
      }
    }
  }

  // Eliminar tokens inválidos
  invalidTokens.forEach(deviceId => {
    deviceTokens.delete(deviceId);
    console.log(`🗑️ Removed invalid token for device: ${deviceId}`);
  });

  console.log(`✅ Cleaned ${invalidTokens.length} invalid tokens`);
}

// Ejecutar limpieza periódicamente (cada 24 horas)
setInterval(cleanInvalidTokens, 24 * 60 * 60 * 1000);
```

---

## 🔐 Seguridad

### Validación de Tokens

```javascript
app.post('/api/notifications/tokens', async (req, res) => {
  const { token, deviceId, platform } = req.body;

  // Validar formato del token
  if (!token || typeof token !== 'string' || token.length < 100) {
    return res.status(400).json({ error: 'Invalid token format' });
  }

  // Validar que el token es válido con Firebase (opcional pero recomendado)
  try {
    await admin.messaging().send({
      token,
      data: { type: 'validation' },
      dryRun: true,
    });

    // Token válido, guardar
    deviceTokens.set(deviceId, {
      token,
      platform,
      registeredAt: new Date(),
    });

    res.status(201).json({
      success: true,
      message: 'Token registered and validated',
    });
  } catch (error) {
    console.error('❌ Invalid token:', error.message);
    res.status(400).json({
      success: false,
      error: 'Invalid FCM token',
    });
  }
});
```

### Autenticación de Endpoints

```javascript
const authenticateUser = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Validar JWT o session
  const token = authHeader.substring(7);
  // ... validar token ...

  next();
};

app.post('/api/notifications/tokens', authenticateUser, async (req, res) => {
  // ... registrar token ...
});
```

---

## 📈 Mejores Prácticas

1. **Usar Base de Datos:** Almacena tokens en DB (MongoDB, PostgreSQL, etc.) en lugar de Map en memoria
2. **Limpiar Tokens Inválidos:** Elimina tokens que FCM rechaza
3. **Rate Limiting:** Limita requests para evitar abuse
4. **Logging:** Registra todas las notificaciones enviadas
5. **Retry Logic:** Reintenta envíos fallidos
6. **Topics:** Usa topics para notificaciones grupales
7. **Prioridad:** Usa `high` priority solo cuando sea necesario
8. **TTL:** Configura time-to-live apropiado
9. **Testing:** Prueba en diferentes estados de la app
10. **Monitoreo:** Usa Firebase Console para ver estadísticas

---

## 🚀 Siguiente Paso

¡El backend está listo para enviar notificaciones! Solo necesitas:

1. Obtener tu Server Key o Service Account de Firebase
2. Implementar uno de los códigos anteriores
3. Probar enviando notificaciones de prueba

**¡La app Flutter ya está lista para recibirlas!** 📱✨

# 📱 Formato de Notificaciones Actualizado

## ✨ Cambios Aplicados

Las notificaciones ahora muestran de forma prominente:

### 🎯 Título
- **Con nombre de planta:** `🌱 [Nombre de la Planta]`
- **Sin planta (solo deviceId):** `📟 [DeviceId]`
- **Sin información:** `⚠️ Alerta de Sensor`

### 📝 Cuerpo
- **Primera línea:** Icono + Tipo de sensor + Valor
  - Ejemplo: `🌡️ Temperatura: 42.5°C`
- **Segunda línea:** Mensaje detallado del backend

## 🎨 Formato Visual

### Ejemplo 1: Temperatura Alta
```
Título: 🌱 Frijol
Cuerpo:
🌡️ Temperatura: 46.91°C
¡Alerta en ESP32_1! La Temperatura ha superado el máximo: 46.91 °C (Máx: 35 °C).
```

### Ejemplo 2: Humedad del Suelo Baja
```
Título: 🌱 Lavanda
Cuerpo:
🌾 Humedad del Suelo: 11.12%
¡Alerta en ESP32_2! La Humedad del Suelo está por debajo del mínimo: 11.12 % (Mín: 20 %).
```

### Ejemplo 3: Radiación Solar Alta
```
Título: 🌱 Tomate
Cuerpo:
☀️ Radiación Solar: 1118.12W/m2
¡Alerta en ESP32_3! La Radiación Solar ha superado el máximo: 1118.12 W/m2 (Máx: 1000 W/m2).
```

## 🎭 Iconos por Tipo de Sensor

| Tipo de Sensor | Icono | Nombre Formateado |
|----------------|-------|-------------------|
| `temperature` | 🌡️ | Temperatura |
| `humidity` | 💧 | Humedad |
| `soil_humidity` | 🌾 | Humedad del Suelo |
| `solar_radiation` | ☀️ | Radiación Solar |
| `pressure` | 🌀 | Presión |
| `light` | 💡 | Luz |
| `ph` | ⚗️ | pH |

## 🔄 Para Reiniciar y Ver los Cambios

1. **Detén la app actual** (presiona `q` en la terminal de Flutter)
2. **Vuelve a ejecutar:**
   ```bash
   flutter run
   ```

3. **O haz Hot Restart:** Presiona `R` en la terminal de Flutter

## ✅ Qué Cambió en el Código

### Archivo: `lib/src/services/fcm_service.dart`

Se modificó el método `showNotificationFromData()` para:

1. **Construir título con nombre de planta:**
   ```dart
   if (plantName.isNotEmpty) {
     title = '🌱 $plantName';
   }
   ```

2. **Formatear tipo de sensor con icono:**
   ```dart
   final sensorTypeFormatted = _formatSensorType(sensorType);
   body = '$sensorTypeFormatted: $value$unit\n$body';
   ```

3. **Agregar método helper:**
   ```dart
   String _formatSensorType(String sensorType) {
     // Mapeo de tipos a nombres + iconos
   }
   ```

## 📊 Prioridades de Datos

### Para el Título:
1. `plantName` → 🌱 [Nombre]
2. `deviceId` → 📟 [ID]
3. Fallback → ⚠️ Alerta de Sensor

### Para el Cuerpo:
1. Tipo sensor formateado + valor + unidad
2. Campo `message` del backend
3. Mensaje construido de datos

## 🎯 Próxima Notificación

La próxima alerta que recibas del backend mostrará:
- ✅ Nombre de la planta en el título
- ✅ Tipo de sensor con icono
- ✅ Valor actual
- ✅ Mensaje detallado

**Ejemplo real que recibirás:**

```
┌─────────────────────────────┐
│ 🌱 Frijol                   │
├─────────────────────────────┤
│ 🌡️ Temperatura: 48.98°C    │
│                             │
│ ¡Alerta en ESP32_1! La     │
│ Temperatura ha superado el  │
│ máximo: 48.98 °C (Máx: 35  │
│ °C).                        │
└─────────────────────────────┘
```

¡Mucho más claro y visible! 🎉

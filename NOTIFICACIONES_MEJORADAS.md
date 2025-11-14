# 🎨 Notificaciones Mejoradas - Guía Completa

## ✨ Mejoras Implementadas

### 1. 🎵 Sonido Personalizado
- Sonido único para alertas de sensores
- Vibración con patrón personalizado
- Se diferencia del sonido de notificaciones normales

### 2. 🎨 Diseño Visual Mejorado
- **BigTextStyle**: Texto expandible con detalles completos
- **Colores inteligentes** según tipo de alerta:
  - 🔴 **Rojo** (0xFFFF5252): Cuando se supera el máximo
  - 🟠 **Naranja** (0xFFFF9800): Cuando está por debajo del mínimo
  - 🟢 **Verde** (0xFF4CAF50): Notificaciones informativas
- **LED** parpadeante con el color de la alerta
- **Icono grande** de la app en la notificación

### 3. 📱 Comportamiento Optimizado
- **Prioridad máxima** para alertas críticas
- **Auto-cancelable**: Desaparece al tocar
- **Ticker** animado en la barra de estado
- **Timestamp** visible
- **Categoría Alarm** para alertas importantes

### 4. 📝 Contenido Mejorado
- **Título**: 🌱 Nombre de la planta
- **Resumen**: Tipo de sensor + Valor
- **Expandido**: Detalles completos del mensaje

---

## 🔧 Configuración del Sonido Personalizado

### Paso 1: Descargar un Sonido

Puedes usar cualquier sonido en formato `.mp3` o `.ogg`. Te recomiendo:

1. **Opción A - Sonido Online:**
   - Ve a https://notificationsounds.com/
   - Descarga un sonido de alerta (ej: "Definite", "Alert Tone", "Juntos")
   - Renómbralo a `notification_sound.mp3`

2. **Opción B - Usar Sonido del Sistema:**
   - Busca en `C:\Windows\Media\` un sonido .wav
   - Conviértelo a .mp3 u .ogg con una herramienta online

3. **Opción C - Sonido Simple (Temporalmente):**
   - Puedes usar cualquier .mp3 corto (1-3 segundos)

### Paso 2: Colocar el Archivo

1. **Crear carpeta** (si no existe):
   ```
   android/app/src/main/res/raw/
   ```

2. **Copiar el archivo:**
   - Nombre: `notification_sound.mp3` o `notification_sound.ogg`
   - Ruta: `android/app/src/main/res/raw/notification_sound.mp3`

**IMPORTANTE:** El nombre del archivo debe ser en minúsculas y sin espacios.

### Paso 3: Alternativa - Usar Sonido por Defecto

Si no quieres un sonido personalizado, modifica esta línea en `fcm_service.dart`:

```dart
// Cambiar de:
sound: const RawResourceAndroidNotificationSound('notification_sound'),

// A:
// sound: null,  // Usa sonido por defecto del sistema
```

---

## 📊 Ejemplo de Cómo se Ve

### Vista Colapsada (Pequeña)
```
┌─────────────────────────────────┐
│ 🌱 Frijol                       │
│ 🌡️ Temperatura: 46.91°C        │
│ hace 1 minuto                   │
└─────────────────────────────────┘
```

### Vista Expandida (Al deslizar hacia abajo)
```
┌─────────────────────────────────┐
│ 🌱 Frijol                       │
├─────────────────────────────────┤
│ 🌡️ Temperatura: 46.91°C        │
│                                 │
│ ¡Alerta en ESP32_1! La         │
│ Temperatura ha superado el      │
│ máximo: 46.91 °C (Máx: 35 °C). │
│                                 │
│ hace 1 minuto                   │
└─────────────────────────────────┘
```

### Características Visuales

- **LED Rojo** parpadeando (para umbral máximo)
- **LED Naranja** parpadeando (para umbral mínimo)
- **Vibración**: Patrón corto-largo-corto-largo
- **Sonido**: Personalizado o por defecto
- **Icono grande**: Logo de la app
- **Ticker**: "Frijol - 🌡️ Temperatura alerta"

---

## 🎯 Tipos de Color por Alerta

### 🔴 Rojo - Umbral Máximo Excedido
Cuando `thresholdType` == `"max"`
- Temperatura muy alta
- Humedad muy alta
- Radiación solar excesiva
- **Prioridad**: Máxima

### 🟠 Naranja - Umbral Mínimo No Alcanzado
Cuando `thresholdType` == `"min"`
- Temperatura muy baja
- Humedad del suelo baja
- **Prioridad**: Alta

### 🟢 Verde - Notificaciones Informativas
Para otros tipos de notificaciones
- **Prioridad**: Normal

---

## 🔔 Patrón de Vibración

El patrón configurado es:
```
[0, 500, 250, 500]
```

Significa:
- **0ms**: Espera inicial
- **500ms**: Vibra fuerte
- **250ms**: Pausa
- **500ms**: Vibra fuerte

Puedes modificarlo en `fcm_service.dart` línea 454:
```dart
vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
```

---

## 💡 Personalización Adicional

### Cambiar Duración del LED

En `fcm_service.dart` líneas 460-461:
```dart
ledOnMs: 1000,   // LED encendido 1 segundo
ledOffMs: 500,   // LED apagado 0.5 segundos
```

### Cambiar Colores

En `fcm_service.dart` líneas 428-436:
```dart
if (thresholdType == 'max') {
  notificationColor = const Color(0xFFFF5252); // Cambia este color
}
```

Algunos colores sugeridos:
- Rojo intenso: `0xFFE53935`
- Naranja vibrante: `0xFFFB8C00`
- Amarillo: `0xFFFDD835`
- Azul: `0xFF1E88E5`

### Deshabilitar LED

```dart
enableLights: false,  // Cambiar a false
```

### Deshabilitar Vibración

```dart
enableVibration: false,  // Cambiar a false
```

---

## 🚀 Aplicar los Cambios

### Opción 1: Hot Restart (Rápido)
1. En la terminal de Flutter, presiona `R`
2. Espera que la app se reinicie

### Opción 2: Reinstalar (Completo)
```bash
# Detener la app
# Presiona 'q' en la terminal

# Limpiar y reinstalar
flutter clean
flutter pub get
flutter run
```

---

## 📱 Pruebas

### 1. Probar Notificación desde la App

1. Abre la app
2. Presiona el botón 🔔 (arriba a la derecha)
3. Presiona "Probar Notificación Local"
4. ✅ Deberías ver/escuchar:
   - Sonido personalizado (o por defecto)
   - Vibración con patrón
   - LED parpadeando
   - Notificación con diseño mejorado

### 2. Esperar Alerta Real

La próxima vez que el backend envíe una alerta:
- ✅ Verás el color según el tipo (rojo/naranja)
- ✅ Escucharás el sonido
- ✅ Sentirás la vibración
- ✅ El LED parpadeará

---

## 🐛 Solución de Problemas

### No escucho el sonido personalizado

1. **Verifica que el archivo existe:**
   ```
   android/app/src/main/res/raw/notification_sound.mp3
   ```

2. **Verifica el nombre:**
   - Debe ser **exactamente** `notification_sound.mp3`
   - Todo en minúsculas
   - Sin espacios

3. **Reinstala la app:**
   ```bash
   flutter clean
   flutter run
   ```

4. **Usa sonido por defecto temporalmente:**
   Comenta la línea del sonido:
   ```dart
   // sound: const RawResourceAndroidNotificationSound('notification_sound'),
   ```

### No veo el LED

- Algunos dispositivos modernos no tienen LED de notificación
- Verifica en Configuración → Notificaciones que el LED esté habilitado

### La vibración no funciona

- Verifica que el modo "No Molestar" esté desactivado
- Asegúrate que la vibración esté habilitada para la app

### Los colores no se ven

- Los colores del LED y la notificación dependen del tema del sistema
- En modo oscuro, los colores pueden verse diferentes

---

## 📚 Recursos del Código

### Archivo Principal
- [lib/src/services/fcm_service.dart](lib/src/services/fcm_service.dart#L383-L527)

### Líneas Clave
- **Sonido**: Línea 451
- **Vibración**: Línea 454
- **LED**: Líneas 457-461
- **Colores**: Líneas 424-437
- **Estilo visual**: Líneas 464-471

---

## ✨ Resumen de Características

✅ **Sonido personalizado** (o por defecto si prefieres)
✅ **Vibración con patrón único**
✅ **LED de colores** según gravedad
✅ **Diseño BigText** expandible
✅ **Colores dinámicos** (rojo/naranja/verde)
✅ **Prioridad inteligente**
✅ **Icono grande** de la app
✅ **Ticker animado**
✅ **Timestamp visible**

**¡Tus notificaciones ahora son mucho más visuales y llamativas!** 🎉

---

## 🎁 Sonidos Recomendados

Si quieres usar un sonido profesional:

1. **Zedge** - https://www.zedge.net/find/ringtones/alert
2. **Notification Sounds** - https://notificationsounds.com/
3. **Freesound** - https://freesound.org/ (busca "alert notification")

Descarga un sonido corto (1-3 segundos), renómbralo a `notification_sound.mp3` y colócalo en `android/app/src/main/res/raw/`.

¡Listo! 🚀

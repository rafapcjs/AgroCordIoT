# Gráficas de Sensores IoT

Este documento explica cómo utilizar las gráficas de líneas creadas para visualizar datos de sensores.

## Componentes Creados

### 1. `SensorLineChart`
**Ubicación:** `lib/src/presentation/widgets/charts/sensor_line_chart.dart`

Gráfica combinada que muestra las tres series de datos en un solo gráfico:
- **Temperatura** (línea roja): Valores en grados Celsius (°C)
- **Humedad** (línea azul): Valores en porcentaje (%)
- **Radiación Solar** (línea naranja): Valores escalados para visualización

**Uso:**
```dart
import 'package:iot/src/presentation/widgets/charts/sensor_line_chart.dart';

// En tu widget
const SensorLineChart()
```

### 2. `SensorChartsView`
**Ubicación:** `lib/src/presentation/widgets/charts/sensor_charts_view.dart`

Vista con tres gráficas separadas, cada una con su propia escala:
- Gráfica de Temperatura (20°C - 35°C)
- Gráfica de Humedad (80% - 95%)
- Gráfica de Radiación Solar (0 - 11000 W/m²)

**Uso:**
```dart
import 'package:iot/src/presentation/widgets/charts/sensor_charts_view.dart';

// En tu widget
const SensorChartsView()
```

### 3. `SensorChartsScreen`
**Ubicación:** `lib/src/presentation/screens/sensor_charts_screen.dart`

Pantalla completa de ejemplo que muestra ambos tipos de gráficas.

**Uso:**
```dart
// Navegar a la pantalla
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SensorChartsScreen(),
  ),
);
```

## Datos Incluidos

### Temperatura
```
Hora      | Temperatura (°C)
----------|------------------
17:00     | 33.1
18:00     | 33.0
19:00     | 30.4
20:00     | 29.3
21:00     | 26.1
22:00     | 24.4
23:00     | 23.1
```

### Humedad
```
Hora      | Humedad (%)
----------|-------------
17:00     | 85
18:00     | 84
19:00     | 88
20:00     | 90
21:00     | 93
22:00     | 82
23:00     | 87
```

### Radiación Solar
```
Hora      | Radiación (W/m²)
----------|------------------
17:00     | 10282.98
18:00     | 9500.00
19:00     | 7800.00
20:00     | 5200.00
21:00     | 2800.00
22:00     | 1200.00
23:00     | 450.00
```

## Personalización

### Cambiar Datos
Para usar tus propios datos, modifica los valores en los arrays `FlSpot`:

```dart
spots: [
  const FlSpot(0, tuValor1),
  const FlSpot(1, tuValor2),
  // ... más puntos
],
```

### Cambiar Colores
Modifica el parámetro `color` en cada gráfica:

```dart
color: Colors.green, // Cambia el color de la línea
```

### Ajustar Rango del Eje Y
En `SensorChartsView`, modifica los parámetros `minY` y `maxY`:

```dart
minY: 0,    // Valor mínimo del eje Y
maxY: 100,  // Valor máximo del eje Y
interval: 20, // Intervalo entre líneas de la cuadrícula
```

## Integración en el Proyecto

Para agregar las gráficas a una pantalla existente:

```dart
import 'package:flutter/material.dart';
import 'package:iot/src/presentation/widgets/charts/sensor_charts_view.dart';

class MiPantalla extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mis Datos')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Tus widgets existentes...
            
            // Agregar las gráficas
            const SensorChartsView(),
            
            // Más widgets...
          ],
        ),
      ),
    );
  }
}
```

## Características de las Gráficas

✅ **Líneas curvas suavizadas** para mejor visualización
✅ **Puntos de datos visibles** en cada medición
✅ **Área rellena** bajo las líneas con degradado
✅ **Leyenda** para identificar cada serie
✅ **Etiquetas de hora** en formato 24h
✅ **Valores formateados** (k para miles en radiación solar)
✅ **Cuadrícula** para facilitar la lectura
✅ **Diseño responsive** que se adapta al tamaño de pantalla
✅ **Colores diferenciados** para cada tipo de sensor
✅ **Iconos descriptivos** para cada medición

## Dependencias

El proyecto ya incluye `fl_chart: ^0.69.0` en `pubspec.yaml`. No es necesario instalar nada adicional.

## Notas Importantes

1. **Radiación Solar en Gráfica Combinada**: En `SensorLineChart`, los valores de radiación solar están divididos entre 100 para que sean visibles en la misma escala que temperatura y humedad. Para valores reales, usa `SensorChartsView`.

2. **Valores Estimados**: Los valores de radiación solar para las horas 18:00 a 23:00 son estimados basándose en el patrón de disminución típico de la radiación solar al anochecer.

3. **Formato de Hora**: Las horas están en formato 24h (17:00 = 5 PM, 23:00 = 11 PM).

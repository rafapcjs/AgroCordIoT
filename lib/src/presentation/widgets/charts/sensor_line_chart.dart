import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorLineChart extends StatelessWidget {
  const SensorLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos de Sensores por Hora',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              _createChartData(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Temperatura (°C)', Colors.red),
        const SizedBox(width: 16),
        _legendItem('Humedad (%)', Color(0xFF00BCD4)),
        const SizedBox(width: 16),
        _legendItem('Rad. Solar (W/m²)', Color(0xFFFDD835)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartData _createChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              const hours = [
                '17:00',
                '18:00',
                '19:00',
                '20:00',
                '21:00',
                '22:00',
                '23:00',
              ];
              if (value.toInt() >= 0 && value.toInt() < hours.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    hours[value.toInt()],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 42,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        // Línea de Temperatura
        _createLineChartBarData(
          spots: [
            const FlSpot(0, 33.1),
            const FlSpot(1, 33.0),
            const FlSpot(2, 30.4),
            const FlSpot(3, 29.3),
            const FlSpot(4, 26.1),
            const FlSpot(5, 24.4),
            const FlSpot(6, 23.1),
          ],
          color: Colors.red,
          label: 'Temperatura',
        ),
        // Línea de Humedad
        _createLineChartBarData(
          spots: [
            const FlSpot(0, 85),
            const FlSpot(1, 84),
            const FlSpot(2, 88),
            const FlSpot(3, 90),
            const FlSpot(4, 93),
            const FlSpot(5, 82),
            const FlSpot(6, 87),
          ],
          color: Color(0xFF00BCD4),
          label: 'Humedad',
        ),
        // Línea de Radiación Solar (valores escalados para visualización)
        // Nota: Los valores de radiación solar son muy altos (10282.98)
        // Los estoy dividiendo entre 100 para que sean visibles en la misma escala
        // En una implementación real, usarías un segundo eje Y
        _createLineChartBarData(
          spots: [
            const FlSpot(0, 102.83), // 10282.98 / 100
            const FlSpot(1, 95.0),   // Valor estimado
            const FlSpot(2, 80.0),   // Valor estimado
            const FlSpot(3, 60.0),   // Valor estimado
            const FlSpot(4, 40.0),   // Valor estimado
            const FlSpot(5, 20.0),   // Valor estimado
            const FlSpot(6, 10.0),   // Valor estimado
          ],
          color: Color(0xFFFDD835),
          label: 'Radiación Solar',
        ),
      ],
    );
  }

  LineChartBarData _createLineChartBarData({
    required List<FlSpot> spots,
    required Color color,
    required String label,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: color,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }
}

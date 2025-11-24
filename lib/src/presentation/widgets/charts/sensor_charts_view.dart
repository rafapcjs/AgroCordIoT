import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget que muestra gráficas separadas para Temperatura, Humedad y Radiación Solar
class SensorChartsView extends StatelessWidget {
  const SensorChartsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTemperatureChart(),
        const SizedBox(height: 16),
        _buildHumidityChart(),
        const SizedBox(height: 16),
        _buildSolarRadiationChart(),
      ],
    );
  }

  Widget _buildTemperatureChart() {
    return _ChartCard(
      title: 'Temperatura (°C)',
      color: Colors.red,
      icon: Icons.thermostat,
      chart: _buildChart(
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
        minY: 20,
        maxY: 35,
        interval: 5,
      ),
    );
  }

  Widget _buildHumidityChart() {
    return _ChartCard(
      title: 'Humedad (%)',
      color: Colors.blue,
      icon: Icons.water_drop,
      chart: _buildChart(
        spots: [
          const FlSpot(0, 85),
          const FlSpot(1, 84),
          const FlSpot(2, 88),
          const FlSpot(3, 90),
          const FlSpot(4, 93),
          const FlSpot(5, 82),
          const FlSpot(6, 87),
        ],
        color: Colors.blue,
        minY: 80,
        maxY: 95,
        interval: 5,
      ),
    );
  }

  Widget _buildSolarRadiationChart() {
    return _ChartCard(
      title: 'Radiación Solar (W/m²)',
      color: Colors.orange,
      icon: Icons.wb_sunny,
      chart: _buildChart(
        spots: [
          const FlSpot(0, 10282.98),
          const FlSpot(1, 9500.0),
          const FlSpot(2, 7800.0),
          const FlSpot(3, 5200.0),
          const FlSpot(4, 2800.0),
          const FlSpot(5, 1200.0),
          const FlSpot(6, 450.0),
        ],
        color: Colors.orange,
        minY: 0,
        maxY: 11000,
        interval: 2000,
      ),
    );
  }

  Widget _buildChart({
    required List<FlSpot> spots,
    required Color color,
    required double minY,
    required double maxY,
    required double interval,
  }) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: interval,
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
                interval: interval,
                reservedSize: 50,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value >= 1000 
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString(),
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
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: color,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Widget chart;

  const _ChartCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}

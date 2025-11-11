import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/threshold_model.dart';

class ThresholdForm extends StatefulWidget {
  final PlantThresholds? initialValue;
  final Function(PlantThresholds) onThresholdsChanged;

  const ThresholdForm({
    super.key,
    this.initialValue,
    required this.onThresholdsChanged,
  });

  @override
  State<ThresholdForm> createState() => _ThresholdFormState();
}

class _ThresholdFormState extends State<ThresholdForm> {
  late final TextEditingController _tempMinController;
  late final TextEditingController _tempMaxController;
  late final TextEditingController _humMinController;
  late final TextEditingController _humMaxController;
  late final TextEditingController _solarRadMaxController;

  @override
  void initState() {
    super.initState();
    _tempMinController = TextEditingController(
      text: widget.initialValue?.temperature.min?.toString() ?? '19',
    );
    _tempMaxController = TextEditingController(
      text: widget.initialValue?.temperature.max?.toString() ?? '30',
    );
    _humMinController = TextEditingController(
      text: widget.initialValue?.humidity.min?.toString() ?? '45',
    );
    _humMaxController = TextEditingController(
      text: widget.initialValue?.humidity.max?.toString() ?? '80',
    );
    _solarRadMaxController = TextEditingController(
      text: widget.initialValue?.solarRadiation.max?.toString() ?? '850',
    );

    // Notificar los valores iniciales después de que el frame se haya construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyThresholdsChanged();
    });
  }

  @override
  void dispose() {
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _humMinController.dispose();
    _humMaxController.dispose();
    _solarRadMaxController.dispose();
    super.dispose();
  }

  void _notifyThresholdsChanged() {
    final thresholds = PlantThresholds(
      temperature: SensorThreshold(
        min: double.tryParse(_tempMinController.text),
        max: double.tryParse(_tempMaxController.text),
      ),
      humidity: SensorThreshold(
        min: double.tryParse(_humMinController.text),
        max: double.tryParse(_humMaxController.text),
      ),
      // Soil humidity input removed from the form UI. Preserve existing value
      // from initialValue when present, otherwise keep nulls.
      soilHumidity: widget.initialValue?.soilHumidity ?? SensorThreshold(min: null),
      solarRadiation: SensorThreshold(
        max: double.tryParse(_solarRadMaxController.text),
      ),
    );
    widget.onThresholdsChanged(thresholds);
  }

  Widget _buildThresholdField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onChanged: (value) => _notifyThresholdsChanged(),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Umbrales de Sensores',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Temperatura',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildThresholdField(
                label: 'Mínimo',
                controller: _tempMinController,
                suffix: '°C',
                icon: Icons.thermostat,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildThresholdField(
                label: 'Máximo',
                controller: _tempMaxController,
                suffix: '°C',
                icon: Icons.thermostat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Humedad',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildThresholdField(
                label: 'Mínimo',
                controller: _humMinController,
                suffix: '%',
                icon: Icons.water_drop,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildThresholdField(
                label: 'Máximo',
                controller: _humMaxController,
                suffix: '%',
                icon: Icons.water_drop,
              ),
            ),
          ],
        ),

        // Humedad del Suelo field removed per request (no input for soil humidity
        // when creating or editing plants). The value is preserved via
        // `initialValue` if present.
        Text(
          'Radiación Solar',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildThresholdField(
          label: 'Máximo',
          controller: _solarRadMaxController,
          suffix: 'W/m²',
          icon: Icons.wb_sunny,
        ),
      ],
    );
  }
}

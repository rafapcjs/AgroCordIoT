import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/fcm_service.dart';
import '../../services/websocket_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() => _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  final fcmService = FCMService();
  final wsService = WebSocketService();
  final localNotifications = FlutterLocalNotificationsPlugin();

  String _statusMessage = 'Esperando acción...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await localNotifications.initialize(initSettings);

    // Crear canal
    const androidChannel = AndroidNotificationChannel(
      'test_channel',
      'Pruebas',
      description: 'Canal para pruebas de notificaciones',
      importance: Importance.max,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _testLocalNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando notificación local...';
    });

    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Pruebas',
        channelDescription: 'Canal para pruebas de notificaciones',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await localNotifications.show(
        DateTime.now().millisecond,
        '🔔 Prueba de Notificación',
        'Si ves esto, las notificaciones locales funcionan! ✅',
        details,
      );

      setState(() {
        _statusMessage = '✅ Notificación local enviada! Revisa la barra de estado.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showToken() async {
    final token = fcmService.currentToken;
    if (token != null) {
      await Clipboard.setData(ClipboardData(text: token));
      setState(() {
        _statusMessage = '✅ Token copiado al portapapeles!\n${token.substring(0, 50)}...';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token FCM copiado al portapapeles')),
        );
      }
    } else {
      setState(() {
        _statusMessage = '❌ No hay token FCM disponible';
      });
    }
  }

  Future<void> _reinitializeFCM() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Reinicializando FCM...';
    });

    try {
      await fcmService.initialize();
      final token = fcmService.currentToken;

      setState(() {
        _statusMessage = token != null
          ? '✅ FCM reinicializado!\nToken: ${token.substring(0, 30)}...'
          : '⚠️ FCM inicializado pero sin token';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error reinicializando: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testWebSocket() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Probando WebSocket...';
    });

    try {
      if (!wsService.isConnected) {
        await wsService.connect();
      }

      final token = fcmService.currentToken;
      if (token != null) {
        await wsService.registerToken(token);
        setState(() {
          _statusMessage = '✅ Token enviado por WebSocket';
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusMessage = '⚠️ No hay token FCM para enviar';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error WebSocket: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Notificaciones'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Información
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('FCM Token:', fcmService.currentToken != null ? 'Disponible ✅' : 'No disponible ❌'),
                    _buildInfoRow('WebSocket:', wsService.isConnected ? 'Conectado ✅' : 'Desconectado ❌'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de prueba
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLocalNotification,
              icon: const Icon(Icons.notifications),
              label: const Text('Probar Notificación Local'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _showToken,
              icon: const Icon(Icons.key),
              label: const Text('Ver/Copiar Token FCM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _reinitializeFCM,
              icon: const Icon(Icons.refresh),
              label: const Text('Reinicializar FCM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testWebSocket,
              icon: const Icon(Icons.wifi),
              label: const Text('Probar WebSocket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Instrucciones
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Instrucciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Presiona "Probar Notificación Local" para verificar que las notificaciones funcionan',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2. Si funciona, el problema está en FCM, no en el sistema de notificaciones',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3. Copia el token FCM y úsalo para enviar notificaciones de prueba',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '4. Revisa los logs de Flutter para ver mensajes de error',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

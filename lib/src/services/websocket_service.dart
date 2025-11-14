import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Servicio para manejar conexión WebSocket con el backend
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // URL del WebSocket
  final String _wsUrl =
      'ws://ec2-98-86-100-220.compute-1.amazonaws.com:3000';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);

  // Callbacks para eventos
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  /// Estado de conexión
  bool get isConnected => _isConnected;

  /// Conectar al WebSocket
  Future<void> connect() async {
    if (_isConnected) {
      if (kDebugMode) {
        print('⚠️ WebSocket already connected');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔌 Connecting to WebSocket: $_wsUrl');
      }

      _channel = WebSocketChannel.connect(
        Uri.parse(_wsUrl),
      );

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      if (kDebugMode) {
        print('✅ WebSocket connected successfully');
      }

      onConnected?.call();

      // Iniciar ping periódico
      _startPingTimer();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error connecting to WebSocket: $e');
      }
      _scheduleReconnect();
    }
  }

  /// Desconectar del WebSocket
  Future<void> disconnect() async {
    _shouldReconnect = false;
    await _cleanup();

    if (kDebugMode) {
      print('🔌 WebSocket disconnected');
    }
  }

  /// Limpiar recursos
  Future<void> _cleanup() async {
    _stopPingTimer();
    _stopReconnectTimer();

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _isConnected = false;
  }

  /// Manejar mensaje recibido
  void _onMessage(dynamic message) {
    try {
      if (kDebugMode) {
        print('📨 WebSocket message received: $message');
      }

      if (message is String) {
        final data = jsonDecode(message) as Map<String, dynamic>;
        onMessageReceived?.call(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing WebSocket message: $e');
      }
      onError?.call(e);
    }
  }

  /// Manejar error
  void _onError(dynamic error) {
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }

    _isConnected = false;
    onError?.call(error);
    _scheduleReconnect();
  }

  /// Manejar cierre de conexión
  void _onDone() {
    if (kDebugMode) {
      print('🔌 WebSocket connection closed');
    }

    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  /// Programar reconexión
  void _scheduleReconnect() {
    if (!_shouldReconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('⚠️ Max reconnect attempts reached');
      }
      return;
    }

    _reconnectAttempts++;

    if (kDebugMode) {
      print('🔄 Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds}s');
    }

    _stopReconnectTimer();
    _reconnectTimer = Timer(_reconnectDelay, () {
      connect();
    });
  }

  /// Detener timer de reconexión
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Iniciar timer de ping
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected) {
        sendMessage({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
      }
    });
  }

  /// Detener timer de ping
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Enviar mensaje
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) {
        print('⚠️ Cannot send message: WebSocket not connected');
      }
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);

      if (kDebugMode) {
        print('📤 WebSocket message sent: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending WebSocket message: $e');
      }
      onError?.call(e);
    }
  }

  /// Obtener device ID
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown_device';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.brand}_${androidInfo.model}'
            .replaceAll(' ', '_')
            .toLowerCase();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = '${iosInfo.name}_${iosInfo.model}'
            .replaceAll(' ', '_')
            .toLowerCase();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device ID: $e');
      }
    }

    return deviceId;
  }

  /// Registrar token FCM via WebSocket
  Future<void> registerToken(String token) async {
    final deviceId = await _getDeviceId();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    final message = {
      'type': 'registerToken',
      'token': token,
      'deviceId': deviceId,
      'platform': platform,
      'timestamp': DateTime.now().toIso8601String(),
    };

    sendMessage(message);
  }

  /// Subscribirse a alertas de un dispositivo específico
  void subscribeToDevice(String deviceId) {
    sendMessage({
      'type': 'subscribe',
      'deviceId': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Desubscribirse de alertas de un dispositivo
  void unsubscribeFromDevice(String deviceId) {
    sendMessage({
      'type': 'unsubscribe',
      'deviceId': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Enviar confirmación de lectura de notificación
  void acknowledgeNotification(String messageId) {
    sendMessage({
      'type': 'acknowledge',
      'messageId': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Resetear contador de reconexión
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Disponer recursos
  Future<void> dispose() async {
    _shouldReconnect = false;
    await _cleanup();
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('🔔 Background message received: ${message.messageId}');
    print('📦 Data: ${message.data}');
  }
}

/// Servicio para manejar notificaciones push con Firebase Cloud Messaging
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // URL del backend para registro de tokens
  final String _registerTokenUrl =
      'http://ec2-98-86-100-220.compute-1.amazonaws.com:3000/api/notifications/tokens';

  String? _currentToken;
  bool _isInitialized = false;

  /// Obtener el token actual
  String? get currentToken => _currentToken;

  /// Inicializar el servicio de FCM
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('⚠️ FCM Service already initialized');
      }
      return;
    }

    try {
      // Inicializar notificaciones locales
      await _initializeLocalNotifications();

      // Solicitar permisos
      await _requestPermissions();

      // Configurar handlers de mensajes
      _setupMessageHandlers();

      // Obtener y registrar token
      await _getAndRegisterToken();

      // Escuchar cambios de token
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ FCM Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FCM Service: $e');
      }
    }
  }

  /// Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) {
      // En web no usamos notificaciones locales
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const androidChannel = AndroidNotificationChannel(
      'sensor_alerts_channel',
      'Alertas de Sensores',
      description: 'Notificaciones de alertas de sensores IoT',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Solicitar permisos de notificaciones
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('📱 Permission status: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('✅ User granted notification permissions');
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('⚠️ User granted provisional notification permissions');
      }
    } else {
      if (kDebugMode) {
        print('❌ User declined notification permissions');
      }
    }
  }

  /// Configurar handlers de mensajes
  void _setupMessageHandlers() {
    // Mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Cuando la app se abre desde una notificación (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verificar si la app se abrió desde una notificación (terminated)
    _checkInitialMessage();
  }

  /// Obtener el device ID
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

  /// Obtener y registrar token FCM
  Future<void> _getAndRegisterToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        if (kDebugMode) {
          print('🔑 FCM Token: $token');
        }
        await _registerTokenWithBackend(token);
      } else {
        if (kDebugMode) {
          print('⚠️ Failed to get FCM token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
    }
  }

  /// Callback cuando el token se refresca
  Future<void> _onTokenRefresh(String newToken) async {
    _currentToken = newToken;
    if (kDebugMode) {
      print('🔄 Token refreshed: $newToken');
    }
    await _registerTokenWithBackend(newToken);
  }

  /// Registrar token con el backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final deviceId = await _getDeviceId();
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final body = {
        'token': token,
        'deviceId': deviceId,
        'platform': platform,
      };

      if (kDebugMode) {
        print('📤 Registering token with backend: $body');
      }

      final response = await http.post(
        Uri.parse(_registerTokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Token registered successfully: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Failed to register token: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error registering token with backend: $e');
      }
    }
  }

  /// Manejar mensajes en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📩 Foreground message received: ${message.messageId}');
      print('📦 Data: ${message.data}');
      print('🔔 Notification: ${message.notification?.title}');
    }

    _showLocalNotification(message);
  }

  /// Manejar cuando se abre la app desde una notificación (background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('🚀 App opened from notification: ${message.messageId}');
      print('📦 Data: ${message.data}');
    }

    _handleNotificationAction(message.data);
  }

  /// Verificar si la app se abrió desde una notificación (terminated)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('🚀 App opened from terminated state: ${initialMessage.messageId}');
        print('📦 Data: ${initialMessage.data}');
      }

      _handleNotificationAction(initialMessage.data);
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Usar el mismo método que WebSocket para consistencia
    await showNotificationFromData(message.data);
  }

  /// Construir mensaje desde datos
  String _buildMessageFromData(Map<String, dynamic> data) {
    if (data.isEmpty) return 'Nueva notificación';

    final sensorType = data['sensorType'] ?? '';
    final value = data['value']?.toString() ?? '';
    final unit = data['unit'] ?? '';
    final plantName = data['plantName'] ?? '';

    if (sensorType.isNotEmpty && value.isNotEmpty) {
      return '$plantName: $sensorType $value$unit';
    }

    return data.toString();
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('👆 Notification tapped: ${response.payload}');
    }

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationAction(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing notification payload: $e');
        }
      }
    }
  }

  /// Manejar acción de notificación
  void _handleNotificationAction(Map<String, dynamic> data) {
    // Aquí puedes implementar navegación o acciones específicas
    // basadas en el tipo de notificación
    if (kDebugMode) {
      print('🎯 Handling notification action: $data');
    }

    // Ejemplo: navegar a una pantalla específica basada en el evento
    final event = data['event'];
    final deviceId = data['deviceId'];

    if (event == 'sensorAlert' && deviceId != null) {
      // Aquí puedes usar un NavigatorKey global para navegar
      // o emitir un evento que sea escuchado por la UI
      if (kDebugMode) {
        print('🔔 Sensor alert for device: $deviceId');
      }
    }
  }

  /// Subscribirse a un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic: $e');
      }
    }
  }

  /// Desubscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic: $e');
      }
    }
  }

  /// Eliminar token (útil para logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _currentToken = null;
      if (kDebugMode) {
        print('✅ FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting token: $e');
      }
    }
  }

  /// Mostrar notificación desde datos (para WebSocket u otras fuentes)
  Future<void> showNotificationFromData(Map<String, dynamic> data) async {
    // Construir título con nombre de planta
    final plantName = data['plantName']?.toString() ?? '';
    final deviceId = data['deviceId']?.toString() ?? '';
    final sensorType = data['sensorType']?.toString() ?? '';
    final thresholdType = data['thresholdType']?.toString() ?? '';

    String title;
    if (plantName.isNotEmpty) {
      title = '🌱 $plantName';
    } else if (deviceId.isNotEmpty) {
      title = '📟 $deviceId';
    } else {
      title = '⚠️ Alerta de Sensor';
    }

    // Construir cuerpo del mensaje
    final message = data['message']?.toString();
    final value = data['value'];
    final unit = data['unit']?.toString() ?? '';

    String body;
    if (message != null && message.isNotEmpty) {
      body = message;
    } else {
      body = _buildMessageFromData(data);
    }

    // Construir texto expandido con más detalles
    final sensorTypeFormatted = _formatSensorType(sensorType);
    String bigText = '';
    String summaryText = '';

    if (sensorType.isNotEmpty) {
      bigText = '$sensorTypeFormatted: $value$unit\n\n$body';
      summaryText = '$sensorTypeFormatted: $value$unit';
    } else {
      bigText = body;
      summaryText = body;
    }

    // Si es web, no mostrar notificaciones (solo mobile)
    if (kIsWeb) {
      if (kDebugMode) {
        print('ℹ️ Web: Notificación recibida pero no se muestra: $title - $summaryText');
      }
      return;
    }

    // Determinar color según tipo de umbral
    Color notificationColor;
    Priority priority;
    Importance importance;

    if (thresholdType == 'max') {
      notificationColor = const Color(0xFFFF5252); // Rojo para máximo excedido
      priority = Priority.max;
      importance = Importance.max;
    } else if (thresholdType == 'min') {
      notificationColor = const Color(0xFFFF9800); // Naranja para mínimo
      priority = Priority.high;
      importance = Importance.high;
    } else {
      notificationColor = const Color(0xFF4CAF50); // Verde para info
      priority = Priority.defaultPriority;
      importance = Importance.defaultImportance;
    }

    final androidDetails = AndroidNotificationDetails(
      'sensor_alerts_channel',
      'Alertas de Sensores',
      channelDescription: 'Notificaciones de alertas de sensores IoT',
      importance: importance,
      priority: priority,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,

      // Sonido y vibración
      enableVibration: true,
      playSound: true,
      // sound: const RawResourceAndroidNotificationSound('notification_sound'), // Descomenta si agregas sonido personalizado

      // Patrón de vibración personalizado (en milisegundos)
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),

      // LED de notificación
      enableLights: true,
      color: notificationColor,
      ledColor: notificationColor,
      ledOnMs: 1000,
      ledOffMs: 500,

      // Estilo visual mejorado
      styleInformation: BigTextStyleInformation(
        bigText,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: summaryText,
        htmlFormatSummaryText: false,
      ),

      // Icono y apariencia
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),

      // Comportamiento
      autoCancel: true,
      ongoing: false,
      onlyAlertOnce: false,
      showProgress: false,
      maxProgress: 0,
      progress: 0,
      indeterminate: false,

      // Categoría
      category: AndroidNotificationCategory.alarm,

      // Visibilidad
      visibility: NotificationVisibility.public,

      // Ticker (texto que aparece en la barra de estado)
      ticker: '$plantName - $sensorTypeFormatted alerta',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
      badgeNumber: 1,
      threadIdentifier: 'sensor_alerts',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      title,
      summaryText,
      details,
      payload: jsonEncode(data),
    );

    if (kDebugMode) {
      print('✅ Notification shown: $title - $summaryText');
    }
  }

  /// Formatear el tipo de sensor para mostrar
  String _formatSensorType(String sensorType) {
    final Map<String, String> sensorNames = {
      'temperature': '🌡️ Temperatura',
      'humidity': '💧 Humedad',
      'soil_humidity': '🌾 Humedad del Suelo',
      'solar_radiation': '☀️ Radiación Solar',
      'pressure': '🌀 Presión',
      'light': '💡 Luz',
      'ph': '⚗️ pH',
    };

    return sensorNames[sensorType] ?? sensorType.toUpperCase();
  }
}


import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iot/src/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'src/core/theme.dart';
import 'src/presentation/screens/login_screen.dart';
import 'src/presentation/screens/dashboard_screen.dart';
import 'src/presentation/screens/internal_report_screen.dart';
import 'src/presentation/screens/monthly_report_screen.dart';
import 'src/presentation/screens/sensor_dashboard_screen.dart';
import 'src/pages/weekly_report_page.dart';
import 'src/pages/dashboard_user_page.dart';
import 'src/providers/auth_provider.dart';
import 'src/data/repositories/auth_repository.dart';
import 'src/data/network_service.dart';
import 'src/services/deep_link_service.dart';
import 'src/services/fcm_service.dart';
import 'src/services/websocket_service.dart';
import 'src/presentation/screens/reset_password_screen.dart';

/// Background message handler - must be a top-level function (solo para mobile)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔔 Background message: ${message.messageId}');
    print('📦 Data: ${message.data}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registrar el handler de mensajes en background (solo mobile)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Inicializar Deep Links (solo mobile)
  if (!kIsWeb) {
    DeepLinkService.initialize();
  }

  // Verificar onboarding
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

  // Inicializar servicios solo en mobile para evitar errores en web
  if (!kIsWeb) {
    try {
      await FCMService().initialize();
    } catch (e) {
      print('Error inicializando FCM: $e');
    }
  }

  // Conectar WebSocket en background (no bloqueante)
  final wsService = WebSocketService();
  final fcmService = kIsWeb ? null : FCMService();

  wsService.onMessageReceived = (data) async {
    print('📨 WebSocket message received: $data');
    if (!kIsWeb && data['event'] == 'sensorAlert' && fcmService != null) {
      try {
        await fcmService.showNotificationFromData(data);
      } catch (e) {
        print('Error mostrando notificación: $e');
      }
    }
  };

  wsService.onConnected = () => print('✅ WebSocket connected');
  wsService.onDisconnected = () => print('⚠️ WebSocket disconnected');
  wsService.onError = (error) => print('❌ WebSocket error: $error');

  // Conectar en background sin bloquear
  wsService.connect().catchError((e) => print('Error WebSocket: $e'));

  // Registrar token solo en mobile
  if (!kIsWeb && fcmService != null) {
    final fcmToken = fcmService.currentToken;
    if (fcmToken != null) {
      wsService.registerToken(fcmToken).catchError((e) => print('Error token: $e'));
    }
  }

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider(
              authRepository: AuthRepository(
                networkService: NetworkService(),
              ),
            );

            // Inicializar la autenticación
            authProvider.initializeAuth();

            return authProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'AgroCordIot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: DeepLinkService.navigatorKey,
        home: onboardingCompleted ? const AuthWrapper() : const OnboardingScreen(),
        routes: {
          '/reset-password': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ResetPasswordScreen(token: args['token']);
          },
          '/sensors/dashboard': (context) {
            final args = (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ?? {};
            final token = args['accessToken'] as String? ?? '';
            return SensorDashboardScreen(accessToken: token);
          },
          '/reports/internal': (context) {
            final args = (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ?? {};
            final token = args['accessToken'] as String? ?? '';
            final deviceId = args['deviceId'] as String? ?? 'ESP32_1';
            return InternalReportScreen(
              accessToken: token,
              initialDeviceId: deviceId,
            );
          },
          '/reports/external': (context) {
            final args = (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ?? {};
            final token = args['accessToken'] as String? ?? '';
            return InternalReportScreen(
              accessToken: token,
              initialDeviceId: 'ESP32_2',
            );
          },
          '/reports/monthly': (context) {
            final args = (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ?? {};
            final token = args['accessToken'] as String? ?? '';
            return MonthlyReportScreen(accessToken: token);
          },
          '/reports/weekly': (context) {
            final args = (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ?? {};
            final token = args['accessToken'] as String? ?? '';
            return WeeklyReportPage(accessToken: token);
          },
          '/dashboard/user': (context) {
            final args = (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ?? {};
            final token = args['accessToken'] as String? ?? '';
            return DashboardUserPage(accessToken: token);
          },
        },
      ),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Debug log para tracking
        debugPrint('🔄 AuthWrapper state: ${authProvider.state}');
        debugPrint('🔄 Usuario: ${authProvider.currentUser?.name ?? "null"}');
        debugPrint('🔄 Rol: ${authProvider.currentUser?.role ?? "null"}');
        
        switch (authProvider.state) {
          case AuthState.loading:
          case AuthState.initial:
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          case AuthState.authenticated:
            // Verificar el rol del usuario y redirigir al dashboard correspondiente
            final userRole = authProvider.currentUser?.role ?? '';
            
            debugPrint('✅ Usuario autenticado - Role: $userRole');
            
            if (userRole == 'admin') {
              debugPrint('📍 Redirigiendo a DashboardScreen (Admin)');
              return DashboardScreen(
                accessToken: authProvider.accessToken ?? '',
              );
            } else {
              // Para usuarios normales, mostrar el dashboard de usuario
              debugPrint('📍 Redirigiendo a DashboardUserPage (User)');
              return DashboardUserPage(
                accessToken: authProvider.accessToken ?? '',
              );
            }
          case AuthState.unauthenticated:
            debugPrint('🚪 Usuario no autenticado - Mostrando LoginScreen');
            return const LoginScreen();
          case AuthState.error:
            debugPrint('❌ Error de autenticación - Mostrando LoginScreen');
            return const LoginScreen();
        }
      },
    );
  }
}

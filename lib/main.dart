
import 'package:flutter/material.dart';
import 'package:iot/src/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/core/theme.dart';
import 'src/presentation/screens/login_screen.dart';
import 'src/presentation/screens/dashboard_screen.dart';
import 'src/presentation/screens/internal_report_screen.dart';
import 'src/presentation/screens/monthly_report_screen.dart';
import 'src/presentation/screens/sensor_dashboard_screen.dart';
import 'src/providers/auth_provider.dart';
import 'src/data/repositories/auth_repository.dart';
import 'src/data/network_service.dart';
import 'src/services/deep_link_service.dart';
import 'src/presentation/screens/reset_password_screen.dart';
 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DeepLinkService.initialize();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

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
            return DashboardScreen(
              accessToken: authProvider.accessToken ?? '',
            );
          case AuthState.unauthenticated:
          case AuthState.error:
            return const LoginScreen();
        }
      },
    );
  }
}

import 'package:flutter/foundation.dart';
import 'dart:async';
import '../data/services/user_service.dart';
import '../providers/auth_provider.dart';

class UserUpdateProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  static final UserUpdateProvider _instance = UserUpdateProvider._internal();
  
  factory UserUpdateProvider() => _instance;
  UserUpdateProvider._internal();

  AuthProvider? _authProvider;
  Timer? _refreshTimer;

  // Configurar el AuthProvider para poder actualizarlo
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Método que se llama cuando un usuario es actualizado
  Future<void> onUserUpdated(String userId, {bool forceRefresh = false}) async {
    debugPrint('🔄 UserUpdateProvider: Usuario actualizado - ID: $userId');
    
    // Si el usuario actualizado es el usuario actual, refrescar inmediatamente
    if (_authProvider?.currentUser?.id == userId || forceRefresh) {
      debugPrint('🎯 UserUpdateProvider: Es el usuario actual, refrescando...');
      await _refreshCurrentUserFromServer();
    }
  }

  // Método que se llama cuando un usuario es eliminado  
  Future<void> onUserDeleted(String userId) async {
    debugPrint('🗑️ UserUpdateProvider: Usuario eliminado - ID: $userId');
    
    // Si el usuario eliminado es el usuario actual, hacer logout
    if (_authProvider?.currentUser?.id == userId) {
      debugPrint('⚠️ UserUpdateProvider: Usuario actual eliminado, cerrando sesión');
      await _authProvider?.logout();
    }
  }

  // Refrescar la información del usuario actual desde el servidor
  Future<void> _refreshCurrentUserFromServer() async {
    if (_authProvider?.accessToken == null) {
      debugPrint('❌ UserUpdateProvider: No hay token de acceso');
      return;
    }

    try {
      debugPrint('🌐 UserUpdateProvider: Haciendo petición al servidor...');
      
      // Hacer petición al servidor para obtener información actualizada
      final updatedUser = await _userService.getAuthenticatedUser(_authProvider!.accessToken!);
      
      debugPrint('✅ UserUpdateProvider: Usuario obtenido del servidor: ${updatedUser.name} ${updatedUser.lastName}');
      
      // Actualizar el AuthProvider directamente
      _authProvider!.updateCurrentUser(updatedUser);
      
      debugPrint('🔄 UserUpdateProvider: AuthProvider actualizado exitosamente');
      
    } catch (e) {
      debugPrint('❌ UserUpdateProvider: Error al refrescar usuario: $e');
    }
  }

  // Método para forzar refresh manual
  Future<void> forceRefreshCurrentUser() async {
    debugPrint('🔄 UserUpdateProvider: Refresh manual solicitado');
    await _refreshCurrentUserFromServer();
  }

  // Método para programar refresh automático
  void scheduleRefresh({Duration delay = const Duration(milliseconds: 500)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () async {
      debugPrint('⏰ UserUpdateProvider: Refresh programado ejecutándose');
      await _refreshCurrentUserFromServer();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
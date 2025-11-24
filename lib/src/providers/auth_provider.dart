import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/user_service.dart';
import '../core/exceptions.dart';
import '../services/event_bus.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserService _userService = UserService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';

  late StreamSubscription<UserUpdatedEvent> _userUpdateSubscription;
  late StreamSubscription<UserDeletedEvent> _userDeleteSubscription;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _setupEventListeners();
  }

  AuthState _state = AuthState.initial;
  String? _accessToken;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthState get state => _state;
  String? get accessToken => _accessToken;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated && _accessToken != null;
  bool get isLoading => _state == AuthState.loading;

  Future<void> initializeAuth() async {
    try {
      _state = AuthState.loading;
      notifyListeners();

      final token = await _storage.read(key: _tokenKey);
      
      if (token != null && token.isNotEmpty) {
        if (!JwtDecoder.isExpired(token)) {
          _accessToken = token;
          await _loadUserFromToken(token);
          _state = AuthState.authenticated;
        } else {
          await logout();
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
    }
    
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      debugPrint('🔐 Iniciando login para: $username');
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final authModel = await _authRepository.authenticate(username, password);
      debugPrint('✅ Autenticación exitosa, token recibido');
      
      if (!JwtDecoder.isExpired(authModel.accessToken)) {
        _accessToken = authModel.accessToken;
        await _loadUserFromToken(authModel.accessToken);
        
        debugPrint('👤 Usuario actual: ${_currentUser?.name} ${_currentUser?.lastName}');
        debugPrint('🎭 Rol del usuario: ${_currentUser?.role}');
        
        // Permitir acceso tanto a admin como a usuarios normales
        // Ya no se valida solo admin, cada uno tendrá su dashboard correspondiente

        await _storage.write(key: _tokenKey, value: authModel.accessToken);
        if (_currentUser != null) {
          await _storage.write(key: _userKey, value: _currentUser!.toJson().toString());
        }

        _state = AuthState.authenticated;
        debugPrint('✅ Login completado - Estado: authenticated');
        notifyListeners();
        return true;
      } else {
        throw AuthenticationException('Token expirado');
      }
    } on AppException catch (e) {
      debugPrint('❌ Error de autenticación: ${e.message}');
      _state = AuthState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error inesperado: ${e.toString()}');
      _state = AuthState.error;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('🔓 AuthProvider: Iniciando logout...');
    
    try {
      // Limpiar storage
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
      debugPrint('✅ Storage limpiado');
    } catch (e) {
      debugPrint('❌ Error limpiando storage: $e');
    }

    // Limpiar todo
    _accessToken = null;
    _currentUser = null;
    _errorMessage = null;
    _state = AuthState.unauthenticated;
    
    debugPrint('✅ Logout completado - Estado: unauthenticated');
    notifyListeners();
  }

  Future<void> _loadUserFromToken(String token) async {
    try {
      final decodedToken = JwtDecoder.decode(token);
      
      debugPrint('🔍 Token decodificado:');
      debugPrint('  - sub: ${decodedToken['sub']}');
      debugPrint('  - name: ${decodedToken['name']}');
      debugPrint('  - role: ${decodedToken['role']}');
      
      _currentUser = UserModel(
        id: decodedToken['sub']?.toString() ?? '',
        name: decodedToken['name']?.toString() ?? '',
        lastName: decodedToken['lastName']?.toString() ?? '',
        phone: decodedToken['phone']?.toString() ?? '',
        email: decodedToken['email']?.toString() ?? '',
        username: decodedToken['username']?.toString() ?? '',
        role: decodedToken['role']?.toString() ?? '',
        createdAt: decodedToken['createdAt']?.toString() ?? '',
        updatedAt: decodedToken['updatedAt']?.toString() ?? '',
      );
      
      debugPrint('✅ Usuario cargado desde token: ${_currentUser!.name} ${_currentUser!.lastName} - Role: ${_currentUser!.role}');
    } catch (e) {
      debugPrint('❌ Error al procesar token: $e');
      throw AuthenticationException('Error al procesar token de usuario');
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _accessToken != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Método para actualizar la información del usuario actual
  void updateCurrentUser(UserModel updatedUser) {
    if (_currentUser != null && _currentUser!.id == updatedUser.id) {
      _currentUser = updatedUser;
      notifyListeners();
      
      // Guardar en storage local también
      _storage.write(key: _userKey, value: updatedUser.toJson().toString());
    }
  }

  // Método para refrescar la información del usuario desde el servidor
  Future<void> refreshCurrentUser() async {
    if (_accessToken == null) {
      debugPrint('⚠️ No hay token de acceso, no se puede refrescar usuario');
      _state = AuthState.unauthenticated;
      _currentUser = null;
      notifyListeners();
      return;
    }
    
    try {
      debugPrint('🔄 Refrescando información del usuario desde el servidor...');
      debugPrint('🔑 Token: ${_accessToken!.substring(0, 20)}...');
      
      // Hacer llamada real al servidor para obtener información actualizada
      final updatedUser = await _userService.getAuthenticatedUser(_accessToken!);
      
      _currentUser = updatedUser;
      
      // Guardar en storage local también
      await _storage.write(key: _userKey, value: updatedUser.toJson().toString());
      
      debugPrint('✅ Usuario actualizado desde servidor: ${updatedUser.name} ${updatedUser.lastName}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing user from server: $e');
      debugPrint('🔄 Intentando cargar usuario desde token como fallback...');
      
      // Si falla la llamada al servidor, intentar recargar desde el token como fallback
      try {
        await _loadUserFromToken(_accessToken!);
        debugPrint('✅ Usuario cargado desde token exitosamente');
        notifyListeners();
      } catch (tokenError) {
        debugPrint('❌ Error loading user from token: $tokenError');
        // En caso de error, cerrar sesión
        await logout();
      }
    }
  }

  // Verificar información del usuario desde el servidor en segundo plano
  Future<void> _verifyUserFromServer() async {
    if (_accessToken == null) return;
    
    try {
      debugPrint('🔍 Verificando información del usuario desde el servidor...');
      
      // Hacer llamada al servidor para verificar información
      final serverUser = await _userService.getAuthenticatedUser(_accessToken!);
      
      // Solo actualizar si hay diferencias significativas
      if (_currentUser != null && _hasSignificantDifferences(_currentUser!, serverUser)) {
        debugPrint('📱 Diferencias detectadas, actualizando desde servidor...');
        _currentUser = serverUser;
        
        // Guardar en storage local
        await _storage.write(key: _userKey, value: serverUser.toJson().toString());
        
        // Notificar cambios
        notifyListeners();
        
        debugPrint('✅ Usuario verificado y actualizado desde servidor');
      } else {
        debugPrint('✅ Usuario verificado, sin cambios necesarios');
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando usuario desde servidor: $e');
      // Silenciar el error ya que es una verificación en segundo plano
    }
  }

  // Helper para detectar diferencias significativas entre usuarios
  bool _hasSignificantDifferences(UserModel current, UserModel server) {
    return current.name != server.name ||
           current.lastName != server.lastName ||
           current.email != server.email ||
           current.phone != server.phone ||
           current.role != server.role ||
           current.updatedAt != server.updatedAt;
  }

  // Configurar listeners para eventos de usuario
  void _setupEventListeners() {
    debugPrint('🎧 AuthProvider: Configurando listeners de eventos...');
    
    _userUpdateSubscription = EventBus().on<UserUpdatedEvent>().listen((event) {
      debugPrint('📢 AuthProvider: Evento UserUpdatedEvent recibido para usuario: ${event.updatedUser.id}');
      _handleUserUpdated(event.updatedUser);
    });

    _userDeleteSubscription = EventBus().on<UserDeletedEvent>().listen((event) {
      debugPrint('📢 AuthProvider: Evento UserDeletedEvent recibido para usuario: ${event.userId}');
      _handleUserDeleted(event.userId);
    });
    
    debugPrint('✅ AuthProvider: Listeners configurados exitosamente');
  }

  // Manejar cuando un usuario es actualizado
  void _handleUserUpdated(UserModel updatedUser) {
    // Si el usuario actualizado es el usuario actual, actualizar inmediatamente
    if (_currentUser != null && _currentUser!.id == updatedUser.id) {
      debugPrint('🎯 AuthProvider: Usuario actual detectado en evento, actualizando información...');
      
      // Actualizar inmediatamente con los datos del evento
      _currentUser = updatedUser;
      
      // Guardar en storage local también
      _storage.write(key: _userKey, value: updatedUser.toJson().toString());
      
      // Notificar inmediatamente para refrescar la UI
      notifyListeners();
      
      debugPrint('✅ AuthProvider: Usuario actualizado inmediatamente: ${updatedUser.name} ${updatedUser.lastName}');
      
      // Opcionalmente, hacer una verificación desde el servidor en segundo plano
      Timer(const Duration(milliseconds: 500), () {
        _verifyUserFromServer();
      });
    }
  }

  // Manejar cuando un usuario es eliminado
  void _handleUserDeleted(String deletedUserId) {
    // Si el usuario eliminado es el usuario actual, hacer logout
    if (_currentUser != null && _currentUser!.id == deletedUserId) {
      debugPrint('Usuario actual eliminado, cerrando sesión');
      logout();
    }
  }

  @override
  void dispose() {
    _userUpdateSubscription.cancel();
    _userDeleteSubscription.cancel();
    super.dispose();
  }
}
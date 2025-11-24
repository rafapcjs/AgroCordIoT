import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_bus.dart';

class UserInfoWidget extends StatefulWidget {
  final String accessToken;
  final VoidCallback onLogout;

  const UserInfoWidget({
    super.key,
    required this.accessToken,
    required this.onLogout,
  });

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  bool _isLoading = false;
  late StreamSubscription<UserUpdatedEvent> _userUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventListeners();
  }

  @override
  void dispose() {
    _userUpdateSubscription.cancel();
    super.dispose();
  }

  void _setupEventListeners() {
    // Escuchar eventos de actualización de usuario
    _userUpdateSubscription = EventBus().on<UserUpdatedEvent>().listen((event) {
      debugPrint('🔄 UserInfoWidget: Recibido evento de actualización de usuario: ${event.updatedUser.name}');
      
      if (mounted) {
        // Obtener el AuthProvider y verificar si el usuario actualizado es el actual
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser?.id == event.updatedUser.id) {
          debugPrint('✅ UserInfoWidget: Actualizando usuario en AuthProvider');
          // Actualizar el usuario en el AuthProvider
          authProvider.updateCurrentUser(event.updatedUser);
          
          // Comentado: La notificación automática puede ser molesta para el usuario
          // Solo actualizar los datos sin mostrar notificación
          /*
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.sync, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Tu información se ha actualizado automáticamente'),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          */
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: _isLoading ? 
                const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                ) : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.white,
                  size: 20,
                ),
          ),
          onPressed: _isLoading ? null : () => _showUserInfoModal(authProvider),
        );
      },
    );
  }

  void _showUserInfoModal(AuthProvider authProvider) async {
    // Siempre mostrar el modal directamente usando la información del AuthProvider
    if (authProvider.currentUser != null) {
      debugPrint('💡 UserInfoWidget: Mostrando modal con usuario: ${authProvider.currentUser!.name} ${authProvider.currentUser!.lastName}');
      _showUserModal(authProvider.currentUser!);
      return;
    }

    // Si no hay información en el provider, la cargamos desde el servidor
    debugPrint('⏳ UserInfoWidget: Usuario no disponible, cargando desde servidor...');
    setState(() => _isLoading = true);
    
    try {
      // Mostrar modal de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.surfaceGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Cargando información...',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Forzar refresh del AuthProvider para obtener información actualizada
      debugPrint('🔄 UserInfoWidget: Refrescando información del usuario...');
      
      // Verificar que hay token antes de intentar refrescar
      if (authProvider.accessToken == null) {
        if (mounted) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
        debugPrint('❌ UserInfoWidget: No hay token, usuario no autenticado');
        return;
      }
      
      await authProvider.refreshCurrentUser();
      
      // Cerrar modal de carga
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);

        // Mostrar modal con la información del usuario actualizada
        if (authProvider.currentUser != null) {
          debugPrint('✅ UserInfoWidget: Usuario cargado exitosamente, mostrando modal');
          _showUserModal(authProvider.currentUser!);
        } else {
          debugPrint('❌ UserInfoWidget: No se pudo cargar la información del usuario');
          _showErrorDialog('No se pudo cargar la información del usuario');
        }
      }

    } catch (e) {
      debugPrint('❌ UserInfoWidget: Error al cargar información: $e');
      setState(() => _isLoading = false);
      
      // Cerrar modal de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar error de forma más elegante
        _showErrorDialog('Error al cargar información del usuario: $e');
      }
    }
  }

  void _showUserModal(UserModel currentUser) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Usar siempre la información más actualizada del AuthProvider
            final userToShow = authProvider.currentUser ?? currentUser;
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 380,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: _buildUserInfoContent(userToShow),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserInfoContent(UserModel currentUser) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header del modal con botón cerrar y refresh
          Row(
            children: [
              Expanded(
                child: Text(
                  'Información del Usuario',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Botón refresh
              IconButton(
                onPressed: () => _refreshUserInfoInModal(context),
                icon: const Icon(
                  Icons.refresh,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                tooltip: 'Actualizar información',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              const SizedBox(width: 4),
              // Botón cerrar
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Avatar del usuario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nombre completo
          Text(
            '${currentUser.name} ${currentUser.lastName}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          
          // Username
          Text(
            '@${currentUser.username}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _getRoleGradient(currentUser.role),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentUser.role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Información de contacto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Email
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            currentUser.email,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (currentUser.phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.secondaryGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Teléfono',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              currentUser.phone,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botón Cerrar Sesión - Solo icono
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    debugPrint('🚪 Botón logout presionado');
                    // NO cerrar el modal aquí, dejarlo abierto para mostrar el diálogo de confirmación
                    _showLogoutConfirmation();
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Cerrar Sesión',
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LinearGradient _getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'user':
        return AppTheme.secondaryGradient;
      case 'moderator':
        return AppTheme.accentGradient;
      default:
        return AppTheme.primaryGradient;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.error),
              SizedBox(width: 12),
              Text('Error'),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            GradientButton(
              text: 'Entendido',
              onPressed: () => Navigator.of(context).pop(),
              gradient: AppTheme.primaryGradient,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshUserInfoInModal(BuildContext modalContext) async {
    try {
      // Usar directamente el AuthProvider para refrescar la información
      // El modal se actualizará automáticamente gracias al Consumer
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshCurrentUser();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Información actualizada desde el servidor'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error al actualizar: $e'),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppTheme.error),
              SizedBox(width: 12),
              Text('Cerrar Sesión'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                // 1. Cerrar el diálogo de confirmación
                Navigator.of(dialogContext).pop();
                
                // 2. Cerrar el modal de información
                Navigator.of(context).pop();
                
                // 3. Pequeño delay para que se cierren las animaciones
                await Future.delayed(const Duration(milliseconds: 150));
                
                // 4. Ejecutar logout
                widget.onLogout();
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
# 🌟 UserInfoWidget - Documentación

## 📋 Descripción
El `UserInfoWidget` es un componente moderno que muestra la información del usuario autenticado en un modal elegante con funcionalidad de cerrar sesión.

## ✨ Características

### 🎯 Funcionalidades Principales
- **Modal de información de usuario** con diseño moderno
- **Cache inteligente** - carga datos solo una vez
- **Estados de carga** visual en el botón
- **Manejo de errores** elegante
- **Confirmación de logout** para evitar cierres accidentales

### 🎨 Elementos Visuales
- **Avatar circular** con gradiente
- **Badge de rol** con colores específicos por tipo de usuario
- **Información de contacto** organizadas en tarjetas
- **Botones con gradientes** coherentes con el tema de la app

## 🔧 Uso

```dart
UserInfoWidget(
  accessToken: accessToken,
  onLogout: () {
    Provider.of<AuthProvider>(context, listen: false).logout();
  },
)
```

## 📱 Flujo de Usuario

1. **Usuario hace clic** en el botón del perfil (icono en AppBar)
2. **Primera vez**: 
   - Muestra indicador de carga en el botón
   - Aparece modal de carga
   - Obtiene datos del servidor
   - Muestra modal con información completa
3. **Siguientes veces**: 
   - Muestra directamente el modal (datos cacheados)
4. **Acciones disponibles**:
   - Ver información completa del usuario
   - Cerrar modal con botón "Cerrar" o "X"
   - Cerrar sesión con confirmación

## 🛠️ Estados del Widget

### Loading States
- **Botón**: Muestra CircularProgressIndicator cuando está cargando
- **Modal de carga**: Dialog elegante mientras obtiene datos
- **Botón deshabilitado**: Previene múltiples llamadas simultáneas

### Error Handling
- **Dialog de error**: Muestra errores de forma elegante
- **Fallback graceful**: No rompe la aplicación si falla la carga

## 🎨 Personalización por Rol

### Admin
- Badge morado (`#8B5CF6` → `#7C3AED`)

### User
- Badge con `AppTheme.secondaryGradient`

### Moderator  
- Badge con `AppTheme.accentGradient`

### Default
- Badge con `AppTheme.primaryGradient`

## 📋 Dependencias

- `UserService` - Para obtener datos del usuario
- `UserModel` - Modelo de datos del usuario
- `AppTheme` - Tema y colores de la aplicación
- `GradientButton` - Botón personalizado con gradiente

## 🔒 Seguridad

- Usa `accessToken` para autenticación
- Valida `mounted` antes de operaciones async
- Maneja errores de red de forma segura

## 💡 Mejoras Implementadas

1. **UX mejorado**: Modal centrado en lugar de overlay
2. **Feedback visual**: Estados de carga claros
3. **Error handling**: Diálogos elegantes en lugar de SnackBars
4. **Prevención de errores**: Botón deshabilitado durante carga
5. **Cache inteligente**: Evita recargas innecesarias
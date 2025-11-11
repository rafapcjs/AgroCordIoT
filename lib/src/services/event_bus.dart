import 'dart:async';
import '../data/models/user_model.dart';

// Eventos que pueden ocurrir en la aplicación
abstract class AppEvent {}

// Evento cuando un usuario es actualizado
class UserUpdatedEvent extends AppEvent {
  final UserModel updatedUser;
  
  UserUpdatedEvent(this.updatedUser);
}

// Evento cuando un usuario es eliminado
class UserDeletedEvent extends AppEvent {
  final String userId;
  
  UserDeletedEvent(this.userId);
}

// EventBus singleton para manejar eventos globales
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  // Stream controller para manejar los eventos
  final StreamController<AppEvent> _eventController = StreamController<AppEvent>.broadcast();

  // Stream para escuchar eventos
  Stream<AppEvent> get events => _eventController.stream;

  // Método para enviar eventos
  void emit(AppEvent event) {
    _eventController.add(event);
  }

  // Método para escuchar eventos específicos
  Stream<T> on<T extends AppEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  // Limpiar recursos
  void dispose() {
    _eventController.close();
  }
}
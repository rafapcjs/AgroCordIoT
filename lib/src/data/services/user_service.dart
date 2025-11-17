import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../../core/constants.dart';
import '../../services/event_bus.dart';

class UserService {
  Future<List<UserModel>> getAllUsers(String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/users');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<UserModel> getUserById(String id, String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/users/$id');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<UserModel> createUser(CreateUserModel user, String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/users');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 201) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<UserModel> updateUser(String id, UserModel user, String accessToken) async {
    if (id.isEmpty) {
      throw Exception('User ID cannot be empty');
    }
    
    final url = Uri.parse('${Constants.baseUrl}/api/users/$id');
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final updatedUser = UserModel.fromJson(json.decode(response.body));
      
      // Emitir evento de actualización de usuario
      EventBus().emit(UserUpdatedEvent(updatedUser));
      
      return updatedUser;
    } else {
      throw Exception('Failed to update user: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteUser(String id, String accessToken) async {
    if (id.isEmpty) {
      throw Exception('User ID cannot be empty');
    }
    
    final url = Uri.parse('${Constants.baseUrl}/api/users/$id');
    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Emitir evento de eliminación de usuario
      EventBus().emit(UserDeletedEvent(id));
    } else {
      throw Exception('Failed to delete user: ${response.statusCode} - ${response.body}');
    }
  }

  Future<UserModel> getAuthenticatedUser(String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/auth/me');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load authenticated user: ${response.statusCode} - ${response.body}');
    }
  }
}
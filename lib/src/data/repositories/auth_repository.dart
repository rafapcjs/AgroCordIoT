import '../network_service.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final NetworkService networkService;

  AuthRepository({required this.networkService});

  Future<AuthModel> authenticate(String username, String password) {
    return networkService.login(username, password);
  }
}

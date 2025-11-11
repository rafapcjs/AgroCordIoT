import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_model.dart';

class AuthUseCase {
  final AuthRepository authRepository;

  AuthUseCase({required this.authRepository});

  Future<AuthModel> authenticate(String username, String password) {
    return authRepository.authenticate(username, password);
  }
}

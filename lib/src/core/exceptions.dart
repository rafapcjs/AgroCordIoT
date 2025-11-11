abstract class AppException implements Exception {
  final String message;
  final String? details;
  final int? statusCode;

  const AppException(this.message, {this.details, this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.details, super.statusCode});
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.details, super.statusCode});
}

class AuthorizationException extends AppException {
  const AuthorizationException(super.message, {super.details, super.statusCode});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.details});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.details, super.statusCode});
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.details});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.details});
}
class AuthModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  AuthModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['accessToken'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'] ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
    };
  }
}
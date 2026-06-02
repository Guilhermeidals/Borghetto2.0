class AuthSession {
  final String token;
  final int userId;
  final String name;
  final String? cpf;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? accessStatus;
  final int? controlIdUserId;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    this.cpf,
    this.phone,
    this.email,
    this.photoUrl,
    this.accessStatus,
    this.controlIdUserId,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;

    return AuthSession(
      token: json['token']?.toString() ?? '',
      userId: int.tryParse(user['id']?.toString() ?? '') ?? 0,
      name: user['name']?.toString() ?? '',
      cpf: user['cpf']?.toString(),
      phone: user['phone']?.toString(),
      email: user['email']?.toString(),
      photoUrl: user['photoUrl']?.toString() ?? user['photo_path']?.toString(),
      accessStatus: user['accessStatus']?.toString() ?? user['access_status']?.toString(),
      controlIdUserId: int.tryParse(
        user['controlIdUserId']?.toString() ??
            user['control_id_user_id']?.toString() ??
            user['control_id']?.toString() ??
            user['facialUserId']?.toString() ??
            user['facial_user_id']?.toString() ??
            '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': {
        'id': userId,
        'name': name,
        'cpf': cpf,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
        'accessStatus': accessStatus,
        'controlIdUserId': controlIdUserId,
      }
    };
  }
}
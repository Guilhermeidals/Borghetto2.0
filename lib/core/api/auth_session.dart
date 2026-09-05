class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    this.email,
    this.cpf,
    this.phone,
    this.birthDate,
    this.role,
    this.active,
    this.controlIdUserId,
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.photoUrl,
    this.accessStatus,
    this.approved = false,
    this.approvalStatus = 'pending',
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  final String token;
  final int userId;
  final String name;

  final String? email;
  final String? cpf;
  final String? phone;
  final String? birthDate;
  final String? role;
  final bool? active;

  final int? controlIdUserId;

  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;

  final String? photoUrl;
  final String? accessStatus;

  final bool approved;
  final String approvalStatus;
  final String? reviewedAt;
  final int? reviewedBy;
  final String? reviewNote;

  bool get isAdmin => role == 'admin';

  bool get isApproved =>
      approved == true && approvalStatus.toLowerCase() == 'approved';

  bool get isPendingApproval =>
      approved == false && approvalStatus.toLowerCase() == 'pending';

  bool get isRejected =>
      approved == false && approvalStatus.toLowerCase() == 'rejected';

  bool get isBlocked =>
      approved == false && approvalStatus.toLowerCase() == 'blocked';

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];

    final Map<String, dynamic> user =
        userRaw is Map<String, dynamic> ? userRaw : json;

    return AuthSession(
      token: json['token']?.toString() ?? '',
      userId: _parseInt(user['id'] ?? user['userId'] ?? user['user_id']),
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString(),
      cpf: user['cpf']?.toString(),
      phone: user['phone']?.toString(),
      birthDate: (user['birthDate'] ?? user['birth_date'])?.toString(),
      role: user['role']?.toString(),
      active: _parseBool(user['active']),
      controlIdUserId: _parseNullableInt(
        user['controlIdUserId'] ?? user['control_id_user_id'],
      ),
      zipCode: (user['zipCode'] ?? user['zip_code'])?.toString(),
      street: user['street']?.toString(),
      number: user['number']?.toString(),
      complement: user['complement']?.toString(),
      neighborhood: user['neighborhood']?.toString(),
      city: user['city']?.toString(),
      state: user['state']?.toString(),
      photoUrl: (user['photoUrl'] ?? user['photo_url'])?.toString(),
      accessStatus: (user['accessStatus'] ?? user['access_status'])?.toString(),
      approved: _parseBool(user['approved']) ?? false,
      approvalStatus:
          (user['approvalStatus'] ?? user['approval_status'])?.toString() ??
              'pending',
      reviewedAt: (user['reviewedAt'] ?? user['reviewed_at'])?.toString(),
      reviewedBy: _parseNullableInt(
        user['reviewedBy'] ?? user['reviewed_by'],
      ),
      reviewNote: (user['reviewNote'] ?? user['review_note'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': {
        'id': userId,
        'name': name,
        'email': email,
        'cpf': cpf,
        'phone': phone,
        'birth_date': birthDate,
        'birthDate': birthDate,
        'role': role,
        'active': active,
        'control_id_user_id': controlIdUserId,
        'controlIdUserId': controlIdUserId,
        'zip_code': zipCode,
        'zipCode': zipCode,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'photoUrl': photoUrl,
        'photo_url': photoUrl,
        'accessStatus': accessStatus,
        'access_status': accessStatus,
        'approved': approved,
        'approval_status': approvalStatus,
        'approvalStatus': approvalStatus,
        'reviewed_at': reviewedAt,
        'reviewedAt': reviewedAt,
        'reviewed_by': reviewedBy,
        'reviewedBy': reviewedBy,
        'review_note': reviewNote,
        'reviewNote': reviewNote,
      },
    };
  }

  AuthSession copyWith({
    String? token,
    int? userId,
    String? name,
    String? email,
    String? cpf,
    String? phone,
    String? birthDate,
    String? role,
    bool? active,
    int? controlIdUserId,
    String? zipCode,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? photoUrl,
    String? accessStatus,
    bool? approved,
    String? approvalStatus,
    String? reviewedAt,
    int? reviewedBy,
    String? reviewNote,
  }) {
    return AuthSession(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      active: active ?? this.active,
      controlIdUserId: controlIdUserId ?? this.controlIdUserId,
      zipCode: zipCode ?? this.zipCode,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      photoUrl: photoUrl ?? this.photoUrl,
      accessStatus: accessStatus ?? this.accessStatus,
      approved: approved ?? this.approved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();

      if (normalized == 'true' || normalized == 't' || normalized == '1') {
        return true;
      }

      if (normalized == 'false' || normalized == 'f' || normalized == '0') {
        return false;
      }
    }

    if (value is int) {
      if (value == 1) {
        return true;
      }

      if (value == 0) {
        return false;
      }
    }

    return null;
  }
}

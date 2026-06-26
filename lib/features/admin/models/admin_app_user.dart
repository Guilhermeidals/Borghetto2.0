class AdminAppUser {
  const AdminAppUser({
    required this.id,
    required this.name,
    required this.email,
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
    required this.approved,
    required this.approvalStatus,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  final int id;
  final String name;
  final String email;

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

  final bool approved;
  final String approvalStatus;
  final String? reviewedAt;
  final int? reviewedBy;
  final String? reviewNote;

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approved && approvalStatus == 'approved';
  bool get isBlocked => !approved && approvalStatus == 'blocked';
  bool get isRejected => !approved && approvalStatus == 'rejected';

  factory AdminAppUser.fromJson(Map<String, dynamic> json) {
    return AdminAppUser(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cpf: json['cpf']?.toString(),
      phone: json['phone']?.toString(),
      birthDate: (json['birthDate'] ?? json['birth_date'])?.toString(),
      role: json['role']?.toString(),
      active: _parseBool(json['active']),
      controlIdUserId: _parseNullableInt(
        json['controlIdUserId'] ?? json['control_id_user_id'],
      ),
      zipCode: json['zipCode']?.toString(),
      street: json['street']?.toString(),
      number: json['number']?.toString(),
      complement: json['complement']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      approved: _parseBool(json['approved']) ?? false,
      approvalStatus:
          (json['approvalStatus'] ?? json['approval_status'])?.toString() ??
              'pending',
      reviewedAt: (json['reviewedAt'] ?? json['reviewed_at'])?.toString(),
      reviewedBy: _parseNullableInt(json['reviewedBy'] ?? json['reviewed_by']),
      reviewNote: (json['reviewNote'] ?? json['review_note'])?.toString(),
    );
  }

  AdminAppUser copyWith({
    int? id,
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
    bool? approved,
    String? approvalStatus,
    String? reviewedAt,
    int? reviewedBy,
    String? reviewNote,
  }) {
    return AdminAppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      active: active ?? this.active,
      controlIdUserId: controlIdUserId ?? this.controlIdUserId,
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
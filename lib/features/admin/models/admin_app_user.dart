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
    this.photoUrl,
    this.dependents = const [],
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
  final String? photoUrl;
  final List<AdminAppUserDependentSummary> dependents;

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approved && approvalStatus == 'approved';
  bool get isBlocked => !approved && approvalStatus == 'blocked';
  bool get isRejected => !approved && approvalStatus == 'rejected';

  factory AdminAppUser.fromJson(Map<String, dynamic> json) {
    return AdminAppUser(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cpf: json['cpf']?.toString(),
      phone: json['phone']?.toString(),
      birthDate: (json['birthDate'] ?? json['birth_date'])?.toString(),
      role: json['role']?.toString(),
      active: parseBool(json['active']),
      controlIdUserId: parseNullableInt(
        json['controlIdUserId'] ?? json['control_id_user_id'],
      ),
      zipCode: json['zipCode']?.toString(),
      street: json['street']?.toString(),
      number: json['number']?.toString(),
      complement: json['complement']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      approved: parseBool(json['approved']) ?? false,
      approvalStatus:
          (json['approvalStatus'] ?? json['approval_status'])?.toString() ??
              'pending',
      reviewedAt: (json['reviewedAt'] ?? json['reviewed_at'])?.toString(),
      reviewedBy: parseNullableInt(json['reviewedBy'] ?? json['reviewed_by']),
      reviewNote: (json['reviewNote'] ?? json['review_note'])?.toString(),
      photoUrl: (json['photoUrl'] ?? json['photo_url'])?.toString(),
      dependents: ((json['dependents'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdminAppUserDependentSummary.fromJson)
        .toList(),
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
  String? photoUrl,
  List<AdminAppUserDependentSummary>? dependents,
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
    zipCode: zipCode ?? this.zipCode,
    street: street ?? this.street,
    number: number ?? this.number,
    complement: complement ?? this.complement,
    neighborhood: neighborhood ?? this.neighborhood,
    city: city ?? this.city,
    state: state ?? this.state,
    approved: approved ?? this.approved,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    reviewedBy: reviewedBy ?? this.reviewedBy,
    reviewNote: reviewNote ?? this.reviewNote,
    photoUrl: photoUrl ?? this.photoUrl,
    dependents: dependents ?? this.dependents,
  );
}

  static int parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int? parseNullableInt(dynamic value) {
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

  static bool? parseBool(dynamic value) {
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

class AdminAppUserDependentSummary {
  const AdminAppUserDependentSummary({
    required this.id,
    required this.name,
    this.relationship,
    this.active,
    this.controlIdUserId,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String? relationship;
  final bool? active;
  final int? controlIdUserId;
  final String? photoUrl;

  factory AdminAppUserDependentSummary.fromJson(Map<String, dynamic> json) {
    return AdminAppUserDependentSummary(
      id: AdminAppUser.parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString(),
      active: AdminAppUser.parseBool(json['active']),
      controlIdUserId: AdminAppUser.parseNullableInt(
        json['controlIdUserId'] ?? json['control_id_user_id'],
      ),
      photoUrl: (json['photoUrl'] ?? json['photo_url'])?.toString(),
    );
  }
}
import 'admin_app_user.dart';

class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.dependents,
  });

  final AdminAppUser user;
  final List<AdminUserDependent> dependents;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final rawDependents = json['dependents'];

    return AdminUserDetail(
      user: AdminAppUser.fromJson(
        rawUser is Map<String, dynamic> ? rawUser : <String, dynamic>{},
      ),
      dependents: rawDependents is List
          ? rawDependents
              .whereType<Map<String, dynamic>>()
              .map(AdminUserDependent.fromJson)
              .toList()
          : <AdminUserDependent>[],
    );
  }
}

class AdminUserDependent {
  const AdminUserDependent({
    required this.id,
    required this.appUserId,
    required this.name,
    this.cpf,
    this.birthDate,
    this.relationship,
    this.active,
    this.controlIdUserId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int appUserId;
  final String name;
  final String? cpf;
  final String? birthDate;
  final String? relationship;
  final bool? active;
  final int? controlIdUserId;
  final String? createdAt;
  final String? updatedAt;

  bool get hasControlId {
    final value = controlIdUserId;
    return value != null && value > 0;
  }

  factory AdminUserDependent.fromJson(Map<String, dynamic> json) {
    return AdminUserDependent(
      id: _parseInt(json['id']),
      appUserId: _parseInt(
        json['app_user_id'] ?? json['appUserId'],
      ),
      name: json['name']?.toString() ?? '',
      cpf: json['cpf']?.toString(),
      birthDate: (json['birth_date'] ?? json['birthDate'])?.toString(),
      relationship: json['relationship']?.toString(),
      active: _parseBool(json['active']),
      controlIdUserId: _parseNullableInt(
        json['control_id_user_id'] ?? json['controlIdUserId'],
      ),
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'])?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    final text = value.toString().toLowerCase().trim();

    if (text == 'true' || text == '1') {
      return true;
    }

    if (text == 'false' || text == '0') {
      return false;
    }

    return null;
  }
}

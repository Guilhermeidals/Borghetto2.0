class AppDependent {
  const AppDependent({
    required this.id,
    required this.name,
    required this.cpf,
    required this.birthDate,
    required this.relationship,
    required this.faceRegistered,
    required this.active,
    this.controlIdUserId,
  });

  final int id;
  final String name;
  final String cpf;

  /// Formato visual no app: DD/MM/AAAA
  final String birthDate;

  /// Valores internos:
  /// spouse, child, father, mother, other
  final String relationship;

  final bool active;
  final int? controlIdUserId;
  final bool faceRegistered;

  AppDependent copyWith({
    int? id,
    String? name,
    String? cpf,
    String? birthDate,
    String? relationship,
    bool? active,
    int? controlIdUserId,
    bool? faceRegistered,
  }) {
    return AppDependent(
      id: id ?? this.id,
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      relationship: relationship ?? this.relationship,
      active: active ?? this.active,
      controlIdUserId: controlIdUserId ?? this.controlIdUserId,
      faceRegistered: faceRegistered ?? this.faceRegistered,
    );
  }

  factory AppDependent.fromJson(Map<String, dynamic> json) {
    return AppDependent(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      birthDate: _formatBirthDate(json['birth_date'] ?? json['birthDate']),
      relationship: json['relationship']?.toString() ?? 'other',
      active: json['active'] == true,
      controlIdUserId: json['control_id_user_id'] == null
          ? null
          : int.tryParse(json['control_id_user_id'].toString()),
      faceRegistered:
          json['face_registered'] == true || json['faceRegistered'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      'birth_date': birthDate,
      'relationship': relationship,
      'active': active,
      'control_id_user_id': controlIdUserId,
      'face_registered': faceRegistered,
    };
  }

  String get relationshipLabel {
    switch (relationship) {
      case 'spouse':
        return 'Cônjuge';
      case 'child':
        return 'Filho(a)';
      case 'father':
        return 'Pai';
      case 'mother':
        return 'Mãe';
      case 'other':
      default:
        return 'Outro';
    }
  }

  String get formattedCpf {
    final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');

    if (cleanCpf.length != 11) {
      return cpf;
    }

    return '${cleanCpf.substring(0, 3)}.'
        '${cleanCpf.substring(3, 6)}.'
        '${cleanCpf.substring(6, 9)}-'
        '${cleanCpf.substring(9, 11)}';
  }
}

String _formatBirthDate(dynamic value) {
  if (value == null) {
    return '';
  }

  final text = value.toString().trim();

  if (text.isEmpty) {
    return '';
  }

  // Já está em PT-BR: DD/MM/AAAA
  if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
    return text;
  }

  // ISO completo vindo do backend: 1998-01-19T00:00:00.000Z
  final isoDate = DateTime.tryParse(text);

  if (isoDate != null) {
    final day = isoDate.day.toString().padLeft(2, '0');
    final month = isoDate.month.toString().padLeft(2, '0');
    final year = isoDate.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }

  // Data simples do banco: YYYY-MM-DD
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    final parts = text.split('-');

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  return text;
}

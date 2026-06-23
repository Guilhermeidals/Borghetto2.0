import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_dependent.dart';

class DependentFormSheet extends StatefulWidget {
  const DependentFormSheet({
    super.key,
    this.dependent,
  });

  final AppDependent? dependent;

  @override
  State<DependentFormSheet> createState() => _DependentFormSheetState();
}

class _DependentFormSheetState extends State<DependentFormSheet> {
  final _formKey = GlobalKey<FormState>();

  File? _selectedFaceImage;

  late final TextEditingController _nameController;
  late final TextEditingController _cpfController;
  late final TextEditingController _birthDateController;

  String _relationship = 'child';
  bool _active = true;
  bool get _isEditing => widget.dependent != null;

  @override
  void initState() {
    super.initState();

    final dependent = widget.dependent;

    _nameController = TextEditingController(text: dependent?.name ?? '');
    _cpfController = TextEditingController(text: dependent?.formattedCpf ?? '');
    _birthDateController = TextEditingController(
      text: dependent?.birthDate ?? '',
    );

    _relationship = dependent?.relationship ?? 'child';
    _active = dependent?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dependent = AppDependent(
      id: widget.dependent?.id ?? 0,
      name: _nameController.text.trim(),
      cpf: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
      birthDate: _birthDateController.text.trim(),
      relationship: _relationship,
      active: _active,
      faceRegistered: widget.dependent?.faceRegistered ?? false,
      controlIdUserId: widget.dependent?.controlIdUserId,
    );

    Navigator.of(context).pop(
      DependentFormResult(
        dependent: dependent,
        faceImage: _selectedFaceImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar familiar' : 'Adicionar familiar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Informe o nome completo';
                    }

                    if (text.length < 5) {
                      return 'Nome muito curto';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CpfInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    prefixIcon: Icon(Icons.badge_rounded),
                    hintText: '000.000.000-00',
                  ),
                  validator: (value) {
                    final cpf = value?.replaceAll(RegExp(r'\D'), '') ?? '';

                    if (cpf.isEmpty) {
                      return 'Informe o CPF';
                    }

                    if (!_isValidCpf(cpf)) {
                      return 'CPF inválido';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _birthDateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _BirthDateInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Data de nascimento',
                    prefixIcon: Icon(Icons.cake_rounded),
                    hintText: 'DD/MM/AAAA',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Informe a data de nascimento';
                    }

                    if (!_isValidBrazilianDate(text)) {
                      return 'Data inválida';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _relationship,
                  decoration: const InputDecoration(
                    labelText: 'Parentesco',
                    prefixIcon: Icon(Icons.family_restroom_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'spouse',
                      child: Text('Cônjuge'),
                    ),
                    DropdownMenuItem(
                      value: 'child',
                      child: Text('Filho(a)'),
                    ),
                    DropdownMenuItem(
                      value: 'father',
                      child: Text('Pai'),
                    ),
                    DropdownMenuItem(
                      value: 'mother',
                      child: Text('Mãe'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Outro'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _relationship = value;
                    });
                  },
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _active,
                    title: const Text('Familiar ativo'),
                    subtitle: Text(
                      _active
                          ? 'Pode continuar usando o acesso'
                          : 'Familiar desativado',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _active = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  _DependentFacePickerCard(
                    selectedImage: _selectedFaceImage,
                    hasControlId: widget.dependent?.controlIdUserId != null,
                    onPickImage: _pickFaceImage,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_isEditing ? 'Salvar alterações' : 'Adicionar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFaceImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) return;

    setState(() {
      _selectedFaceImage = File(image.path);
    });
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      }

      if (i == 9) {
        buffer.write('-');
      }

      buffer.write(digits[i]);
    }

    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _BirthDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }

      buffer.write(digits[i]);
    }

    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

bool _isValidBrazilianDate(String value) {
  final regex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

  final match = regex.firstMatch(value);

  if (match == null) {
    return false;
  }

  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);

  if (day == null || month == null || year == null) {
    return false;
  }

  if (year < 1900 || year > DateTime.now().year) {
    return false;
  }

  if (month < 1 || month > 12) {
    return false;
  }

  final date = DateTime(year, month, day);

  return date.day == day && date.month == month && date.year == year;
}

bool _isValidCpf(String cpf) {
  final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');

  if (cleanCpf.length != 11) {
    return false;
  }

  if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) {
    return false;
  }

  var sum = 0;

  for (var i = 0; i < 9; i++) {
    sum += int.parse(cleanCpf[i]) * (10 - i);
  }

  var firstDigit = 11 - (sum % 11);

  if (firstDigit >= 10) {
    firstDigit = 0;
  }

  if (firstDigit != int.parse(cleanCpf[9])) {
    return false;
  }

  sum = 0;

  for (var i = 0; i < 10; i++) {
    sum += int.parse(cleanCpf[i]) * (11 - i);
  }

  var secondDigit = 11 - (sum % 11);

  if (secondDigit >= 10) {
    secondDigit = 0;
  }

  return secondDigit == int.parse(cleanCpf[10]);
}

class DependentFormResult {
  const DependentFormResult({
    required this.dependent,
    this.faceImage,
  });

  final AppDependent dependent;
  final File? faceImage;
}

class _DependentFacePickerCard extends StatelessWidget {
  const _DependentFacePickerCard({
    required this.selectedImage,
    required this.hasControlId,
    required this.onPickImage,
  });

  final File? selectedImage;
  final bool hasControlId;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage:
                selectedImage == null ? null : FileImage(selectedImage!),
            child: selectedImage == null
                ? Icon(
                    Icons.face_rounded,
                    color: colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedImage == null
                      ? 'Foto facial'
                      : 'Foto selecionada',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasControlId
                      ? 'A foto será enviada ao Control iD ao salvar.'
                      : 'Este familiar ainda não possui acesso, pois não tem foto.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.add_a_photo_rounded),
            label: const Text('Foto'),
          ),
        ],
      ),
    );
  }
}
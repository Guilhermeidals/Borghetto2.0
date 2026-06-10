import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_session.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _profilePhoto;
  final ImagePicker _picker = ImagePicker();

  AuthSession? _session;

  bool _isLoadingSession = true;
  bool _isUploadingPhoto = false;
  bool _isSavingProfile = false;

  int _photoVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    AuthSession? savedSession;

    try {
      savedSession = await ApiClient.instance.getSavedSession();

      if (mounted && savedSession != null) {
        setState(() {
          _session = savedSession;
        });
      }

      final freshSession = await ApiClient.instance.me();

      if (!mounted) return;

      setState(() {
        _session = freshSession;
        _isLoadingSession = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _session = savedSession;
        _isLoadingSession = false;
      });

      if (savedSession == null) {
        _showSnackBar(
          'Não foi possível carregar os dados do perfil.',
          isError: true,
        );
      }
    }
  }

  String get _displayName {
    final name = _session?.name.trim();

    if (name == null || name.isEmpty) {
      return 'Cliente Borghetto';
    }

    return name;
  }

  String get _displayEmail {
    final email = _session?.email?.trim();

    if (email == null || email.isEmpty) {
      return 'E-mail não informado';
    }

    return email;
  }

  String get _displayCpf {
    final cpf = _session?.cpf?.trim();

    if (cpf == null || cpf.isEmpty) {
      return 'CPF não informado';
    }

    return cpf;
  }

  String get _displayPhone {
    final phone = _session?.phone?.trim();

    if (phone == null || phone.isEmpty) {
      return 'Telefone não informado';
    }

    return phone;
  }

  String get _displayBirthDate {
    final birthDate = _session?.birthDate?.trim();

    if (birthDate == null || birthDate.isEmpty) {
      return 'Data de nascimento não informada';
    }

    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(birthDate)) {
      final parts = birthDate.substring(0, 10).split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return birthDate;
  }

  String get _displayZipCode {
    final zipCode = _session?.zipCode?.trim();

    if (zipCode == null || zipCode.isEmpty) {
      return 'CEP não informado';
    }

    final digits = _onlyDigits(zipCode);

    if (digits.length == 8) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }

    return zipCode;
  }

  String get _displayStreetNumber {
    final street = _session?.street?.trim();
    final number = _session?.number?.trim();

    if (street == null || street.isEmpty) {
      return 'Rua não informada';
    }

    if (number == null || number.isEmpty) {
      return street;
    }

    return '$street, $number';
  }

  String get _displayComplement {
    final complement = _session?.complement?.trim();

    if (complement == null || complement.isEmpty) {
      return 'Complemento não informado';
    }

    return complement;
  }

  String get _displayNeighborhood {
    final neighborhood = _session?.neighborhood?.trim();

    if (neighborhood == null || neighborhood.isEmpty) {
      return 'Bairro não informado';
    }

    return neighborhood;
  }

  String get _displayCityState {
    final city = _session?.city?.trim();
    final state = _session?.state?.trim();

    if (city != null && city.isNotEmpty && state != null && state.isNotEmpty) {
      return '$city/$state';
    }

    if (city != null && city.isNotEmpty) {
      return city;
    }

    if (state != null && state.isNotEmpty) {
      return state;
    }

    return 'Cidade/UF não informadas';
  }

  String get _initials {
    final parts = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'CB';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatPhone(String value) {
    final digits = _onlyDigits(value);

    if (digits.isEmpty) {
      return '';
    }

    if (digits.length <= 2) {
      return '(${digits}';
    }

    final ddd = digits.substring(0, 2);
    final number = digits.substring(2);

    if (number.length <= 4) {
      return '($ddd) $number';
    }

    if (digits.length <= 10) {
      final firstPart = number.substring(0, number.length - 4);
      final lastPart = number.substring(number.length - 4);
      return '($ddd) $firstPart-$lastPart';
    }

    final firstPart = number.substring(0, 5);
    final lastPart = number.substring(5, 9);
    return '($ddd) $firstPart-$lastPart';
  }

  String? get _serverPhotoUrl {
    final facialUserId = _session?.controlIdUserId;

    if (facialUserId == null || facialUserId <= 0) {
      return null;
    }

    final url = ApiClient.instance.resolveFileUrl(
      '/facial/users/$facialUserId/face?v=$_photoVersion',
    );

    if (url.isEmpty) {
      return null;
    }

    return url;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError
            ? AppTheme.error
            : const Color(0xFF2E7D52),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foto do perfil',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A foto será usada para reconhecimento facial',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 20),
              _buildPhotoOption(
                icon: Icons.camera_alt_outlined,
                label: 'Tirar foto',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.photo_library_outlined,
                label: 'Escolher da galeria',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profilePhoto != null) ...[
                const SizedBox(height: 12),
                _buildPhotoOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remover foto',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _profilePhoto = null;
                    });
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppTheme.darkText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 92,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _profilePhoto = image;
      });

      await _uploadProfilePhoto(image);
    } catch (_) {
      _showSnackBar(
        'Não foi possível acessar a ${source == ImageSource.camera ? 'câmera' : 'galeria'}. Verifique as permissões.',
        isError: true,
      );
    }
  }

  Future<void> _uploadProfilePhoto(XFile image) async {
  final session = _session;

  if (session == null || session.userId <= 0) {
    _showSnackBar(
      'Sessão não encontrada. Faça login novamente.',
      isError: true,
    );
    return;
  }

  final facialUserId = session.controlIdUserId;

  if (facialUserId == null || facialUserId <= 0) {
    _showSnackBar(
      'Usuário ainda não possui ID facial vinculado.',
      isError: true,
    );
    return;
  }

  if (kIsWeb) {
    _showSnackBar(
      'Envio de foto pela Web ainda não está habilitado.',
      isError: true,
    );
    return;
  }

  setState(() {
    _isUploadingPhoto = true;
  });

  try {
    final preparedImage = await _prepareImageForUpload(image);

    final updatedSession = await ApiClient.instance.uploadSelfie(
      facialUserId: facialUserId,
      imageFile: preparedImage,
    );

    if (!mounted) return;

    setState(() {
      _session = updatedSession;
      _profilePhoto = null;
      _photoVersion = DateTime.now().millisecondsSinceEpoch;
    });

    _showSnackBar('Foto enviada com sucesso.');
  } on ApiException catch (e) {
    _showSnackBar(e.message, isError: true);
  } catch (_) {
    _showSnackBar(
      'Erro inesperado ao enviar a foto.',
      isError: true,
    );
  } finally {
    if (mounted) {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }
}

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja realmente sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await ApiClient.instance.logout();

    if (!mounted) return;

    context.go(AppRoutes.signUpLoginScreen);
  }

  Future<void> _showEditProfileDialog() async {
    final session = _session;

    if (session == null) {
      _showSnackBar(
        'Sessão não encontrada. Faça login novamente.',
        isError: true,
      );
      return;
    }

    final phoneController = TextEditingController(
      text: _formatPhone(session.phone ?? ''),
    );
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                          _PhoneInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          final phone = _onlyDigits(value ?? '');

                          if (phone.isEmpty) {
                            return 'Informe seu telefone';
                          }

                          if (phone.length < 10 || phone.length > 11) {
                            return 'Informe um telefone válido';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Alterar senha',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Preencha os campos abaixo somente se quiser trocar sua senha.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Senha atual',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureCurrentPassword =
                                    !obscureCurrentPassword;
                              });
                            },
                            icon: Icon(
                              obscureCurrentPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final currentPassword = value ?? '';
                          final newPassword = newPasswordController.text;
                          final confirmPassword =
                              confirmPasswordController.text;

                          final wantsToChangePassword =
                              currentPassword.isNotEmpty ||
                                  newPassword.isNotEmpty ||
                                  confirmPassword.isNotEmpty;

                          if (!wantsToChangePassword) {
                            return null;
                          }

                          if (currentPassword.isEmpty) {
                            return 'Informe sua senha atual';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final currentPassword =
                              currentPasswordController.text;
                          final newPassword = value ?? '';
                          final confirmPassword =
                              confirmPasswordController.text;

                          final wantsToChangePassword =
                              currentPassword.isNotEmpty ||
                                  newPassword.isNotEmpty ||
                                  confirmPassword.isNotEmpty;

                          if (!wantsToChangePassword) {
                            return null;
                          }

                          if (newPassword.isEmpty) {
                            return 'Informe a nova senha';
                          }

                          if (newPassword.length < 6) {
                            return 'A nova senha precisa ter pelo menos 6 caracteres';
                          }

                          if (newPassword == currentPassword) {
                            return 'A nova senha precisa ser diferente da atual';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar nova senha',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final currentPassword =
                              currentPasswordController.text;
                          final newPassword = newPasswordController.text;
                          final confirmPassword = value ?? '';

                          final wantsToChangePassword =
                              currentPassword.isNotEmpty ||
                                  newPassword.isNotEmpty ||
                                  confirmPassword.isNotEmpty;

                          if (!wantsToChangePassword) {
                            return null;
                          }

                          if (confirmPassword.isEmpty) {
                            return 'Confirme a nova senha';
                          }

                          if (confirmPassword != newPassword) {
                            return 'As senhas não conferem';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSavingProfile
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSavingProfile
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            _isSavingProfile = true;
                          });

                          final newPassword =
                              newPasswordController.text.trim();

                          final success = await _saveProfileSecurity(
                            userId: session.userId,
                            phone: _onlyDigits(phoneController.text),
                            currentPassword: currentPasswordController.text,
                            newPassword:
                                newPassword.isEmpty ? null : newPassword,
                          );

                          if (!mounted) return;

                          setDialogState(() {
                            _isSavingProfile = false;
                          });

                          if (success &&
                              Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: _isSavingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  Future<bool> _saveProfileSecurity({
    required int userId,
    required String phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final updatedSession = await ApiClient.instance.updateProfileSecurity(
        userId: userId,
        phone: phone,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return false;

      setState(() {
        _session = updatedSession;
      });

      if (newPassword != null && newPassword.trim().isNotEmpty) {
        _showSnackBar('Telefone e/ou senha atualizados com sucesso.');
      } else {
        _showSnackBar('Telefone atualizado com sucesso.');
      }

      return true;
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
      return false;
    } catch (_) {
      _showSnackBar(
        'Erro inesperado ao atualizar perfil.',
        isError: true,
      );
      return false;
    }
  }

  Future<File> _prepareImageForUpload(XFile image) async {
    final originalFile = File(image.path);

    final targetPath =
        '${image.path}_fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final fixedImage = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      quality: 92,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: true,
      keepExif: false,
    );

    if (fixedImage == null) {
      return originalFile;
    }

    return File(fixedImage.path);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSession) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildMemberCard(context)),
            SliverToBoxAdapter(child: _buildStatsRow(context)),
            SliverToBoxAdapter(child: _buildProfileDataSection(context)),
            SliverToBoxAdapter(child: _buildMenuSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Perfil',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 18,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _isUploadingPhoto ? null : _showPhotoOptions,
              child: Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: _profilePhoto == null
                          ? const LinearGradient(
                              colors: [Color(0xFF4CAF7D), Color(0xFF2E7D52)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _profilePhoto != null ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: _buildAvatarContent(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUploadingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(4),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayEmail,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFFE8A020),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cliente Borghetto',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE8A020),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showEditProfileDialog,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_profilePhoto != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: kIsWeb
            ? Image.network(
                _profilePhoto!.path,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                semanticLabel: 'Foto de perfil de $_displayName',
              )
            : Image.file(
                File(_profilePhoto!.path),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                semanticLabel: 'Foto de perfil de $_displayName',
              ),
      );
    }

    if (_serverPhotoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Image.network(
          _serverPhotoUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          semanticLabel: 'Foto de perfil de $_displayName',
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        ),
      );
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _initials,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '0',
              'Pontos',
              Icons.stars_rounded,
              AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '0',
              'Visitas',
              Icons.storefront_outlined,
              AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'R\$ 0',
              'Economia',
              Icons.savings_outlined,
              const Color(0xFFE8A020),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDataSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do perfil',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: [
                _buildProfileDataRow(
                  icon: Icons.badge_outlined,
                  label: 'CPF',
                  value: _displayCpf,
                ),
                const SizedBox(height: 14),
                _buildProfileDataRow(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  value: _formatPhone(_displayPhone),
                ),
                const SizedBox(height: 14),
                _buildProfileDataRow(
                  icon: Icons.cake_outlined,
                  label: 'Nascimento',
                  value: _displayBirthDate,
                ),
                const SizedBox(height: 14),
                _buildProfileDataRow(
                  icon: Icons.home_outlined,
                  label: 'Rua e número',
                  value: _displayStreetNumber,
                ),
                const SizedBox(height: 14),
                _buildProfileDataRow(
                  icon: Icons.maps_home_work_outlined,
                  label: 'Complemento',
                  value: _displayComplement,
                ),
                const SizedBox(height: 14),
                _buildProfileDataRow(
                  icon: Icons.location_city_outlined,
                  label: 'Bairro',
                  value: _displayNeighborhood,
                ),
                const SizedBox(height: 14),
                _buildProfileDataRow(
                  icon: Icons.location_on_outlined,
                  label: 'Cidade/Estado',
                  value: _displayCityState,
                ),
                const SizedBox(height: 14),
                _buildProfileDataRow(
                  icon: Icons.markunread_mailbox_outlined,
                  label: 'CEP',
                  value: _displayZipCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDataRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantLight,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.history_rounded,
        'label': 'Histórico de acesso',
        'subtitle': 'Veja os registros de acesso',
        'onTap': () => context.push(AppRoutes.accessLogScreen),
        'accent': true,
      },
      {
        'icon': Icons.credit_card_outlined,
        'label': 'Carteirinha digital',
        'subtitle': 'Veja seu cartão de membro',
        'onTap': () => context.go(AppRoutes.digitalMembershipCardScreen),
        'accent': false,
      },
      {
        'icon': Icons.lock_outline_rounded,
        'label': 'Privacidade e segurança',
        'subtitle': 'Senha e biometria',
        'onTap': () {},
        'accent': false,
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Ajuda e suporte',
        'subtitle': 'Dúvidas e contato',
        'onTap': () {},
        'accent': false,
      },
      {
        'icon': Icons.logout_rounded,
        'label': 'Sair',
        'subtitle': 'Encerrar sessão da conta',
        'onTap': _confirmLogout,
        'accent': false,
        'danger': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conta',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: List.generate(menuItems.length, (i) {
                final item = menuItems[i];
                final isDanger = item['danger'] == true;
                final isAccent = item['accent'] == true;
                final color = isDanger
                    ? AppTheme.error
                    : isAccent
                        ? AppTheme.accent
                        : AppTheme.darkText;

                return Column(
                  children: [
                    InkWell(
                      onTap: item['onTap'] as VoidCallback,
                      borderRadius: BorderRadius.circular(16.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDanger
                                    ? AppTheme.error.withAlpha(20)
                                    : isAccent
                                        ? AppTheme.accentLight
                                        : AppTheme.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    item['subtitle'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isDanger)
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppTheme.mutedText,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (i < menuItems.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.outlineLight,
                        indent: 66,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
class _PhoneInputFormatter extends TextInputFormatter {
  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatPhone(String value) {
    final digits = _onlyDigits(value);

    if (digits.isEmpty) {
      return '';
    }

    if (digits.length <= 2) {
      return '(${digits}';
    }

    final ddd = digits.substring(0, 2);
    final number = digits.substring(2);

    if (number.length <= 4) {
      return '($ddd) $number';
    }

    if (digits.length <= 10) {
      final firstPart = number.substring(0, number.length - 4);
      final lastPart = number.substring(number.length - 4);
      return '($ddd) $firstPart-$lastPart';
    }

    final firstPart = number.substring(0, 5);
    final lastPart = number.substring(5, 9);
    return '($ddd) $firstPart-$lastPart';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _onlyDigits(newValue.text);
    final limitedDigits =
        digits.length > 11 ? digits.substring(0, 11) : digits;

    final formatted = _formatPhone(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

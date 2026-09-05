import 'package:borghetto/features/admin/models/admin_app_user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/brazilian_formatters.dart';
import '../../../theme/app_theme.dart';
import '../models/admin_user_detail.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({
    required this.userId,
    super.key,
  });

  final int userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  AdminUserDetail? _detail;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isUpdatingApproval = false;

  String? _errorMessage;

  Color get _readOnlyFieldColor => const Color(0xFFFAF7F2);
  Color get _readOnlyBorderColor => const Color(0xFFE6D8C8);
  Color get _readOnlyIconColor => const Color(0xFF9B7A5F);

  Color get _editingFieldColor => const Color(0xFFECE1D2);
  Color get _editingBorderColor => const Color(0xFFD8C5AD);
  Color get _editingIconColor => const Color(0xFF946B47);

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();

    _zipCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();

    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await ApiClient.instance.getAdminUserDetail(
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      _fillControllers(detail);

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Erro ao carregar detalhes do usuário';
        _isLoading = false;
      });
    }
  }

  void _fillControllers(AdminUserDetail detail) {
    final user = detail.user;

    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = _formatPhone(user.phone);
    _cpfController.text = _formatCpf(user.cpf);
    _birthDateController.text = _formatDate(user.birthDate);

    _zipCodeController.text = _formatZipCode(user.zipCode);
    _streetController.text = _fallback(user.street);
    _numberController.text =
        _fallback(user.number) == '-' ? '' : _fallback(user.number);
    _complementController.text =
        _fallback(user.complement) == '-' ? '' : _fallback(user.complement);
    _neighborhoodController.text =
        _fallback(user.neighborhood) == '-' ? '' : _fallback(user.neighborhood);
    _cityController.text =
        _fallback(user.city) == '-' ? '' : _fallback(user.city);
    _stateController.text =
        _fallback(user.state) == '-' ? '' : _fallback(user.state);
  }

  Future<void> _toggleApproval(bool approved) async {
    setState(() {
      _isUpdatingApproval = true;
    });

    try {
      await ApiClient.instance.updateAdminUserApproval(
        userId: widget.userId,
        approved: approved,
        reviewNote: approved ? null : 'Bloqueio manual pelo administrador',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        approved ? 'Usuário ativado.' : 'Usuário desativado.',
      );

      await _loadDetail();
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      _showSnackBar(
        'Erro inesperado ao alterar status do usuário.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingApproval = false;
        });
      }
    }
  }

  Future<void> _saveUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = onlyDigits(_phoneController.text);
    final cpf = onlyDigits(_cpfController.text);
    final birthDate = _birthDateToApi(_birthDateController.text);
    final zipCode = onlyDigits(_zipCodeController.text);
    final street = _streetController.text.trim();
    final number = _numberController.text.trim();
    final complement = _complementController.text.trim();
    final neighborhood = _neighborhoodController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim().toUpperCase();

    if (name.isEmpty) {
      _showSnackBar('Informe o nome do usuário.', isError: true);
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Informe um e-mail válido.', isError: true);
      return;
    }

    if (phone.isEmpty) {
      _showSnackBar('Telefone não pode ficar em branco.', isError: true);
      return;
    }

    if (!RegExp(r'^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$').hasMatch(phone)) {
      _showSnackBar(
        'Telefone inválido. Informe DDD + telefone. Ex: 51999999999',
        isError: true,
      );
      return;
    }

    if (cpf.length != 11 || !isValidCpf(cpf)) {
      _showSnackBar('Informe um CPF válido.', isError: true);
      return;
    }

    if (birthDate == null) {
      _showSnackBar('Informe uma data de nascimento válida.', isError: true);
      return;
    }

    if (zipCode.isNotEmpty && zipCode.length != 8) {
      _showSnackBar('Informe um CEP válido.', isError: true);
      return;
    }

    if (state.isNotEmpty && state.length != 2) {
      _showSnackBar('Informe a UF com 2 letras.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiClient.instance.updateAdminUser(
        userId: widget.userId,
        name: name,
        email: email,
        phone: phone,
        cpf: cpf,
        birthDate: birthDate,
        zipCode: zipCode.isEmpty ? null : zipCode,
        street: street.isEmpty ? null : street,
        number: number.isEmpty ? null : number,
        complement: complement.isEmpty ? null : complement,
        neighborhood: neighborhood.isEmpty ? null : neighborhood,
        city: city.isEmpty ? null : city,
        state: state.isEmpty ? null : state,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
      });

      _showSnackBar('Usuário atualizado.');

      await _loadDetail();
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      _showSnackBar(
        'Erro inesperado ao salvar usuário.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    final detail = _detail;

    if (detail != null) {
      _fillControllers(detail);
    }

    setState(() {
      _isEditing = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

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
        backgroundColor: isError ? AppTheme.error : AppTheme.primary,
      ),
    );
  }

  String? _buildFaceImageUrl(int? controlIdUserId) {
    if (controlIdUserId == null || controlIdUserId <= 0) {
      return null;
    }

    return '${ApiClient.baseUrl}/facial/users/$controlIdUserId/face';
  }

  String _initialsFromName(String name) {
    final clean = name.trim();

    if (clean.isEmpty) {
      return '?';
    }

    final parts = clean.split(RegExp(r'\s+'));

    return parts
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
  }

  void _showUserPhotoDialog(AdminAppUser user) {
    final imageUrl = _buildFaceImageUrl(user.controlIdUserId);

    if (imageUrl == null) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 42,
          ),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: size.width * 0.88,
              height: size.height * 0.58,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 72,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withAlpha(135),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Detalhes do usuário',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        actions: [
          if (!_isLoading && _errorMessage == null && detail != null)
            IconButton(
              tooltip: _isEditing ? 'Cancelar edição' : 'Editar usuário',
              onPressed: _isSaving || _isUpdatingApproval
                  ? null
                  : () {
                      if (_isEditing) {
                        _cancelEdit();
                        return;
                      }

                      setState(() {
                        _isEditing = true;
                      });
                    },
              icon: Icon(
                _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: _buildBody(detail),
      ),
    );
  }

  Widget _buildBody(AdminUserDetail? detail) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildErrorCard(),
        ],
      );
    }

    if (detail == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildEmptyCard(),
        ],
      );
    }

    final user = detail.user;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildHeaderCard(detail),
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Dados cadastrais',
          children: [
            _InfoRow(label: 'ID interno', value: user.id.toString()),
            const SizedBox(height: 8),
            if (_isEditing) ...[
              _buildEditableField(
                label: 'Nome',
                controller: _nameController,
                icon: Icons.person_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'E-mail',
                controller: _emailController,
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'Telefone',
                controller: _phoneController,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  const PhoneInputFormatter(),
                ],
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'CPF',
                controller: _cpfController,
                icon: Icons.badge_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  const CpfInputFormatter(),
                ],
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'Nascimento',
                controller: _birthDateController,
                icon: Icons.cake_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  const BirthDateInputFormatter(),
                ],
              ),
            ] else ...[
              _buildReadOnlyField(
                label: 'Nome',
                value: user.name,
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'E-mail',
                value: user.email,
                icon: Icons.email_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Telefone',
                value: _formatPhone(user.phone),
                icon: Icons.phone_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'CPF',
                value: _formatCpf(user.cpf),
                icon: Icons.badge_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Nascimento',
                value: _formatDate(user.birthDate),
                icon: Icons.cake_rounded,
              ),
            ],
            const SizedBox(height: 12),
            _buildReadOnlyField(
              label: 'Tipo',
              value: _fallback(user.role),
              icon: Icons.admin_panel_settings_rounded,
            ),
          ],
        ),
        if (_isEditing) ...[
          const SizedBox(height: 14),
          _buildEditActions(),
        ],
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Endereço',
          children: [
            if (_isEditing) ...[
              _buildEditableField(
                label: 'CEP',
                controller: _zipCodeController,
                icon: Icons.markunread_mailbox_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  const ZipCodeInputFormatter(),
                ],
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'Rua',
                controller: _streetController,
                icon: Icons.route_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'Número',
                controller: _numberController,
                icon: Icons.pin_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'Complemento',
                controller: _complementController,
                icon: Icons.home_work_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'Bairro',
                controller: _neighborhoodController,
                icon: Icons.location_city_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'Cidade',
                controller: _cityController,
                icon: Icons.location_on_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: 'UF',
                controller: _stateController,
                icon: Icons.map_rounded,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(2),
                ],
              ),
            ] else ...[
              _buildReadOnlyField(
                label: 'CEP',
                value: _formatZipCode(user.zipCode),
                icon: Icons.markunread_mailbox_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Rua',
                value: _fallback(user.street),
                icon: Icons.route_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Número',
                value: _fallback(user.number),
                icon: Icons.pin_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Complemento',
                value: _fallback(user.complement),
                icon: Icons.home_work_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Bairro',
                value: _fallback(user.neighborhood),
                icon: Icons.location_city_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Cidade',
                value: _fallback(user.city),
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'UF',
                value: _fallback(user.state),
                icon: Icons.map_rounded,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _buildApprovalCard(detail),
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Control iD',
          children: [
            _buildReadOnlyField(
              label: 'ID Control iD',
              value: user.controlIdUserId?.toString() ?? '-',
              icon: Icons.fingerprint_rounded,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              label: 'Vinculado',
              value: user.controlIdUserId != null && user.controlIdUserId! > 0
                  ? 'Sim'
                  : 'Não',
              icon: Icons.link_rounded,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              label: 'Foto facial',
              value: user.controlIdUserId != null && user.controlIdUserId! > 0
                  ? 'Enviada'
                  : 'Sem foto',
              icon: Icons.face_retouching_natural_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildDependentsCard(detail),
      ],
    );
  }

  Widget _buildHeaderCard(AdminUserDetail detail) {
    final user = detail.user;
    final hasFacial = user.controlIdUserId != null && user.controlIdUserId! > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildUserPhotoAvatar(user),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: _translateApprovalStatus(user.approvalStatus),
                      backgroundColor: Colors.white.withAlpha(32),
                      textColor: Colors.white,
                    ),
                    _StatusChip(
                      label: user.approved ? 'Ativo' : 'Inativo',
                      backgroundColor: Colors.white.withAlpha(32),
                      textColor: Colors.white,
                    ),
                    _StatusChip(
                      label: hasFacial ? 'Com foto' : 'Sem foto',
                      backgroundColor: Colors.white.withAlpha(32),
                      textColor: Colors.white,
                    ),
                    _StatusChip(
                      label: '${detail.dependents.length} dependente(s)',
                      backgroundColor: Colors.white.withAlpha(32),
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPhotoAvatar(AdminAppUser user) {
    final imageUrl = _buildFaceImageUrl(user.controlIdUserId);
    final hasPhoto = imageUrl != null;
    final initials = _initialsFromName(user.name);

    return GestureDetector(
      onTap: hasPhoto ? () => _showUserPhotoDialog(user) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(35),
              border: Border.all(
                color: Colors.white.withAlpha(80),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(AdminUserDetail detail) {
    final user = detail.user;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Status'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  user.approved ? 'Usuário ativo' : 'Usuário inativo',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              _isUpdatingApproval
                  ? const SizedBox(
                      width: 44,
                      height: 32,
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    )
                  : Switch.adaptive(
                      value: user.approved,
                      activeThumbColor: AppTheme.success,
                      onChanged: _isSaving ? null : _toggleApproval,
                    ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReadOnlyField(
            label: 'Ativo',
            value: user.active == true ? 'Sim' : 'Não',
            icon: Icons.toggle_on_rounded,
          ),
          const SizedBox(height: 12),
          _buildReadOnlyField(
            label: 'Status',
            value: _translateApprovalStatus(user.approvalStatus),
            icon: Icons.verified_user_rounded,
          ),
          const SizedBox(height: 12),
          _buildReadOnlyField(
            label: 'Nota revisão',
            value: _fallback(user.reviewNote),
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 12),
          _buildReadOnlyField(
            label: 'Revisado em',
            value: _formatDateTime(user.reviewedAt),
            icon: Icons.event_available_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : _cancelEdit,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveUser,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkText,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: _editingFieldColor,
        prefixIcon: Icon(
          icon,
          color: _editingIconColor,
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.mutedText,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: _editingBorderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: _editingIconColor,
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: _editingBorderColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkText,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: _readOnlyFieldColor,
        prefixIcon: Icon(
          icon,
          color: _readOnlyIconColor,
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.mutedText,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: _readOnlyBorderColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDependentsCard(AdminUserDetail detail) {
    final dependents = detail.dependents;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Dependentes',
            trailing: Text(
              dependents.length.toString(),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (dependents.isEmpty)
            Text(
              'Nenhum dependente cadastrado.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText,
              ),
            )
          else
            ...dependents.map(_buildDependentItem),
        ],
      ),
    );
  }

  Widget _buildDependentItem(AdminUserDependent dependent) {
    final active = dependent.active == true;
    final hasFacial =
        dependent.controlIdUserId != null && dependent.controlIdUserId! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: active
                    ? AppTheme.success.withAlpha(25)
                    : AppTheme.error.withAlpha(25),
                child: Icon(
                  Icons.family_restroom_rounded,
                  size: 18,
                  color: active ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dependent.name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  _StatusChip(
                    label: active ? 'Ativo' : 'Inativo',
                    backgroundColor: active
                        ? AppTheme.success.withAlpha(22)
                        : AppTheme.error.withAlpha(22),
                    textColor: active ? AppTheme.success : AppTheme.error,
                  ),
                  _StatusChip(
                    label: hasFacial ? 'Com foto' : 'Sem foto',
                    backgroundColor: hasFacial
                        ? AppTheme.success.withAlpha(22)
                        : AppTheme.warning.withAlpha(22),
                    textColor: hasFacial ? AppTheme.success : AppTheme.warning,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'ID', value: dependent.id.toString()),
          _InfoRow(label: 'CPF', value: _formatCpf(dependent.cpf)),
          _InfoRow(
            label: 'Nascimento',
            value: _formatDate(dependent.birthDate),
          ),
          _InfoRow(
            label: 'Parentesco',
            value: _fallback(dependent.relationship),
          ),
          _InfoRow(
            label: 'ID Control iD',
            value: dependent.controlIdUserId?.toString() ?? '-',
          ),
          _InfoRow(
            label: 'Criado em',
            value: _formatDateTime(dependent.createdAt),
          ),
          _InfoRow(
            label: 'Atualizado em',
            value: _formatDateTime(dependent.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Erro ao carregar detalhes',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadDetail,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        'Nenhum detalhe encontrado.',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkText,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF8F7F5),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0xFFE2DDD6),
      ),
    );
  }

  String _fallback(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) {
      return '-';
    }

    return clean;
  }

  String _formatCpf(String? value) {
    final cpf = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cpf.length != 11) {
      return _fallback(value);
    }

    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  String _formatPhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }

    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }

    return _fallback(value);
  }

  String _formatZipCode(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (digits.length == 8) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }

    return _fallback(value);
  }

  String _translateApprovalStatus(String value) {
    switch (value.toLowerCase().trim()) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'blocked':
        return 'Bloqueado';
      case 'rejected':
        return 'Negado';
      default:
        return value;
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String? _birthDateToApi(String value) {
    final digits = onlyDigits(value);

    if (digits.length != 8) {
      return null;
    }

    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));

    if (day == null || month == null || year == null) {
      return null;
    }

    final date = DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}',
    );

    if (date == null ||
        date.day != day ||
        date.month != month ||
        date.year != year) {
      return null;
    }

    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

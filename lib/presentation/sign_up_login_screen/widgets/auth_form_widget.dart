import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class AuthFormWidget extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onToggleMode;
  final VoidCallback onAuthSuccess;

  const AuthFormWidget({
    super.key,
    required this.isLogin,
    required this.onToggleMode,
    required this.onAuthSuccess,
  });

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isSearchingZipCode = false;
  String? _lastSearchedZipCode;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
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

  Future<void> _showError(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Atenção'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSuccess(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sucesso'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.isLogin) {
      await _handleLogin();
    } else {
      await _handleRegister();
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiClient.instance.login(
        email: email,
        password: password,
      );

      await _showSuccess('Login realizado com sucesso.');

      if (!mounted) return;

      widget.onAuthSuccess();
    } on ApiException catch (e) {
      await _showError(e.message);
    } catch (_) {
      await _showError('Erro inesperado ao fazer login.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final cpf = _onlyDigits(_cpfController.text);
    final phone = _onlyDigits(_phoneController.text);
    final birthDate = _formatBirthDateToApi(_birthDateController.text);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final zipCode = _onlyDigits(_zipCodeController.text);
    final street = _streetController.text.trim();
    final number = _numberController.text.trim();
    final complement = _complementController.text.trim();
    final neighborhood = _neighborhoodController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim().toUpperCase();

    if (!_isValidCpf(cpf)) {
      await _showError('CPF inválido. Verifique o número informado.');
      return;
    }

    if (!_isValidBirthDate(_birthDateController.text)) {
      await _showError('Data de nascimento inválida.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiClient.instance.registerUser(
        name: name,
        cpf: cpf,
        phone: phone,
        birthDate: birthDate,
        email: email,
        password: password,
        zipCode: zipCode,
        street: street,
        number: number,
        complement: complement.isEmpty ? null : complement,
        neighborhood: neighborhood,
        city: city,
        state: state,
      );

      await _showSuccess('Cadastro realizado com sucesso.');

      if (!mounted) return;

      widget.onAuthSuccess();
    } on ApiException catch (e) {
      await _showError(e.message);
    } catch (_) {
      await _showError('Erro inesperado ao criar cadastro.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFaceId() async {
    Fluttertoast.showToast(
      msg: 'Face ID ainda não está integrado ao servidor.',
      backgroundColor: AppTheme.darkText,
      textColor: Colors.white,
    );
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _searchZipCode(String value) async {
    final zipCode = _onlyDigits(value);

    if (zipCode.length != 8) return;
    if (_isSearchingZipCode) return;
    if (_lastSearchedZipCode == zipCode) return;

    setState(() {
      _isSearchingZipCode = true;
      _lastSearchedZipCode = zipCode;
    });

    try {
      final dio = Dio();

      final response = await dio.get(
        'https://viacep.com.br/ws/$zipCode/json/',
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        await _showError('Não foi possível consultar o CEP.');
        return;
      }

      if (data['erro'] == true) {
        await _showError('CEP não encontrado.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _streetController.text = data['logradouro']?.toString() ?? '';
        _neighborhoodController.text = data['bairro']?.toString() ?? '';
        _cityController.text = data['localidade']?.toString() ?? '';
        _stateController.text = data['uf']?.toString() ?? '';
      });
    } on DioException {
      await _showError('Não foi possível consultar o CEP agora.');
    } catch (_) {
      await _showError('Erro inesperado ao consultar CEP.');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingZipCode = false;
        });
      }
    }
  }

  String _formatBirthDateToApi(String value) {
    final digits = _onlyDigits(value);

    if (digits.length != 8) return '';

    final day = digits.substring(0, 2);
    final month = digits.substring(2, 4);
    final year = digits.substring(4, 8);

    return '$year-$month-$day';
  }

  bool _isValidBirthDate(String value) {
    final digits = _onlyDigits(value);

    if (digits.length != 8) return false;

    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));

    if (day == null || month == null || year == null) return false;

    final now = DateTime.now();

    if (year < 1900 || year > now.year) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    final parsed = DateTime(year, month, day);

    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return false;
    }

    if (parsed.isAfter(now)) return false;

    return true;
  }

  bool _isValidCpf(String value) {
  final cpf = _onlyDigits(value);

  if (cpf.length != 11) return false;

  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

  final digits = cpf.split('').map(int.parse).toList();

  var sum = 0;
  for (var i = 0; i < 9; i++) {
    sum += digits[i] * (10 - i);
  }

  var firstCheckDigit = 11 - (sum % 11);
  if (firstCheckDigit >= 10) firstCheckDigit = 0;

  if (digits[9] != firstCheckDigit) return false;

  sum = 0;
  for (var i = 0; i < 10; i++) {
    sum += digits[i] * (11 - i);
  }

  var secondCheckDigit = 11 - (sum % 11);
  if (secondCheckDigit >= 10) secondCheckDigit = 0;

  return digits[10] == secondCheckDigit;
}

  void _handleToggleMode() {
    _formKey.currentState?.reset();

    setState(() {
      _obscurePassword = true;
    });

    widget.onToggleMode();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                widget.isLogin
                    ? 'Bem vindo de volta'
                    : 'Registre-se no Borghetto',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                widget.isLogin ? 'Entre na sua conta' : 'Crie sua conta',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                ),
              ),

              const SizedBox(height: 28),

              if (widget.isLogin) ...[
                _buildDemoCredentialsBox(),
                const SizedBox(height: 20),
              ],

              if (!widget.isLogin) ...[
                _buildUnderlineField(
                  controller: _nameController,
                  label: 'Nome',
                  hint: 'Insira seu nome completo',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Insira seu nome';
                    }

                    if (v.trim().length < 3) {
                      return 'Informe um nome válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _cpfController,
                  label: 'CPF',
                  hint: '000.000.000-00',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    _CpfInputFormatter(),
                  ],
                  validator: (v) {
                    final cpf = _onlyDigits(v ?? '');

                    if (cpf.isEmpty) {
                      return 'Insira seu CPF';
                    }

                    if (cpf.length != 11) {
                      return 'O CPF precisa ter 11 números';
                    }

                    if (!_isValidCpf(cpf)) {
                      return 'Informe um CPF válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _phoneController,
                  label: 'Telefone',
                  hint: '(51) 99999-9999',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    _PhoneInputFormatter(),
                  ],
                  validator: (v) {
                    final phone = _onlyDigits(v ?? '');

                    if (phone.isEmpty) {
                      return 'Insira seu telefone';
                    }

                    final phoneRegex = RegExp(r'^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$');

                    if (!phoneRegex.hasMatch(phone)) {
                      return 'Informe DDD + telefone válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _birthDateController,
                  label: 'Data de nascimento',
                  hint: 'DD/MM/AAAA',
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    _BirthDateInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Insira sua data de nascimento';
                    }

                    if (!_isValidBirthDate(v)) {
                      return 'Informe uma data válida';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _zipCodeController,
                  label: 'CEP',
                  hint: '12345-678',
                  icon: Icons.location_on_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    _CepInputFormatter(),
                  ],
                  suffixIcon: _isSearchingZipCode
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  onChanged: (value) {
                    final zipCode = _onlyDigits(value);

                    if (zipCode.length < 8) {
                      _lastSearchedZipCode = null;
                      return;
                    }

                    if (zipCode.length == 8) {
                      _searchZipCode(value);
                    }
                  },
                  validator: (v) {
                    final zipCode = _onlyDigits(v ?? '');

                    if (zipCode.isEmpty) {
                      return 'Insira seu CEP';
                    }

                    if (zipCode.length != 8) {
                      return 'O CEP precisa ter 8 números';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _streetController,
                  label: 'Rua',
                  hint: 'Nome da rua',
                  icon: Icons.route_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Insira sua rua';
                    }

                    if (v.trim().length < 3) {
                      return 'Informe uma rua válida';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _numberController,
                  label: 'Número',
                  hint: 'Número da residência',
                  icon: Icons.home_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (v) {
                    final number = _onlyDigits(v ?? '');

                    if (number.isEmpty) {
                      return 'Insira o número';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _complementController,
                  label: 'Complemento',
                  hint: 'Apartamento, bloco, casa, referência...',
                  icon: Icons.maps_home_work_outlined,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _neighborhoodController,
                  label: 'Bairro',
                  hint: 'Nome do bairro',
                  icon: Icons.location_city_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Insira seu bairro';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _cityController,
                  label: 'Cidade',
                  hint: 'Nome da cidade',
                  icon: Icons.apartment_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Insira sua cidade';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildUnderlineField(
                  controller: _stateController,
                  label: 'UF',
                  hint: 'RS',
                  icon: Icons.flag_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final state = v?.trim().toUpperCase() ?? '';

                    if (state.isEmpty) {
                      return 'Insira a UF';
                    }

                    if (state.length != 2) {
                      return 'Informe a UF com 2 letras';
                    }

                    return null;
                  },
                ),
              ],

              _buildUnderlineField(
                controller: _emailController,
                label: 'E-mail',
                hint: 'cliente@borghetto.com.br',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Insira seu e-mail';
                  }

                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Insira um e-mail válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              _buildUnderlineField(
                controller: _passwordController,
                label: 'Senha',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_isLoading) {
                    _handleSubmit();
                  }
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppTheme.mutedText,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Insira sua senha';
                  }

                  if (!widget.isLogin && v.length < 8) {
                    return 'A senha precisa de pelo menos 8 caracteres';
                  }

                  return null;
                },
              ),

              if (widget.isLogin) ...[
                const SizedBox(height: 12),

                Row(
                  children: [
                    Transform.scale(
                      scale: 0.85,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: _isLoading
                            ? null
                            : (v) {
                                setState(() {
                                  _rememberMe = v ?? false;
                                });
                              },
                        activeColor: AppTheme.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: AppTheme.outlineLight),
                      ),
                    ),

                    Text(
                      'Lembrar-me',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isLogin ? 'Entrar' : 'Criar conta',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              if (widget.isLogin) _buildFaceIdButton(),

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _handleToggleMode,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                      ),
                      children: [
                        TextSpan(
                          text: widget.isLogin
                              ? 'Não possui uma conta? '
                              : 'Já é membro? ',
                        ),
                        TextSpan(
                          text: widget.isLogin
                              ? 'Registre-se'
                              : 'Entre agora',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredentialsBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'Conta de teste',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _credRow('Email', 'giovane@eventelecom.com.br'),

          const SizedBox(height: 4),

          _credRow('Senha', 'Milen@93'),
        ],
      ),
    );
  }

  Widget _credRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ),

        GestureDetector(
          onTap: () {
            if (label == 'Email') {
              _emailController.text = value;
            } else {
              _passwordController.text = value;
            }

            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accentContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Usar',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaceIdButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleFaceId,
        icon: const Icon(Icons.face_rounded, size: 22),
        label: Text(
          'Continuar com Face ID',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.darkText,
          side: BorderSide(
            color: AppTheme.outlineLight,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_isLoading,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: AppTheme.darkText,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: AppTheme.mutedText,
        ),
        suffixIcon: suffixIcon,
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: AppTheme.mutedText,
        ),
        hintStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: AppTheme.outlineLight,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.outlineLight,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.outlineLight,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.darkText,
            width: 1.5,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.error,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.error,
            width: 1.5,
          ),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.outlineLight,
          ),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 0,
        ),
      ),
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    var formatted = digits;

    if (digits.length > 9) {
      formatted =
          '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    } else if (digits.length > 6) {
      formatted =
          '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
    } else if (digits.length > 3) {
      formatted = '${digits.substring(0, 3)}.${digits.substring(3)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    var formatted = digits;

    if (digits.length >= 11) {
      formatted =
          '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length > 6) {
      formatted =
          '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else if (digits.length > 2) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.isNotEmpty) {
      formatted = '($digits';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _BirthDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }

    var formatted = digits;

    if (digits.length > 4) {
      formatted =
          '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
    } else if (digits.length > 2) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }

    var formatted = digits;

    if (digits.length > 5) {
      formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
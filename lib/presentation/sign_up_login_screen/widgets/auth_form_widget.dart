import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/app_theme.dart';

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
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: Replace with real auth API call
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isLoading = false);
    widget.onAuthSuccess();
  }

  Future<void> _handleFaceId() async {
    setState(() => _isLoading = true);
    // TODO: Replace with local_auth Face ID implementation
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isLoading = false);
    Fluttertoast.showToast(
      msg: 'Face ID verified',
      backgroundColor: AppTheme.accent,
      textColor: Colors.white,
    );
    widget.onAuthSuccess();
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
              // Drag handle
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
                widget.isLogin ? 'Bem vindo de volta' : 'Registre-se no Borghetto',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isLogin
                    ? 'Entre na sua conta'
                    : 'Crie sua conta',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 28),

              // Demo credentials info box
              _buildDemoCredentialsBox(),
              const SizedBox(height: 20),

              // Name field (sign up only)
              if (!widget.isLogin) ...[
                _buildUnderlineField(
                  controller: _nameController,
                  label: 'Nome',
                  hint: 'Insira seu nome completo',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Insira seu nome'
                      : null,
                ),
                const SizedBox(height: 20),
              ],

              // Email field
              _buildUnderlineField(
                controller: _emailController,
                label: 'E-mail',
                hint: 'cliente@borghetto.com.br',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Insira seu e-mail';
                  if (!v.contains('@')) return 'Insira um e-mail válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password field
              _buildUnderlineField(
                controller: _passwordController,
                label: 'Senha',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppTheme.mutedText,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Insira sua senha';
                  if (v.length < 8) {
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
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
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

              // Submit button
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

              // Face ID button
              _buildFaceIdButton(),

              const SizedBox(height: 20),

              // Toggle login / signup
              Center(
                child: GestureDetector(
                  onTap: widget.onToggleMode,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                      ),
                      children: [
                        TextSpan(
                          text: widget.isLogin
                              ? "Não possui uma conta? "
                              : 'Já é membro? ',
                        ),
                        TextSpan(
                          text: widget.isLogin ? 'Registre-se' : 'Entre agora',
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
                'Demo Account',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _credRow('Email', 'maya.chen@borghetto.com'),
          const SizedBox(height: 4),
          _credRow('Password', 'club2026'),
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
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.mutedText),
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
              'Use',
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
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.darkText,
          side: BorderSide(color: AppTheme.outlineLight, width: 1.5),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: AppTheme.darkText,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.mutedText),
        suffixIcon: suffixIcon,
        labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.mutedText),
        hintStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: AppTheme.outlineLight,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.outlineLight),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.outlineLight),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.darkText, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.error, width: 1.5),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      ),
    );
  }
}

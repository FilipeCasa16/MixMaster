import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/local_database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _creatingAccount = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_creatingAccount) {
        await appState.register(_email.text, _password.text);
      } else {
        await appState.login(_email.text, _password.text);
      }
    } on AccountException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível concluir. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(
    String hint, {
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        filled: true,
        fillColor: AppColors.card,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      );

  Widget _passwordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    bool confirmation = false,
  }) {
    return _labeledField(
      label,
      TextFormField(
        controller: controller,
        obscureText: !visible,
        textInputAction:
            confirmation ? TextInputAction.done : TextInputAction.next,
        decoration: _decoration(
          hint,
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.muted,
            ),
          ),
        ),
        validator: (value) {
          final password = value ?? '';
          if (password.isEmpty) return 'Informe sua senha.';
          if (_creatingAccount && password.length < 8) {
            return 'Use pelo menos 8 caracteres.';
          }
          if (confirmation && password != _password.text) {
            return 'As senhas não coincidem.';
          }
          return null;
        },
        onFieldSubmitted: confirmation ? (_) => _submit() : null,
      ),
    );
  }

  Widget _labeledField(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          child,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final title = _creatingAccount ? 'Crie sua conta' : 'Entre na sua conta';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Salve seus drinks favoritos e encontre seu próximo brinde.',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _modeButton('Entrar', false),
                  _modeButton('Criar conta', true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _labeledField(
                    'E-mail',
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: _decoration('seu@email.com'),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    label: 'Senha',
                    hint: _creatingAccount
                        ? 'Mínimo de 8 caracteres'
                        : 'Sua senha',
                    controller: _password,
                    visible: _showPassword,
                    onToggle: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  if (_creatingAccount) ...[
                    const SizedBox(height: 14),
                    _passwordField(
                      label: 'Confirmar senha',
                      hint: 'Digite a senha novamente',
                      controller: _confirmPassword,
                      visible: _showConfirmPassword,
                      onToggle: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                      confirmation: true,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              _creatingAccount ? 'Criar conta' : 'Entrar',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, bool createAccount) {
    final selected = _creatingAccount == createAccount;
    return Expanded(
      child: TextButton(
        onPressed: _busy
            ? null
            : () => setState(() {
                  _creatingAccount = createAccount;
                  _error = null;
                  _formKey.currentState?.reset();
                }),
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppColors.accent.withAlpha(24) : null,
          foregroundColor: selected ? AppColors.accent : AppColors.muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

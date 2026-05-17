import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart' show MaskTextInputFormatter, MaskAutoCompletionType;
import 'package:live_bank/core/utils/validators.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Controladores para os campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();

  // Formatadores para campos
  final maskPhone = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);
      
  final maskCpf = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  // Variáveis de estado
  String? _errorMessage;
  String? _telefoneError, _nomeError, _emailError, _senhaError, _confirmarSenhaError, _cpfError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _aceitouTermos = false;

  // Chave do formulário para validação
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Adiciona listeners para validação em tempo real
    _emailController.addListener(() {
      _validateEmail();
    });
    _senhaController.addListener(() {
      _validateSenha();
    });
    _confirmarSenhaController.addListener(() {
      _validateConfirmarSenha();
    });
    _nomeController.addListener(() {
      _validateNome();
    });
    _telefoneController.addListener(() {
      _validateTelefone();
    });
    _cpfController.addListener(() {
      _validateCpf();
    });
  }

  @override
  void dispose() {
    // Libera recursos
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  // Validação de e-mail em tempo real
  void _validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = null;
        return;
      }

      final text = _emailController.text.trim();
      if (!isValidEmail(text)) {
        _emailError = context.l10n('invalid_email');
      } else {
        _emailError = null;
      }
    });
  }

  void _validateSenha() {
    setState(() {
      if (_senhaController.text.isEmpty) {
        _senhaError = null;
        return;
      }

      if (!isStrongPassword(_senhaController.text)) {
        _senhaError = context.l10n('password_requirements');
      } else {
        _senhaError = null;
      }

      // Valida a confirmação de senha se já foi preenchida
      if (_confirmarSenhaController.text.isNotEmpty) {
        _validateConfirmarSenha();
      }
    });
  }

  void _validateConfirmarSenha() {
    setState(() {
      if (_confirmarSenhaController.text.isEmpty) {
        _confirmarSenhaError = null;
        return;
      }

      if (_confirmarSenhaController.text != _senhaController.text) {
        _confirmarSenhaError = context.l10n('passwords_not_match');
      } else {
        _confirmarSenhaError = null;
      }
    });
  }

  void _validateNome() {
    setState(() {
      if (_nomeController.text.isEmpty) {
        _nomeError = null;
        return;
      }

      if (!isValidName(_nomeController.text)) {
        _nomeError = context.l10n('name_error');
      } else {
        _nomeError = null;
      }
    });
  }

  void _validateTelefone() {
    setState(() {
      if (_telefoneController.text.isEmpty) {
        _telefoneError = null;
        return;
      }

      final phone = _telefoneController.text;
      if (phone.isEmpty) {
        _telefoneError = null;
        return;
      }
      
      final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleaned.length != 11) {
        _telefoneError = context.l10n('phone_error');
      } else if (cleaned[2] != '9') {
        _telefoneError = context.l10n('phone_start_9_error');
      } else if (RegExp(r'^(\d)\1+$').hasMatch(cleaned.substring(2))) {
        _telefoneError = context.l10n('phone_invalid_error');
      } else {
        _telefoneError = null;
      }
    });
  }
  
  void _validateCpf() {
    setState(() {
      if (_cpfController.text.isEmpty) {
        _cpfError = null;
        return;
      }
      
      final cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cpf.length != 11) {
        _cpfError = context.l10n('cpf_digits_error');
      } else if (!isValidCPF(cpf)) {
        _cpfError = context.l10n('invalid_cpf');
      } else {
        _cpfError = null;
      }
    });
  }

  void _register() async {
    // Valida todos os campos antes de enviar
    _validateEmail();
    _validateNome();
    _validateTelefone();
    _validateCpf();
    _validateSenha();
    _validateConfirmarSenha();

    // Verifica se há erros de validação
    if (_emailError != null ||
        _nomeError != null ||
        _telefoneError != null ||
        _cpfError != null ||
        _senhaError != null ||
        _confirmarSenhaError != null ||
        !_aceitouTermos) {
      setState(() {
        _errorMessage = context.l10n('fix_errors');
        if (!_aceitouTermos) {
          _errorMessage = context.l10n('accept_terms_error');
        }
      });
      return;
    }

    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final telefone = _telefoneController.text.trim();
    final nome = _nomeController.text.trim();
    final cpf = _cpfController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    try {
      debugPrint('RegisterScreen: Iniciando processo de cadastro para $email');
      await ref.read(authProvider.notifier).register(
        email: email,
        password: senha,
        nome: nome,
        telefone: telefone,
        cpf: cpf,
      );
      debugPrint('RegisterScreen: register concluído com sucesso');
      
      if (!mounted) {
        debugPrint('RegisterScreen: Widget não está mais montado (root mudou)');
        return;
      }
      
      // Ao cadastrar com sucesso, limpamos a pilha e vamos para a Home
      debugPrint('RegisterScreen: Executando navegação de fallback');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint('RegisterScreen: Erro capturado no _register: $e');
      // Erro tratado pelo ref.listen
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Escuta erros de autenticação para exibir mensagens premium
    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_outlined, size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n('register'),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n('register_subtitle'),
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildTextField(
                          controller: _nomeController,
                          label: context.l10n('full_name'),
                          hint: context.l10n('full_name_hint'),
                          icon: Icons.person_outline,
                          errorText: _nomeError,
                          textCapitalization: TextCapitalization.words,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _cpfController,
                          label: 'CPF',
                          hint: '000.000.000-00',
                          icon: Icons.badge_outlined,
                          errorText: _cpfError,
                          keyboardType: TextInputType.number,
                          inputFormatters: [maskCpf],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _telefoneController,
                                label: context.l10n('phone'),
                                hint: '(00) 00000-0000',
                                icon: Icons.phone_outlined,
                                errorText: _telefoneError,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [maskPhone],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: context.l10n('email'),
                          hint: 'seu@email.com',
                          icon: Icons.email_outlined,
                          errorText: _emailError,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _senhaController,
                          label: context.l10n('password'),
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          errorText: _senhaError,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _confirmarSenhaController,
                          label: context.l10n('confirm_password'),
                          hint: '••••••••',
                          icon: Icons.lock_reset,
                          obscureText: _obscureConfirmPassword,
                          errorText: _confirmarSenhaError,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),

                        const SizedBox(height: 24),

                        CheckboxListTile(
                          value: _aceitouTermos,
                          onChanged: (val) => setState(() => _aceitouTermos = val ?? false),
                          title: Text(
                            context.l10n('accept_terms'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        ),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: authState.isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(context.l10n('register').toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('${context.l10n('already_account')} ${context.l10n('login')}', style: const TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters?.cast<TextInputFormatter>(),
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.7)),
        suffixIcon: suffixIcon,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
    );
  }
}

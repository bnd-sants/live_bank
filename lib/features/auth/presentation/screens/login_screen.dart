import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/services/biometric_service.dart';
import '../providers/auth_provider.dart';
import 'package:live_bank/features/dashboard/presentation/screens/home_screen.dart';
import 'register_screen.dart';
import 'package:live_bank/core/utils/validators.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:live_bank/routes/custom_route.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _biometricService = BiometricService();
  bool _biometriaDisponivel = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _senhaError;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
    
    // Adiciona listeners para validação em tempo real
    _emailController.addListener(_validateEmail);
    _senhaController.addListener(_validateSenha);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _senhaController.removeListener(_validateSenha);
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
  
  // Verifica se o formulário está válido
  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
           _emailError == null &&
           _senhaController.text.isNotEmpty &&
           _senhaError == null;
  }
  
  // Valida o campo de e-mail
  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = null;
        return;
      }
      
      if (!isValidEmail(email)) {
        _emailError = context.l10n('invalid_email');
      } else {
        _emailError = null;
      }
    });
  }
  
  // Valida o campo de senha
  void _validateSenha() {
    setState(() {
      if (_senhaController.text.isEmpty) {
        _senhaError = null;
        return;
      }
      
      if (_senhaController.text.length < 4) {
        _senhaError = context.l10n('password_too_short');
      } else {
        _senhaError = null;
      }
    });
  }

  Future<void> _verificarBiometria() async {
    final disponivel = await _biometricService.isBiometricAvailable();
    final cadastrada = await _biometricService.hasEnrolledBiometrics();
    final habilitada = await _biometricService.isBiometricEnabled();
    setState(() {
      _biometriaDisponivel = disponivel && cadastrada && habilitada;
    });
  }

  Future<void> _autenticarComBiometria() async {
    final autenticado = await _biometricService.authenticate();
    if (autenticado && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (!_isFormValid) return;
    
    // Força a validação dos campos
    _validateEmail();
    _validateSenha();
    
    // Verifica se ainda há erros após a validação
    if (_emailError != null || _senhaError != null) {
      return;
    }
    
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    
    try {
      debugPrint('LoginScreen: Iniciando processo de login para $email');
      await ref.read(authProvider.notifier).signIn(email, senha);
      debugPrint('LoginScreen: signIn concluído com sucesso');
      
      if (!mounted) {
        debugPrint('LoginScreen: Widget não está mais montado (provavelmente root já mudou)');
        return;
      }
      
      // Ao logar com sucesso, limpamos a pilha e vamos para a Home
      debugPrint('LoginScreen: Executando navegação de fallback');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint('LoginScreen: Erro capturado no _login: $e');
      // O erro é tratado pelo ref.listen no build
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

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
              duration: const Duration(seconds: 4),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                
                // Logo e Título
                Column(
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 80,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                letterSpacing: 1.2,
                              ),
                              children: [
                                TextSpan(
                                  text: 'LIVE',
                                  style: TextStyle(
                                    color: theme.textTheme.displayLarge?.color,
                                  ),
                                ),
                                TextSpan(
                                  text: ' BANK',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n('premium_experience'),
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),
  
                // Formulário de login
                Card(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título do formulário
                        Text(
                          context.l10n('login'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n('login_subtitle'),
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
  
                        // Campo de E-mail
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: context.l10n('email'),
                            hintText: 'exemplo@email.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                            errorText: _emailError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
  
                        // Campo de senha
                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: context.l10n('password'),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                            errorText: _senhaError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
  
                        // Botão de login
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (isLoading || !_isFormValid) ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormValid 
                                  ? theme.primaryColor 
                                  : theme.dividerColor,
                              elevation: _isFormValid ? 4 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    context.l10n('login'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
  
                        // Link para cadastro
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n('no_account'),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  SlideRightRoute(
                                    page: const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                context.l10n('register'),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Biometria com animação
                if (_biometriaDisponivel) ...[
                  const SizedBox(height: 40),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _autenticarComBiometria,
                            borderRadius: BorderRadius.circular(40),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                color: AppColors.primary.withValues(alpha: 0.05),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: const Icon(
                                Icons.fingerprint,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n('biometrics'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_bank/core/providers/supabase_provider.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
}

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Ocorreu um erro inesperado ao fazer login';
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nome,
    required String telefone,
  }) async {
    try {
      // 1. Criar o usuário no Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
          'telefone': telefone,
          'tipo_pessoa': 'fisica',
        },
      );

      if (response.user == null) {
        throw 'Falha ao criar conta. Tente novamente.';
      }

      // 2. Garantir a criação do perfil na tabela 'users'
      // Nota: Idealmente isso seria feito via Trigger no Supabase, 
      // mas mantemos aqui para garantir consistência com a lógica anterior.
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        nome: nome,
        telefone: telefone,
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Ocorreu um erro inesperado ao criar conta';
    }
  }

  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String nome,
    required String telefone,
  }) async {
    try {
      await _supabase.from('users').upsert({
        'user_id': userId,
        'email': email,
        'nome': nome,
        'telefone': telefone,
        'tipo_pessoa': 'fisica',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Retry simples se falhar (ex: delay de propagação do auth)
      await Future.delayed(const Duration(seconds: 1));
      await _supabase.from('users').upsert({
        'user_id': userId,
        'email': email,
        'nome': nome,
        'telefone': telefone,
        'tipo_pessoa': 'fisica',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials') || 
        message.contains('invalid email or password')) {
      return 'E-mail ou senha incorretos';
    }
    if (message.contains('already registered') || 
        message.contains('user_already_exists')) {
      return 'Este e-mail já está em uso';
    }
    if (message.contains('email not confirmed')) {
      return 'Por favor, confirme seu e-mail para prosseguir';
    }
    return e.message;
  }
}

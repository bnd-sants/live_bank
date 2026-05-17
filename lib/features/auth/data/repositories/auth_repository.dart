import 'package:flutter/foundation.dart';
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

  /// Verifica se e-mail ou CPF já existem na tabela public.users usando RPC (Security Definer)
  Future<void> _checkEmailOrCpfConflict(String email, String cpf) async {
    try {
      final response = await _supabase.rpc(
        'check_user_exists',
        params: {
          'p_email': email,
          'p_cpf': cpf,
        },
      );

      if (response['exists'] == true) {
        if (response['field'] == 'email') {
          throw 'Este e-mail já está em uso';
        } else if (response['field'] == 'cpf') {
          throw 'Este CPF já está em uso';
        }
      }
    } catch (e) {
      // Se for nossa mensagem customizada, repassa
      if (e is String) rethrow;
      // Caso contrário, ignora (deixa o Auth ou o Trigger tratar se houver erro real)
      debugPrint('Erro ao verificar conflitos: $e');
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    required String cpf,
  }) async {
    try {
      // 0. Pré-verificação de conflitos no banco (evita erro genérico do trigger)
      await _checkEmailOrCpfConflict(email, cpf);

      // 1. Criar o usuário no Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
          'telefone': telefone,
          'cpf': cpf,
          'tipo_pessoa': 'fisica',
        },
      );

      if (response.user == null) {
        throw 'Falha ao criar conta. Tente novamente.';
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Se for um erro que já tratamos como String, apenas repassa
      if (e is String) rethrow;
      throw 'Ocorreu um erro inesperado ao criar conta';
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
    if (message.contains('database error saving new user')) {
      return 'Erro ao salvar dados. Verifique se o CPF ou e-mail já estão cadastrados.';
    }
    if (message.contains('network error') || message.contains('failed host lookup')) {
      return 'Erro de conexão. Verifique sua internet.';
    }

    return e.message;
  }
}

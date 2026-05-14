import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_bank/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  AsyncValue<User?> build() {
    final repository = ref.watch(authRepositoryProvider);
    
    // Escuta mudanças no estado de autenticação
    repository.authStateChanges.listen((data) {
      state = AsyncValue.data(data.session?.user);
    });

    return AsyncValue.data(repository.currentUser);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signIn(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nome,
    required String telefone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signUp(
        email: email,
        password: password,
        nome: nome,
        telefone: telefone,
      );
      state = AsyncValue.data(response.user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

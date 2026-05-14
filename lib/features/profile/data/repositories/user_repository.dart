import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_bank/core/providers/supabase_provider.dart';
import 'package:live_bank/core/error/failure.dart';
import 'package:live_bank/core/utils/result.dart';

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  Future<Result<Map<String, dynamic>>> getUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Result.failure(const AuthFailure('Usuário não autenticado'));

      final data = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return Result.failure(const DatabaseFailure('Perfil não encontrado'));
      
      return Result.success(data);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao buscar perfil', originalError: e));
    }
  }

  Future<Result<void>> updateUserProfile({
    String? nome,
    String? telefone,
    String? foto,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Result.failure(const AuthFailure('Usuário não autenticado'));

      final updateData = <String, dynamic>{};
      if (nome != null) updateData['nome'] = nome;
      if (telefone != null) updateData['telefone'] = telefone;
      if (foto != null) updateData['foto'] = foto;

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();
        await _supabase.from('users').update(updateData).eq('user_id', userId);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao atualizar perfil', originalError: e));
    }
  }

  Future<Result<String>> uploadProfilePhoto(File file) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Result.failure(const AuthFailure('Usuário não autenticado'));

      final storage = _supabase.storage.from('profile-photos');
      final filePath = 'user_$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      await storage.upload(filePath, file);
      final url = storage.getPublicUrl(filePath);

      await updateUserProfile(foto: url);

      return Result.success(url);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao fazer upload da foto', originalError: e));
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return UserRepository(supabase);
});

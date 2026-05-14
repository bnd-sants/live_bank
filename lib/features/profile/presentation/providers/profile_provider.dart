import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/profile/data/repositories/user_repository.dart';
import 'package:live_bank/core/utils/result.dart';

class ProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final repository = ref.watch(userRepositoryProvider);
    final result = await repository.getUserProfile();
    
    return result.when(
      success: (data) => data,
      failure: (failure) => throw failure,
    );
  }

  Future<void> updateProfile({
    String? nome,
    String? telefone,
  }) async {
    state = const AsyncValue.loading();
    final repository = ref.read(userRepositoryProvider);
    
    final result = await repository.updateUserProfile(
      nome: nome,
      telefone: telefone,
    );

    result.when(
      success: (_) {
        ref.invalidateSelf();
      },
      failure: (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
    );
  }

  Future<void> uploadPhoto(File file) async {
    state = const AsyncValue.loading();
    final repository = ref.read(userRepositoryProvider);
    
    final result = await repository.uploadProfilePhoto(file);

    result.when(
      success: (url) {
        ref.invalidateSelf();
      },
      failure: (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Map<String, dynamic>>(() {
  return ProfileNotifier();
});

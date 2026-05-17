import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/services/biometric_service.dart';
import 'package:live_bank/features/auth/data/repositories/auth_repository.dart';

class BiometricState {
  final bool isAvailable;
  final bool isEnabled;
  final bool hasEnrolled;
  final String status;
  final bool isLoading;

  BiometricState({
    this.isAvailable = false,
    this.isEnabled = false,
    this.hasEnrolled = false,
    this.status = 'Verificando...',
    this.isLoading = true,
  });

  BiometricState copyWith({
    bool? isAvailable,
    bool? isEnabled,
    bool? hasEnrolled,
    String? status,
    bool? isLoading,
  }) {
    return BiometricState(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      hasEnrolled: hasEnrolled ?? this.hasEnrolled,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<BiometricState> {
  final BiometricService _biometricService;
  final Ref ref;

  SettingsNotifier(this._biometricService, this.ref) : super(BiometricState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, status: 'Verificando disponibilidade...');
    
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      final hasEnrolled = await _biometricService.hasEnrolledBiometrics();
      
      String status = isAvailable 
          ? (hasEnrolled ? 'Disponível' : 'Nenhuma biometria cadastrada')
          : 'Não disponível';

      state = state.copyWith(
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        hasEnrolled: hasEnrolled,
        status: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: 'Erro ao verificar',
      );
    }
  }

  Future<bool> toggleBiometric(bool value, {String? password}) async {
    state = state.copyWith(isLoading: true);
    
    try {
      if (value) {
        final authenticated = await _biometricService.authenticate(
          localizedReason: 'Autentique-se para habilitar a biometria',
        );
        
        if (!authenticated) {
          state = state.copyWith(isLoading: false);
          return false;
        }

        if (password != null) {
          final repo = ref.read(authRepositoryProvider);
          final user = repo.currentUser;
          if (user == null || user.email == null) {
            state = state.copyWith(isLoading: false);
            return false;
          }

          // Tenta fazer login para validar a senha
          try {
            await repo.signIn(email: user.email!, password: password);
          } catch (e) {
            // Senha incorreta ou erro de rede
            state = state.copyWith(isLoading: false);
            return false;
          }

          // Se deu certo, salva as credenciais de forma segura!
          await _biometricService.saveCredentials(user.email!, password);
        }
      } else {
        // Ao desabilitar, limpa as credenciais biométricas salvas
        await _biometricService.clearCredentials();
      }

      final success = await _biometricService.setBiometricEnabled(value);
      
      if (success) {
        state = state.copyWith(
          isEnabled: value,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final biometricServiceProvider = Provider((ref) => BiometricService());

final settingsProvider = StateNotifierProvider<SettingsNotifier, BiometricState>((ref) {
  final service = ref.watch(biometricServiceProvider);
  return SettingsNotifier(service, ref);
});

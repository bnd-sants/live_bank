import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/services/biometric_service.dart';

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

  SettingsNotifier(this._biometricService) : super(BiometricState()) {
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

  Future<bool> toggleBiometric(bool value) async {
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
  return SettingsNotifier(service);
});

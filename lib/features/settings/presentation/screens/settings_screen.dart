import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:live_bank/features/settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.transparent,
      ),
      body: settingsState.isLoading && settingsState.status == 'Verificando...'
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Segurança',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (settingsState.isAvailable) ...[
                  SwitchListTile(
                    title: const Text('Usar biometria', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(
                      settingsState.status,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    activeColor: AppColors.primary,
                    secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                    value: settingsState.isEnabled,
                    onChanged: settingsState.isLoading 
                        ? null 
                        : (value) async {
                            final success = await ref.read(settingsProvider.notifier).toggleBiometric(value);
                            if (!context.mounted) return;
                            
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value 
                                      ? 'Autenticação biométrica necessária para habilitar' 
                                      : 'Não foi possível desabilitar a biometria'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value 
                                      ? 'Biometria habilitada com sucesso' 
                                      : 'Biometria desabilitada'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                  ),
                  if (settingsState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.divider),
                    ),
                ] else
                  ListTile(
                    title: const Text('Biometria não disponível', style: TextStyle(color: AppColors.textSecondary)),
                    subtitle: Text(
                      settingsState.status,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                    leading: const Icon(
                      Icons.fingerprint_outlined,
                      color: AppColors.error,
                    ),
                  ),
                const Divider(color: AppColors.divider),
              ],
            ),
    );
  }
}

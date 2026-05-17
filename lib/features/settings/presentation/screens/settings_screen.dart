import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:live_bank/core/providers/app_state_provider.dart';
import 'package:live_bank/features/settings/presentation/providers/settings_provider.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _getLocalizedStatus(BuildContext context, String status) {
    switch (status) {
      case 'Verificando...':
        return context.l10n('status_verifying');
      case 'Verificando disponibilidade...':
        return context.l10n('status_verifying_availability');
      case 'Disponível':
        return context.l10n('status_available');
      case 'Nenhuma biometria cadastrada':
        return context.l10n('status_no_biometrics');
      case 'Não disponível':
        return context.l10n('status_not_available');
      case 'Erro ao verificar':
        return context.l10n('status_error_checking');
      default:
        return status;
    }
  }

  Future<String?> _showPasswordConfirmationDialog(BuildContext context) {
    final controller = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n('confirm_access_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n('confirm_access_desc'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n('current_password_label'),
                      labelStyle: const TextStyle(color: AppColors.primary),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        onPressed: () => setStateDialog(() => obscure = !obscure),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : AppColors.divider,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.l10n('cancel'),
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, controller.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    context.l10n('confirm'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n('settings_title')),
        backgroundColor: Colors.transparent,
      ),
      body: settingsState.isLoading && settingsState.status == 'Verificando...'
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.l10n('security_section'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (settingsState.isAvailable) ...[
                  SwitchListTile(
                    title: Text(context.l10n('use_biometrics')),
                    subtitle: Text(
                      _getLocalizedStatus(context, settingsState.status),
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeThumbColor: AppColors.primary,
                    secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                    value: settingsState.isEnabled,
                    onChanged: settingsState.isLoading 
                        ? null 
                        : (value) async {
                            String? password;
                            if (value) {
                              password = await _showPasswordConfirmationDialog(context);
                              if (password == null || password.isEmpty) {
                                return; // Cancelado
                              }
                            }
                            
                            final success = await ref.read(settingsProvider.notifier).toggleBiometric(value, password: password);
                            if (!context.mounted) return;
                            
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value 
                                      ? context.l10n('biometric_error_enable_or_wrong_password') 
                                      : context.l10n('biometric_error_disable')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value 
                                      ? context.l10n('biometric_success_enable') 
                                      : context.l10n('biometric_success_disable')),
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
                    title: Text(context.l10n('biometrics_not_available')),
                    subtitle: Text(
                      _getLocalizedStatus(context, settingsState.status),
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                    leading: const Icon(
                      Icons.fingerprint_outlined,
                      color: AppColors.error,
                    ),
                  ),
                const Divider(color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.l10n('appearance_section'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: Text(context.l10n('dark_mode')),
                  secondary: const Icon(Icons.brightness_6),
                  value: appState.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(appStateProvider.notifier).toggleTheme();
                  },
                ),
                const Divider(color: AppColors.divider),
              ],
            ),
    );
  }
}

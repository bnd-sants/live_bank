import 'package:flutter/material.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:live_bank/features/auth/presentation/providers/auth_provider.dart';
import 'package:live_bank/features/profile/presentation/providers/profile_provider.dart';
import 'package:live_bank/core/providers/app_state_provider.dart';
import 'package:live_bank/core/utils/validators.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) text = text.substring(0, 11);
    String formatted = text;
    
    if (text.isNotEmpty) {
      formatted = '(${text.substring(0, text.length > 2 ? 2 : text.length)}';
      if (text.length > 2) {
        formatted += ') ${text.substring(2, text.length > 7 ? 7 : text.length)}';
        if (text.length > 7) {
          formatted += '-${text.substring(7)}';
        }
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  bool _isEditing = false;
  String? _nomeError, _telefoneError;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  String _maskCpf(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 11) return cpf;
    return '${clean.substring(0, 3)}.***.***-${clean.substring(9)}';
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera, // Mudei para câmera como padrão para testar refinamento
      imageQuality: 100, // Qualidade máxima aqui, comprimimos depois
    );
    
    if (picked == null) return;

    // 1. Cortar a imagem (Crop)
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar Foto',
          toolbarColor: AppColors.background,
          toolbarWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Ajustar Foto',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;

    // 2. Comprimir a imagem
    final tempDir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, "profile_${DateTime.now().millisecondsSinceEpoch}.jpg");

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      croppedFile.path,
      targetPath,
      quality: 70, // Reduz para 70% para otimização premium
      format: CompressFormat.jpeg,
    );

    if (compressedFile == null) return;
    
    final file = File(compressedFile.path);
    try {
      await ref.read(profileProvider.notifier).uploadPhoto(file);
      _showSuccessSnackBar('Foto atualizada com sucesso!');
    } catch (e) {
      _showErrorSnackBar('Erro ao enviar foto: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _nomeError = null;
      _telefoneError = null;
    });

    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();
    bool hasError = false;

    if (nome.isEmpty) {
      _nomeError = 'O nome é obrigatório.';
      hasError = true;
    } else if (!isValidName(nome)) {
      _nomeError = 'Nome inválido (apenas letras e espaços, mínimo 3 letras).';
      hasError = true;
    }

    if (telefone.isNotEmpty && !isValidPhoneBR(telefone)) {
      _telefoneError = 'Telefone inválido (use DDD, ex: 11999999999).';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    try {
      await ref.read(profileProvider.notifier).updateProfile(
        nome: nome,
        telefone: telefone,
      );
      _showSuccessSnackBar('Perfil salvo com sucesso!');
      setState(() => _isEditing = false);
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar perfil: $e');
    }
  }

  void _toggleEditMode(Map<String, dynamic>? data) {
    setState(() {
      if (!_isEditing && data != null) {
        _nomeController.text = data['nome'] ?? '';
        _telefoneController.text = data['telefone'] ?? '';
      }
      _isEditing = !_isEditing;
      _nomeError = null;
      _telefoneError = null;
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'Não informado',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow({
    required String label,
    required TextEditingController controller,
    String? errorText,
    bool isRequired = false,
    bool isPhone = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (isRequired ? ' *' : ''),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: errorText,
              errorStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
            ),
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            inputFormatters: isPhone
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    _TelefoneInputFormatter(),
                  ]
                : null,
            readOnly: readOnly,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileProvider);
    final appState = ref.watch(appStateProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n('profile')),
        backgroundColor: Colors.transparent,
        actions: [
          profileState.when(
            data: (data) => IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () => _toggleEditMode(data),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileState.when(
        data: (data) {
          final cpf = data['cpf'] ?? '';
          final email = data['email'] ?? '';
          final fotoUrl = data['foto'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                      child: fotoUrl == null
                          ? Icon(Icons.person, size: 64, color: theme.textTheme.bodyMedium?.color)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _pickAndUploadPhoto,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('CPF', _maskCpf(cpf)),
                      Divider(height: 24, color: theme.dividerColor),
                      _isEditing
                          ? _buildEditableInfoRow(
                              label: context.l10n('full_name'),
                              controller: _nomeController,
                              errorText: _nomeError,
                              isRequired: true,
                            )
                          : _buildInfoRow(context.l10n('full_name'), data['nome'] ?? ''),
                      Divider(height: 24, color: theme.dividerColor),
                      _buildInfoRow(context.l10n('email'), email),
                      Divider(height: 24, color: theme.dividerColor),
                      _isEditing
                          ? _buildEditableInfoRow(
                              label: context.l10n('phone'),
                              controller: _telefoneController,
                              errorText: _telefoneError,
                              isPhone: true,
                            )
                          : _buildInfoRow(context.l10n('phone'), data['telefone'] ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isEditing) ...[
                  ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: Text(context.l10n('save')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _toggleEditMode(null),
                    icon: const Icon(Icons.close),
                    label: Text(context.l10n('cancel')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n('settings'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.color_lens, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(context.l10n('theme'), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                            ],
                          ),
                          DropdownButton<ThemeMode>(
                            value: appState.themeMode,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('Sistema'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Claro'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Escuro'),
                              ),
                            ],
                            onChanged: (mode) {
                              if (mode != null) {
                                ref.read(appStateProvider.notifier).setThemeMode(mode);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.divider),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: Text(context.l10n('logout'), style: const TextStyle(color: Colors.red)),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sair da conta'),
                              content: const Text('Tem certeza que deseja sair da sua conta?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                    ref.read(authProvider.notifier).signOut();
                                  },
                                  child: Text('Sair', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar perfil: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

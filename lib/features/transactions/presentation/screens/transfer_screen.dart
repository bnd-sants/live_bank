import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:live_bank/features/transactions/data/repositories/transaction_repository.dart';
import 'package:live_bank/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'receipt_screen.dart';
import 'package:live_bank/widgets/secure_screen.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  String _selectedPixType = 'cpf';
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  Map<String, dynamic>? _recipientAccount;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _recipientController.text.isNotEmpty) {
        _searchRecipient();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _searchRecipient() async {
    final searchTerm = _recipientController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() => _recipientAccount = null);
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.searchRecipient(searchTerm, _selectedPixType);

    if (mounted) {
      result.when(
        success: (data) {
          setState(() {
            _recipientAccount = data;
            _isSearching = false;
          });
        },
        failure: (failure) {
          setState(() {
            _errorMessage = failure.message;
            _recipientAccount = null;
            _isSearching = false;
          });
        },
      );
    }
  }

  Future<void> _transferir() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipientAccount == null) return;

    final valor = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) / 100;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.executeTransfer(
      toUserId: _recipientAccount!['user_id'],
      amount: valor,
      description: 'Transferência via PIX',
    );

    if (mounted) {
      result.when(
        success: (data) async {
          // Atualiza saldo e histórico no provider global
          ref.invalidate(balanceProvider);
          ref.invalidate(transactionsProvider);

          final now = DateTime.now();
          final formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(
                destinatario: _recipientAccount?['nome'] ?? 'Destinatário',
                valorEmReais: valor,
                data: formattedDate,
                moeda: 'BRL',
                valorOriginal: valor,
                transactionId: data['transaction_id'],
              ),
            ),
          );
        },
        failure: (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n('transfer')),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceHeader(balanceAsync),
                const SizedBox(height: 32),
                
                // Campo de valor
                TextFormField(
                  controller: _amountController,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: context.l10n('amount_to_transfer'),
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surface : AppColors.grey100,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _RealInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return context.l10n('inform_amount');
                    final valor = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    if (valor < 50) return context.l10n('min_amount_error');
                    
                    final currentBalance = balanceAsync.asData?.value ?? 0;
                    if (valor / 100 > currentBalance) return context.l10n('insufficient_balance');
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Seletor de tipo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : AppColors.grey100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPixType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'cpf', child: Text('CPF')),
                        DropdownMenuItem(value: 'email', child: Text('E-mail')),
                        DropdownMenuItem(value: 'celular', child: Text('Celular')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPixType = value;
                            _recipientController.clear();
                            _recipientAccount = null;
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Campo destinatário
                TextFormField(
                  controller: _recipientController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    labelText: _getRecipientFieldLabel(),
                    hintText: _getRecipientHint(),
                    prefixIcon: const Icon(Icons.person_search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surface : AppColors.grey100,
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : null,
                  ),
                  keyboardType: _getKeyboardType(),
                  onFieldSubmitted: (_) => _searchRecipient(),
                  validator: (value) {
                    if (value == null || value.isEmpty) return context.l10n('inform_recipient');
                    if (_recipientAccount == null) return context.l10n('invalid_recipient');
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Card do Destinatário
                if (_recipientAccount != null) _buildRecipientCard(theme),

                if (_errorMessage != null) _buildErrorMessage(theme),

                const SizedBox(height: 32),

                // Botão principal
                ElevatedButton(
                  onPressed: _isLoading || _isSearching || _recipientAccount == null
                      ? null
                      : _transferir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(context.l10n('confirm_transfer'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(AsyncValue<double> balanceAsync) {
    return balanceAsync.when(
      data: (balance) => Column(
        children: [
          Text(context.l10n('balance'), style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(
            'R\$ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecipientCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recipientAccount!['nome'] ?? 'Nome não informado',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      _formatInfoValue(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _getRecipientFieldLabel() {
    switch (_selectedPixType) {
      case 'cpf': return context.l10n('cpf_label');
      case 'email': return context.l10n('email_label');
      case 'celular': return context.l10n('phone_label');
      default: return 'Chave PIX';
    }
  }

  String _getRecipientHint() {
    switch (_selectedPixType) {
      case 'cpf': return '000.000.000-00';
      case 'email': return 'email@exemplo.com';
      case 'celular': return '(00) 00000-0000';
      default: return '';
    }
  }

  String _formatInfoValue() {
    if (_recipientAccount == null) return '';
    if (_selectedPixType == 'cpf') return 'CPF: ${_formatCpf(_recipientAccount!['cpf'])}';
    if (_selectedPixType == 'email') return 'E-mail: ${_recipientAccount!['email']}';
    return 'Tel: ${_formatPhone(_recipientAccount!['telefone'])}';
  }

  TextInputType _getKeyboardType() {
    switch (_selectedPixType) {
      case 'cpf':
      case 'celular': return TextInputType.phone;
      case 'email': return TextInputType.emailAddress;
      default: return TextInputType.text;
    }
  }

  String _formatCpf(String? cpf) {
    if (cpf == null || cpf.length != 11) return cpf ?? '';
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  String _formatPhone(String? phone) {
    if (phone == null) return '';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    return phone;
  }
}

class _RealInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(cleanText) ?? 0;
    final formattedText = (value / 100).toStringAsFixed(2).replaceAll('.', ',');
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

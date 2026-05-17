import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:live_bank/services/pdf_service.dart';
import 'package:live_bank/services/biometric_service.dart';
import 'package:live_bank/core/utils/file_helper.dart';
import 'package:live_bank/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:live_bank/features/auth/presentation/providers/auth_provider.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/shimmer_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Controle de paginação
  final int _itemsPerPage = 10;
  int _displayedItems = 10;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // Filtros
  String _recipientFilter = '';
  String _typeFilter = 'Todos';
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  double? _minAmountFilter;
  double? _maxAmountFilter;
  String? _dateError;

  // Gráficos
  String _chartType = 'Barra';
  final List<String> _chartTypes = ['Barra', 'Linha', 'Pizza'];

  // Personalização
  bool _showBalance = true;
  bool _showTransactions = true;
  final Map<String, bool> _visibleCharts = {
    'Barra': true,
    'Linha': true,
    'Pizza': true,
  };
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  final BiometricService _biometricService = BiometricService();

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadCustomizationPreferences();
    _initializeNotifications().then((_) => _checkBalanceAndNotify());
    _checkBiometricAvailability();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    // Na Web ou se não for uma plataforma suportada, não inicializamos
    if (kIsWeb) {
      _notificationsInitialized = false;
      return;
    }
    
    try {
      // Configuramos apenas Android por enquanto, pois o plugin pode ter 
      // limitações em outras plataformas dependendo da configuração do projeto.
      // Se for Windows ou macOS, o plugin pode exigir configurações extras.
      if (Platform.isAndroid) {
        const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initSettings = InitializationSettings(
          android: androidInit,
        );
        await notificationsPlugin.initialize(initSettings);
        _notificationsInitialized = true;
      } else {
        _notificationsInitialized = false;
      }
    } catch (e) {
      debugPrint('Erro ao inicializar notificações: $e');
      _notificationsInitialized = false;
    }
  }

  Future<void> _checkBalanceAndNotify() async {
    if (!_notificationsInitialized || kIsWeb) return;

    try {
      final balanceValue = ref.read(balanceProvider);
      
      // Se houver erro no provider (ex: sessão expirada), não tentamos mostrar notificação
      if (balanceValue.hasError) return;

      final balance = balanceValue.value ?? 0.0;
      
      if (balance > 1000) {
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'balance_channel',
          'Saldo',
          importance: Importance.max,
          priority: Priority.high,
        );
        
        const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
        );

        await notificationsPlugin.show(
          0,
          'Saldo em Conta',
          'Seu saldo atual é de R\$ ${balance.toStringAsFixed(2)}',
          platformDetails,
        );
      }
    } catch (e) {
      debugPrint('Erro ao mostrar notificação: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
    });
    // Simulação de carregamento
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _displayedItems += _itemsPerPage;
          _loadingMore = false;
        });
      }
    });
  }

  void _validateDateFilter() {
    if (_startDateFilter != null && _endDateFilter != null) {
      if (_startDateFilter!.isAfter(_endDateFilter!)) {
        setState(() {
          _dateError = 'A data inicial não pode ser maior que a data final.';
        });
      } else {
        setState(() {
          _dateError = null;
        });
      }
    } else {
      setState(() {
        _dateError = null;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _recipientFilter = '';
      _typeFilter = 'Todos';
      _startDateFilter = null;
      _endDateFilter = null;
      _minAmountFilter = null;
      _maxAmountFilter = null;
      _dateError = null;
    });
  }

  Future<void> _toggleBalance() async {
    if (!_showBalance && _biometricEnabled) {
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Autentique-se para visualizar seu saldo',
      );
      if (!authenticated) return;
    }
    
    setState(() {
      _showBalance = !_showBalance;
    });
  }

  List<TransactionModel> _getFilteredHistory(List<TransactionModel> history) {
    return history.where((item) {
      if (_recipientFilter.isNotEmpty && 
          !item.description.toLowerCase().contains(_recipientFilter.toLowerCase())) {
        return false;
      }
      if (_typeFilter != 'Todos' && item.type != _typeFilter) {
        return false;
      }
      if (_startDateFilter != null && item.date.isBefore(_startDateFilter!)) {
        return false;
      }
      if (_endDateFilter != null && item.date.isAfter(_endDateFilter!.add(const Duration(days: 1)))) {
        return false;
      }
      if (_minAmountFilter != null && item.amount < _minAmountFilter!) {
        return false;
      }
      if (_maxAmountFilter != null && item.amount > _maxAmountFilter!) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _loadCustomizationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showBalance = prefs.getBool('showBalance') ?? true;
      _showTransactions = prefs.getBool('showTransactions') ?? true;
      for (final tipo in _chartTypes) {
        _visibleCharts[tipo] = prefs.getBool('chart_$tipo') ?? true;
      }
    });
  }

  Future<void> _saveCustomizationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showBalance', _showBalance);
    await prefs.setBool('showTransactions', _showTransactions);
    for (final tipo in _chartTypes) {
      await prefs.setBool('chart_$tipo', _visibleCharts[tipo]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);
    final historyAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n('history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showPersonalizationModal(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareOptions(historyAsync.value ?? []),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (history) {
          final filteredHistory = _getFilteredHistory(history);
          final totalSent = history
              .where((t) => t.type == 'debit')
              .fold(0.0, (sum, t) => sum + t.amount);

          return DashboardContent(
            balance: balanceAsync.value ?? 0.0,
            totalSent: totalSent,
            transactionCount: history.length,
            chartType: _chartType,
            chartTypes: _chartTypes,
            onChartTypeChanged: (val) {
              if (val != null) setState(() => _chartType = val);
            },
            chartWidget: _buildChart(history),
            filtersWidget: FiltersWidget(
              recipientFilter: _recipientFilter,
              typeFilter: _typeFilter,
              startDateFilter: _startDateFilter,
              endDateFilter: _endDateFilter,
              minAmountFilter: _minAmountFilter,
              maxAmountFilter: _maxAmountFilter,
              dateError: _dateError,
              onRecipientChanged: (v) => setState(() => _recipientFilter = v),
              onTypeChanged: (v) => setState(() => _typeFilter = v ?? 'Todos'),
              onClearFilters: _clearFilters,
              onStartDatePressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDateFilter ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _startDateFilter = picked;
                    _validateDateFilter();
                  });
                }
              },
              onEndDatePressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDateFilter ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _endDateFilter = picked;
                    _validateDateFilter();
                  });
                }
              },
              onMinAmountChanged: (v) => setState(() => _minAmountFilter = double.tryParse(v)),
              onMaxAmountChanged: (v) => setState(() => _maxAmountFilter = double.tryParse(v)),
            ),
            historyListWidget: HistoryListWidget(
              filteredHistory: filteredHistory,
              displayedItems: _displayedItems,
              loadingMore: _loadingMore,
              onReachEnd: _loadMoreItems,
              formatDate: (d) => DateFormat('dd/MM/yyyy HH:mm').format(d),
            ),
            showTransactions: _showTransactions,
            showBalance: _showBalance,
            onToggleBalance: _toggleBalance,
          );
        },
        loading: () => const ShimmerLoading(),
        error: (err, stack) {
          final isAuthError = err.toString().contains('Sessão expirada') || 
                             err.toString().contains('Unauthorized') ||
                             err.toString().contains('AuthFailure');
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                   Text(
                    isAuthError ? context.l10n('session_expired') : context.l10n('error_loading_data'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(err.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (isAuthError)
                    ElevatedButton.icon(
                       onPressed: () => ref.read(authProvider.notifier).signOut(),
                       icon: const Icon(Icons.logout),
                       label: Text(context.l10n('login_again')),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => ref.refresh(transactionsProvider),
                      child: Text(context.l10n('try_again')),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(List<TransactionModel> history) {
    // Implementação simplificada dos valores por mês para o gráfico
    final now = DateTime.now();
    final monthlyValues = List<double>.filled(6, 0.0);
    
    for (final item in history) {
      final diff = (now.year - item.date.year) * 12 + (now.month - item.date.month);
      if (diff >= 0 && diff < 6) {
        monthlyValues[5 - diff] += item.amount;
      }
    }

    switch (_chartType) {
      case 'Barra':
        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(monthlyValues.length, (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthlyValues[i], 
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                )
              ],
            )),
          ),
        );
      case 'Linha':
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.35,
                preventCurveOverShooting: true,
                spots: List.generate(monthlyValues.length, (i) => FlSpot(i.toDouble(), monthlyValues[i])),
                color: AppColors.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              )
            ],
          ),
        );
      case 'Pizza':
        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: List.generate(monthlyValues.length, (i) => PieChartSectionData(
              value: monthlyValues[i],
              color: Colors.primaries[i % Colors.primaries.length].withValues(alpha: 0.8),
              title: '', // Minimalist: hide titles on pizza
              radius: 50,
            )),
          ),
        );
      default:
        return Center(child: Text(context.l10n('chart_not_available')));
    }
  }

  void _showPersonalizationModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Mostrar Saldo'),
                value: _showBalance,
                onChanged: (v) {
                  setModalState(() => _showBalance = v);
                  setState(() => _showBalance = v);
                },
              ),
              SwitchListTile(
                title: const Text('Mostrar Transações'),
                value: _showTransactions,
                onChanged: (v) {
                  setModalState(() => _showTransactions = v);
                  setState(() => _showTransactions = v);
                },
              ),
              if (_biometricAvailable)
                SwitchListTile(
                  title: const Text('Autenticação Biométrica'),
                  subtitle: const Text('Exigir biometria para ações sensíveis'),
                  value: _biometricEnabled,
                  onChanged: (v) async {
                    final success = await _biometricService.setBiometricEnabled(v);
                    if (success) {
                      setModalState(() => _biometricEnabled = v);
                      setState(() => _biometricEnabled = v);
                    }
                  },
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _saveCustomizationPreferences();
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareOptions(List<TransactionModel> history) {
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há transações para exportar.')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Compartilhar Histórico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Colors.blue),
                title: const Text('Compartilhar como Texto (CSV)'),
                onTap: () async {
                  Navigator.pop(context);
                  if (_biometricEnabled) {
                    final authenticated = await _biometricService.authenticate(
                      localizedReason: 'Autentique-se para exportar seu histórico',
                    );
                    if (!authenticated) return;
                  }
                  _exportCsv(history);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Compartilhar como PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  if (_biometricEnabled) {
                    final authenticated = await _biometricService.authenticate(
                      localizedReason: 'Autentique-se para exportar seu histórico',
                    );
                    if (!authenticated) return;
                  }
                  _exportPdf(history);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportCsv(List<TransactionModel> history) async {
    final csvData = [
      [
        context.l10n('date'),
        context.l10n('pdf_description'),
        context.l10n('value'),
        context.l10n('type')
      ],
      ...history.map((t) => [
            DateFormat('dd/MM/yyyy HH:mm').format(t.date),
            t.description,
            t.amount.toStringAsFixed(2),
            t.type == 'credit' ? context.l10n('credit') : context.l10n('debit')
          ]),
    ];

    final bytes = Uint8List.fromList(
        csvData.map((row) => row.join(',')).join('\n').codeUnits);

    await FileHelper.saveAndShare(
      bytes,
      'historico_${DateTime.now().millisecondsSinceEpoch}.csv',
      subject: context.l10n('share_history_csv_subject'),
      text: context.l10n('share_history_csv_text'),
    );
  }
 
  Future<void> _exportPdf(List<TransactionModel> history) async {
    try {
      final user = ref.read(sessionStateProvider).value;
      final userName = user?.userMetadata?['nome'] ?? context.l10n('default_user_name');
      
      final pdfService = PdfService();
      final l10n = {
        'pdf_history_title': context.l10n('pdf_history_title'),
        'pdf_client': context.l10n('pdf_client'),
        'pdf_issue_date': context.l10n('pdf_issue_date'),
        'date': context.l10n('date'),
        'pdf_description': context.l10n('pdf_description'),
        'type': context.l10n('type'),
        'pdf_value_brl': context.l10n('pdf_value_brl'),
        'credit': context.l10n('credit'),
        'debit': context.l10n('debit'),
      };
      
      final subject = context.l10n('share_history_pdf_subject');
      final text = context.l10n('share_history_pdf_text');
      
      final bytes = await pdfService.generateHistoryPdf(history, userName, l10n);
      
      await FileHelper.saveAndShare(
        bytes,
        'historico_${DateTime.now().millisecondsSinceEpoch}.pdf',
        subject: subject,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n('error_generating_pdf')}: $e')));
      }
    }
  }
}

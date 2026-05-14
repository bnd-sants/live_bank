import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:live_bank/core/utils/csv_utils.dart';
import 'package:live_bank/core/utils/pdf_utils.dart';
import 'package:live_bank/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import '../widgets/dashboard_widgets.dart';

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

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadCustomizationPreferences();
    _initializeNotifications().then((_) => _checkBalanceAndNotify());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await notificationsPlugin.initialize(initSettings);
  }

  Future<void> _checkBalanceAndNotify() async {
    final balance = ref.read(balanceProvider).value ?? 0.0;
    if (balance < 100) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'low_balance',
        'Saldo Baixo',
        channelDescription: 'Notificações de saldo baixo',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
      
      await notificationsPlugin.show(
        0,
        'Atenção: Saldo Baixo',
        'Seu saldo está abaixo de R\$ 100,00. Considere realizar um depósito.',
        notificationDetails,
      );
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
        title: const Text('Histórico e Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showPersonalizationModal(),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: () => _exportCsv(historyAsync.value ?? []),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            onPressed: () => _exportPdf(historyAsync.value ?? []),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar dados: $err')),
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
            barGroups: List.generate(monthlyValues.length, (i) => BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: monthlyValues[i], color: Colors.blue)],
            )),
            titlesData: const FlTitlesData(show: true),
          ),
        );
      case 'Linha':
        return LineChart(
          LineChartData(
            lineBarsData: [LineChartBarData(
              spots: List.generate(monthlyValues.length, (i) => FlSpot(i.toDouble(), monthlyValues[i])),
              color: Colors.green,
            )],
          ),
        );
      case 'Pizza':
        return PieChart(
          PieChartData(
            sections: List.generate(monthlyValues.length, (i) => PieChartSectionData(
              value: monthlyValues[i],
              color: Colors.primaries[i % Colors.primaries.length],
              title: monthlyValues[i] > 0 ? 'M${i+1}' : '',
            )),
          ),
        );
      default:
        return const Center(child: Text('Gráfico não disponível'));
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

  Future<void> _exportCsv(List<TransactionModel> history) async {
    final csvData = history.map((t) => {
      'id': t.id,
      'description': t.description,
      'amount': t.amount,
      'date': t.date.toIso8601String(),
      'type': t.type,
    }).toList();
    final csv = CsvUtils.toCsv(csvData);
    await Share.share(csv, subject: 'Histórico Live Bank');
  }

  Future<void> _exportPdf(List<TransactionModel> history) async {
    final csvData = history.map((t) => {
      'id': t.id,
      'description': t.description,
      'amount': t.amount,
      'date': t.date.toIso8601String(),
      'type': t.type,
    }).toList();
    try {
      final pdfBytes = await PdfUtils.toPdf(csvData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/historico_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], subject: 'Histórico Live Bank PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    }
  }
}

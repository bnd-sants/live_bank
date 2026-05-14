import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:live_bank/features/investments/presentation/providers/investments_provider.dart';
import 'package:live_bank/features/investments/domain/models/investment_model.dart';
import 'package:live_bank/widgets/currency_card.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String? _selectedAsset;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Investimentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Mercado'),
            Tab(text: 'Minha Carteira'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketTab(),
          _buildPortfolioTab(),
        ],
      ),
    );
  }

  Widget _buildMarketTab() {
    final quotesAsync = ref.watch(quotesProvider);
    final historyAsync = ref.watch(exchangeHistoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(quotesProvider);
        ref.invalidate(exchangeHistoryProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Resumo do Mercado',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          quotesAsync.when(
            data: (quotes) => Column(
              children: quotes.entries.map((entry) {
                final isSelected = _selectedAsset == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAsset = entry.key),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CurrencyCard(
                      currencyName: _getAssetName(entry.key),
                      currencyCode: entry.key,
                      amount: _currencyFormat.format(entry.value),
                      convertedAmount: 'Variação 24h: +1.2%', // Mock variation
                      icon: _getAssetIcon(entry.key),
                      color: isSelected ? AppColors.primary : AppColors.secondary,
                      isLoading: false,
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Erro ao carregar cotações: $err', style: const TextStyle(color: AppColors.error)),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedAsset != null) ...[
            Text(
              'Histórico - ${_getAssetName(_selectedAsset!)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (history) {
                final assetHistory = history[_selectedAsset];
                if (assetHistory == null || assetHistory.isEmpty) {
                  return const Center(child: Text('Nenhum histórico disponível', style: TextStyle(color: AppColors.textSecondary)));
                }
                return Container(
                  height: 200,
                  padding: const EdgeInsets.only(right: 16, top: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildChart(assetHistory),
                );
              },
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => Text('Erro no gráfico: $err', style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    final investmentsAsync = ref.watch(investmentsProvider);

    return investmentsAsync.when(
      data: (investments) {
        if (investments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Você ainda não possui investimentos',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Explorar Mercado'),
                ),
              ],
            ),
          );
        }

        final totalValue = investments.fold<double>(0, (sum, inv) => sum + inv.amount);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPortfolioSummary(totalValue),
            const SizedBox(height: 24),
            const Text(
              'Meus Ativos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...investments.map((inv) => _buildInvestmentCard(inv)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err', style: const TextStyle(color: AppColors.error))),
    );
  }

  Widget _buildPortfolioSummary(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patrimônio Total',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text(
                '+R\$ 450,00 (2.5%)',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Mês atual',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(InvestmentModel investment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getAssetIcon(investment.assetName), color: AppColors.primary),
        ),
        title: Text(
          investment.assetName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Qtde: ${investment.amount.toStringAsFixed(4)}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currencyFormat.format(investment.amount * investment.currentYield), // Simplified
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '+${investment.currentYield}%',
              style: const TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<MapEntry<DateTime, double>> history) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: history.length.toDouble() - 1,
        minY: history.map((e) => e.value).reduce((a, b) => a < b ? a : b) * 0.99,
        maxY: history.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.01,
        lineBarsData: [
          LineChartBarData(
            spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _getAssetName(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return 'Dólar Americano';
      case 'EUR': return 'Euro';
      case 'BTC': return 'Bitcoin';
      case 'ETH': return 'Ethereum';
      default: return code;
    }
  }

  IconData _getAssetIcon(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return Icons.attach_money;
      case 'EUR': return Icons.euro;
      case 'BTC': return Icons.currency_bitcoin;
      case 'ETH': return Icons.token;
      default: return Icons.trending_up;
    }
  }
}

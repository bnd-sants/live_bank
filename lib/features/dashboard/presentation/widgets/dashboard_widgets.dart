import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:live_bank/features/transactions/presentation/screens/receipt_screen.dart';
import 'package:live_bank/core/utils/categorization_utils.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class DashboardContent extends StatelessWidget {
  final double balance;
  final double totalSent;
  final int transactionCount;
  final String chartType;
  final List<String> chartTypes;
  final Function(String?) onChartTypeChanged;
  final Widget chartWidget;
  final Widget filtersWidget;
  final Widget historyListWidget;
  final bool showTransactions;

  const DashboardContent({
    super.key,
    required this.balance,
    required this.totalSent,
    required this.transactionCount,
    required this.chartType,
    required this.chartTypes,
    required this.onChartTypeChanged,
    required this.chartWidget,
    required this.filtersWidget,
    required this.historyListWidget,
    required this.showTransactions,
    this.showBalance = true,
    this.onToggleBalance,
  });

  final bool showBalance;
  final VoidCallback? onToggleBalance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        GestureDetector(
          onTap: onToggleBalance,
          child: _buildInfoCard(
            title: context.l10n('current_balance'),
            value: showBalance 
                ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(balance)
                : '••••••',
            valueStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
            icon: showBalance ? Icons.visibility : Icons.visibility_off,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: context.l10n('total_sent'),
                value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalSent),
                valueStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                icon: Icons.arrow_upward,
                iconColor: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                title: context.l10n('transactions'),
                value: transactionCount.toString(),
                valueStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                icon: Icons.history,
                iconColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildChartSection(context),
        if (showTransactions) ...[
          const SizedBox(height: 32),
          Text(context.l10n('transaction_history'), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          filtersWidget,
          const SizedBox(height: 16),
          historyListWidget,
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required TextStyle valueStyle,
    IconData? icon,
    Color? iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                if (icon != null) Icon(icon, size: 16, color: iconColor ?? Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n('financial_summary'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: chartType,
                      items: chartTypes
                          .map((tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ))
                          .toList(),
                      onChanged: onChartTypeChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: chartWidget,
            ),
          ],
        ),
      ),
    );
  }
}

class FiltersWidget extends StatelessWidget {
  final String recipientFilter;
  final String typeFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final double? minAmountFilter;
  final double? maxAmountFilter;
  final String? dateError;
  final Function(String) onRecipientChanged;
  final Function(String?) onTypeChanged;
  final Function() onClearFilters;
  final Function() onStartDatePressed;
  final Function() onEndDatePressed;
  final Function(String) onMinAmountChanged;
  final Function(String) onMaxAmountChanged;

  const FiltersWidget({
    super.key,
    required this.recipientFilter,
    required this.typeFilter,
    required this.startDateFilter,
    required this.endDateFilter,
    required this.minAmountFilter,
    required this.maxAmountFilter,
    required this.dateError,
    required this.onRecipientChanged,
    required this.onTypeChanged,
    required this.onClearFilters,
    required this.onStartDatePressed,
    required this.onEndDatePressed,
    required this.onMinAmountChanged,
    required this.onMaxAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTextField(
            width: 200,
            label: context.l10n('search'),
            icon: Icons.search,
            onChanged: onRecipientChanged,
          ),
          const SizedBox(width: 12),
          _buildDropdownField(context),
          const SizedBox(width: 12),
          _buildDateField(
            label: context.l10n('start_date'),
            value: startDateFilter,
            onTap: onStartDatePressed,
          ),
          const SizedBox(width: 12),
          _buildDateField(
            label: context.l10n('end_date'),
            value: endDateFilter,
            onTap: onEndDatePressed,
          ),
          const SizedBox(width: 12),
          _buildAmountField(
            label: context.l10n('min'),
            onChanged: onMinAmountChanged,
          ),
          const SizedBox(width: 12),
          _buildAmountField(
            label: context.l10n('max'),
            onChanged: onMaxAmountChanged,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list_off, color: Colors.redAccent),
            tooltip: context.l10n('clear_filters'),
            onPressed: onClearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required double width,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    return SizedBox(
      width: 130,
      child: DropdownButtonFormField<String>(
        initialValue: typeFilter,
        decoration: InputDecoration(
          labelText: context.l10n('type'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: ['Todos', 'credit', 'debit']
            .map((tipo) => DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo == 'credit' ? context.l10n('credit') : (tipo == 'debit' ? context.l10n('debit') : context.l10n('all'))),
                ))
            .toList(),
        onChanged: onTypeChanged,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 130,
      child: TextField(
        readOnly: true,
        controller: TextEditingController(
            text: value != null ? DateFormat('dd/MM/yy').format(value) : ''),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAmountField({
    required String label,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      width: 110,
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          prefixText: 'R\$ ',
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class HistoryListWidget extends StatelessWidget {
  final List<TransactionModel> filteredHistory;
  final int displayedItems;
  final bool loadingMore;
  final Function() onReachEnd;
  final Function(DateTime) formatDate;

  const HistoryListWidget({
    super.key,
    required this.filteredHistory,
    required this.displayedItems,
    required this.loadingMore,
    required this.onReachEnd,
    required this.formatDate,
    this.onTransactionTap,
  });

  final Function(TransactionModel)? onTransactionTap;

  @override
  Widget build(BuildContext context) {
    if (filteredHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text(context.l10n('no_transactions_found'))),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedItems < filteredHistory.length
          ? displayedItems + 1
          : filteredHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index < displayedItems && index < filteredHistory.length) {
          final item = filteredHistory[index];
          final isCredit = item.type == 'credit';
          final category = CategorizationUtils.categorize(item.description);

          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              onTap: () {
                if (onTransactionTap != null) {
                  onTransactionTap!(item);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptScreen(
                        destinatario: item.description,
                        valorEmReais: item.amount,
                        moeda: 'BRL',
                        valorOriginal: item.amount,
                        data: formatDate(item.date),
                        transactionId: item.id,
                      ),
                    ),
                  );
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isCredit ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.icon,
                  color: isCredit ? Colors.green : Colors.blue,
                  size: 20,
                ),
              ),
              title: Text(
                item.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${context.l10n('cat_${category.name}')} • ${formatDate(item.date)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              trailing: Text(
                '${isCredit ? '+' : '-'} ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(item.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        } else if (loadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextButton(
              onPressed: onReachEnd,
              child: Text(context.l10n('load_more')),
            ),
          );
        }
      },
    );
  }
}

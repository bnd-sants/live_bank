import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildInfoCard(
          title: 'Saldo atual',
          value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(balance),
          valueStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'Total enviado',
                value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalSent),
                valueStyle: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                title: 'Transações',
                value: transactionCount.toString(),
                valueStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildChartSection(),
        if (showTransactions) ...[
          const SizedBox(height: 32),
          const Text('Histórico de transações:', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
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
                const Text(
                  'Resumo financeiro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            label: 'Buscar',
            icon: Icons.search,
            onChanged: onRecipientChanged,
          ),
          const SizedBox(width: 12),
          _buildDropdownField(),
          const SizedBox(width: 12),
          _buildDateField(
            label: 'Início',
            value: startDateFilter,
            onTap: onStartDatePressed,
          ),
          const SizedBox(width: 12),
          _buildDateField(
            label: 'Fim',
            value: endDateFilter,
            onTap: onEndDatePressed,
          ),
          const SizedBox(width: 12),
          _buildAmountField(
            label: 'Mín.',
            onChanged: onMinAmountChanged,
          ),
          const SizedBox(width: 12),
          _buildAmountField(
            label: 'Máx.',
            onChanged: onMaxAmountChanged,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list_off, color: Colors.redAccent),
            tooltip: 'Limpar filtros',
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

  Widget _buildDropdownField() {
    return SizedBox(
      width: 130,
      child: DropdownButtonFormField<String>(
        value: typeFilter,
        decoration: InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: ['Todos', 'credit', 'debit']
            .map((tipo) => DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo == 'credit' ? 'Crédito' : (tipo == 'debit' ? 'Débito' : 'Todos')),
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
  });

  @override
  Widget build(BuildContext context) {
    if (filteredHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('Nenhuma transação encontrada.')),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayedItems < filteredHistory.length
            ? displayedItems + 1
            : filteredHistory.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index < displayedItems && index < filteredHistory.length) {
            final item = filteredHistory[index];
            final isCredit = item.type == 'credit';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                item.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                formatDate(item.date),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              trailing: Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(item.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            );
          } else if (loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            return TextButton(
              onPressed: onReachEnd,
              child: const Text('Carregar mais'),
            );
          }
        },
      ),
    );
  }
}

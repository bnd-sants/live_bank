import 'package:flutter/material.dart';
import 'package:live_bank/core/theme/app_colors.dart';

class ReceiptScreen extends StatelessWidget {
  final String destinatario;
  final double valorEmReais;
  final String moeda;
  final double valorOriginal;
  final String? data;

  const ReceiptScreen({
    super.key,
    required this.destinatario,
    required this.valorEmReais,
    required this.moeda,
    required this.valorOriginal,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comprovante'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Pagamento Confirmado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColors.grey100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Destinatário', destinatario),
                  const Divider(height: 32),
                  _buildDetailRow('Valor', 'R\$ ${valorEmReais.toStringAsFixed(2)}'),
                  if (moeda != 'BRL') ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Valor Original', '$moeda ${valorOriginal.toStringAsFixed(2)}'),
                  ],
                  const Divider(height: 32),
                  _buildDetailRow('Data e Hora', data ?? 'Agora'),
                  const Divider(height: 32),
                  _buildDetailRow('ID da Transação', 'LB-${DateTime.now().millisecondsSinceEpoch}'),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Compartilhamento em breve!')),
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.black),
                    label: const Text('Compartilhar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500])),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

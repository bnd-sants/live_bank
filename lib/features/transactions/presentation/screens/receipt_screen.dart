import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/theme/app_colors.dart';
import 'package:live_bank/services/pdf_service.dart';
import 'package:live_bank/core/utils/file_helper.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:live_bank/core/providers/supabase_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:live_bank/features/transactions/presentation/widgets/visual_receipt_card.dart';
import 'package:live_bank/core/l10n/app_localizations.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final String destinatario;
  final double valorEmReais;
  final String moeda;
  final double valorOriginal;
  final String? data;
  final String? transactionId;

  const ReceiptScreen({
    super.key,
    required this.destinatario,
    required this.valorEmReais,
    required this.moeda,
    required this.valorOriginal,
    this.data,
    this.transactionId,
  });

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _isSharing = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareAsImage() async {
    setState(() => _isSharing = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      final senderName = user?.userMetadata?['nome'] ?? context.l10n('default_user_name');
      final transactionId = widget.transactionId ?? 'LB-${DateTime.now().millisecondsSinceEpoch}';

      final subject = context.l10n('share_receipt_subject');
      final text = context.l10n('share_receipt_text');

      final image = await _screenshotController.captureFromWidget(
        VisualReceiptCard(
          destinatario: widget.destinatario,
          valor: widget.valorEmReais,
          transactionId: transactionId,
          data: widget.data ?? context.l10n('now'),
          senderName: senderName,
        ),
        delay: const Duration(milliseconds: 100),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/comprovante_$transactionId.png');
      await file.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          subject: subject,
          text: text,
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n('error_generating_image')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _generateAndShareReceipt() async {
    setState(() => _isSharing = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      final senderName = user?.userMetadata?['nome'] ?? context.l10n('default_user_name');

      final transactionId = widget.transactionId ?? 'LB-${DateTime.now().millisecondsSinceEpoch}';

      final transaction = TransactionModel(
        id: transactionId,
        description: widget.destinatario,
        amount: widget.valorEmReais,
        date: widget.data != null ? DateTime.tryParse(widget.data!) ?? DateTime.now() : DateTime.now(),
        type: 'debit', // assuming debit for transfer
      );

      final pdfService = PdfService();
      final l10n = {
        'pdf_receipt_title': context.l10n('pdf_receipt_title'),
        'pdf_auth': context.l10n('pdf_auth'),
        'pdf_transaction_value': context.l10n('pdf_transaction_value'),
        'pdf_details_title': context.l10n('pdf_details_title'),
        'from': context.l10n('from'),
        'to': context.l10n('to'),
        'pdf_op_type': context.l10n('pdf_op_type'),
        'pdf_received': context.l10n('pdf_received'),
        'pdf_sent': context.l10n('pdf_sent'),
        'pdf_control_id': context.l10n('pdf_control_id'),
        'pdf_disclaimer': context.l10n('pdf_disclaimer'),
        'pdf_security_note': context.l10n('pdf_security_note'),
      };
      
      final subject = context.l10n('share_receipt_pdf_subject');
      final text = context.l10n('share_receipt_pdf_text');

      final bytes = await pdfService.generateReceipt(transaction, senderName, l10n);

      await FileHelper.saveAndShare(
        bytes,
        'comprovante_$transactionId.pdf',
        subject: subject,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n('error_generating_pdf')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionId = widget.transactionId ?? 'LB-${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n('receipt')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              context.l10n('payment_confirmed'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColors.grey100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context.l10n('recipient'), widget.destinatario),
                  const Divider(height: 32),
                  _buildDetailRow(context.l10n('amount'), 'R\$ ${widget.valorEmReais.toStringAsFixed(2)}'),
                  if (widget.moeda != 'BRL') ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(context.l10n('original_value'), '${widget.moeda} ${widget.valorOriginal.toStringAsFixed(2)}'),
                  ],
                  const Divider(height: 32),
                  _buildDetailRow(context.l10n('date_time'), widget.data ?? context.l10n('now')),
                  const Divider(height: 32),
                  _buildDetailRow(context.l10n('transaction_id'), transactionId),
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
                    label: Text(context.l10n('back')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareAsImage,
                    icon: _isSharing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.share, color: Colors.black),
                    label: Text(context.l10n('send_image')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSharing ? null : _generateAndShareReceipt,
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

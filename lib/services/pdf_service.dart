import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<Uint8List> generateReceipt(
    TransactionModel transaction, 
    String userName, 
    Map<String, String> l10n,
  ) async {
    final pdf = pw.Document();

    // Carrega a fonte Roboto dos assets
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final isCredit = transaction.type == 'credit';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 4,
                width: double.infinity,
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF00D1FF),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('LIVE BANK', style: pw.TextStyle(font: ttf, fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00D1FF))),
                      pw.Text(l10n['pdf_receipt_title'] ?? '', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(dateFormat.format(transaction.date), style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
                      pw.Text('${l10n['pdf_auth']}: ${transaction.id.hashCode.toRadixString(16).toUpperCase()}', style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColor.fromInt(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 50),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8FAFC),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(l10n['pdf_transaction_value'] ?? '', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColor.fromInt(0xFF64748B))),
                      pw.SizedBox(height: 8),
                      pw.Text('R\$ ${transaction.amount.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 50),
              pw.Text(l10n['pdf_details_title'] ?? '', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF64748B))),
              pw.SizedBox(height: 10),
              _buildPdfRow(ttf, isCredit ? (l10n['from'] ?? '') : (l10n['to'] ?? ''), transaction.description),
              pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5),
              _buildPdfRow(ttf, isCredit ? (l10n['to'] ?? '') : (l10n['from'] ?? ''), userName),
              pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5),
              _buildPdfRow(ttf, l10n['pdf_op_type'] ?? '', isCredit ? (l10n['pdf_received'] ?? '') : (l10n['pdf_sent'] ?? '')),
              pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5),
              _buildPdfRow(ttf, l10n['pdf_control_id'] ?? '', transaction.id),
              pw.SizedBox(height: 80),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(l10n['pdf_disclaimer'] ?? '', 
                      style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColor.fromInt(0xFF94A3B8))),
                    pw.SizedBox(height: 4),
                    pw.Text(l10n['pdf_security_note'] ?? '', 
                      style: pw.TextStyle(font: ttf, fontSize: 7, color: PdfColor.fromInt(0xFFCBD5E1))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildPdfRow(pw.Font font, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 12, color: PdfColor.fromInt(0xFF64748B))),
          pw.Flexible(
            child: pw.Text(value, 
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> generateHistoryPdf(
    List<TransactionModel> history, 
    String userName,
    Map<String, String> l10n,
  ) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    // Add a summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('LIVE BANK', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00D1FF))),
              pw.Text(l10n['pdf_history_title'] ?? '', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
              pw.SizedBox(height: 40),
              pw.Text('${l10n['pdf_client']}: $userName', style: pw.TextStyle(font: ttf, fontSize: 14)),
              pw.Text('${l10n['pdf_issue_date']}: ${dateFormat.format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.SizedBox(height: 40),
              pw.TableHelper.fromTextArray(
                headers: [
                  l10n['date'] ?? '', 
                  l10n['pdf_description'] ?? '', 
                  l10n['type'] ?? '', 
                  l10n['pdf_value_brl'] ?? ''
                ],
                data: history.map((t) => [
                  dateFormat.format(t.date),
                  t.description,
                  t.type == 'credit' ? (l10n['credit'] ?? '') : (l10n['debit'] ?? ''),
                  t.amount.toStringAsFixed(2)
                ]).toList(),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                headerStyle: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFFFFFFF)),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00D1FF)),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)))),
              ),
            ],
          ),
        ),
      ),
    );

    return await pdf.save();
  }
}

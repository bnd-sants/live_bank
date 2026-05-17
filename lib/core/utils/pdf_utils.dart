import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;


class PdfUtils {
  /// Gera um arquivo PDF a partir de uma lista de mapas (histórico), usando fonte Roboto para suporte Unicode.
  static Future<Uint8List> toPdf(List<Map<String, dynamic>> data,
      {List<String>? headers}) async {
    final pdf = pw.Document();
    final keys = headers ?? (data.isNotEmpty ? data.first.keys.toList() : []);

    // Carrega a fonte Roboto dos assets
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Se for recibo de transferência (possui campos típicos)
    final isTransferencia = data.isNotEmpty && (
      data.first.containsKey('remetente') ||
      data.first.containsKey('destinatario') ||
      data.first.containsKey('valor')
    );

    if (isTransferencia) {
      // Gera recibo bonito para cada transferência
      for (final row in data) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('LIVE BANK', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00D1FF))),
                          pw.Text('Comprovante de Transferência', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
                        ],
                      ),
                      pw.Text(row['data'] ?? 'N/A', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
                    ],
                  ),
                  pw.SizedBox(height: 60),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text('Valor', style: pw.TextStyle(font: ttf, fontSize: 14, color: PdfColor.fromInt(0xFF64748B))),
                        pw.SizedBox(height: 8),
                        pw.Text('R\$ ${row['valor']}', style: pw.TextStyle(font: ttf, fontSize: 42, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 60),
                  _buildPdfRow(ttf, 'Destinatário', row['destinatario'] ?? 'N/A'),
                  pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 1),
                  _buildPdfRow(ttf, 'Remetente', row['remetente'] ?? 'N/A'),
                  pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 1),
                  _buildPdfRow(ttf, 'ID da Transação', row['id'] ?? 'N/A'),
                  pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 1),
                  pw.SizedBox(height: 100),
                  pw.Center(
                    child: pw.Text('Este comprovante é válido como documento fiscal.', 
                      style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColor.fromInt(0xFF94A3B8))),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      // Mantém tabela padrão para outros usos
      pdf.addPage(
        pw.Page(
          build: (context) => pw.TableHelper.fromTextArray( 
            headers: keys,
            data: data
                .map((row) => keys.map((k) => row[k]?.toString() ?? '').toList())
                .toList(),
            cellStyle: pw.TextStyle(font: ttf),
            headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }
    return pdf.save();
  }

  static pw.Widget _buildPdfRow(pw.Font font, String label, String value) {
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
}

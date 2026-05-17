import 'package:live_bank/core/utils/categorization_utils.dart';

class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'credit' ou 'debit'
  final String? category;

  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final description = json['description'] ?? json['descricao'] ?? 'Sem descrição';
    final category = json['category'] ?? CategorizationUtils.categorize(description).label;

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      description: description,
      amount: (json['amount'] ?? json['valor'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['data'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? (json['is_debit'] == true ? 'debit' : 'credit'),
      category: category,
    );
  }
}

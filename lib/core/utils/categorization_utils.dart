import 'package:flutter/material.dart';

enum TransactionCategory {
  food('Alimentação', Icons.restaurant),
  shopping('Compras', Icons.shopping_bag),
  health('Saúde', Icons.medical_services),
  transport('Transporte', Icons.directions_car),
  entertainment('Lazer', Icons.movie),
  services('Serviços', Icons.build),
  investment('Investimentos', Icons.trending_up),
  transfer('Transferência', Icons.swap_horiz),
  others('Outros', Icons.more_horiz);

  final String label;
  final IconData icon;
  const TransactionCategory(this.label, this.icon);
}

class CategorizationUtils {
  static TransactionCategory categorize(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('mercado') || desc.contains('supermercado') || desc.contains('ifood') || desc.contains('restaurante') || desc.contains('padaria')) {
      return TransactionCategory.food;
    }
    if (desc.contains('loja') || desc.contains('amazon') || desc.contains('mercadolivre') || desc.contains('shopee')) {
      return TransactionCategory.shopping;
    }
    if (desc.contains('farmacia') || desc.contains('hospital') || desc.contains('medico') || desc.contains('clinica')) {
      return TransactionCategory.health;
    }
    if (desc.contains('uber') || desc.contains('99') || desc.contains('posto') || desc.contains('combustivel')) {
      return TransactionCategory.transport;
    }
    if (desc.contains('netflix') || desc.contains('spotify') || desc.contains('cinema') || desc.contains('show')) {
      return TransactionCategory.entertainment;
    }
    if (desc.contains('luz') || desc.contains('agua') || desc.contains('aluguel') || desc.contains('internet') || desc.contains('servico')) {
      return TransactionCategory.services;
    }
    if (desc.contains('investimento') || desc.contains('corretora') || desc.contains('bolsa')) {
      return TransactionCategory.investment;
    }
    if (desc.contains('transferencia') || desc.contains('pix') || desc.contains('envio')) {
      return TransactionCategory.transfer;
    }

    return TransactionCategory.others;
  }
}

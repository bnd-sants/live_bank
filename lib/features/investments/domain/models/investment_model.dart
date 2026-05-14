class InvestmentModel {
  final String id;
  final String assetType;
  final String assetName;
  final double amount;
  final double purchasePrice;
  final DateTime purchaseDate;
  final double currentYield;

  InvestmentModel({
    required this.id,
    required this.assetType,
    required this.assetName,
    required this.amount,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.currentYield,
  });

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'],
      assetType: json['asset_type'],
      assetName: json['asset_name'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      purchasePrice: (json['purchase_price'] ?? 0.0).toDouble(),
      purchaseDate: DateTime.parse(json['purchase_date']),
      currentYield: (json['current_yield'] ?? 0.0).toDouble(),
    );
  }
}

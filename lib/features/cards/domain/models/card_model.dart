enum CardType { virtual, physical }

class CardModel {
  final String id;
  final String userId;
  final String lastFour;
  final String holderName;
  final CardType type;
  final bool isLocked;
  final String cvv;
  final String expiryDate;
  final String? label;

  CardModel({
    required this.id,
    required this.userId,
    required this.lastFour,
    required this.holderName,
    required this.type,
    required this.isLocked,
    required this.cvv,
    required this.expiryDate,
    this.label,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'],
      userId: json['user_id'],
      lastFour: json['last_four'],
      holderName: json['holder_name'],
      type: json['card_type'] == 'virtual' ? CardType.virtual : CardType.physical,
      isLocked: json['is_locked'] ?? false,
      cvv: json['cvv'],
      expiryDate: json['expiry_date'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'last_four': lastFour,
      'holder_name': holderName,
      'card_type': type.name,
      'is_locked': isLocked,
      'cvv': cvv,
      'expiry_date': expiryDate,
      'label': label,
    };
  }

  CardModel copyWith({
    String? id,
    String? userId,
    String? lastFour,
    String? holderName,
    CardType? type,
    bool? isLocked,
    String? cvv,
    String? expiryDate,
    String? label,
  }) {
    return CardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lastFour: lastFour ?? this.lastFour,
      holderName: holderName ?? this.holderName,
      type: type ?? this.type,
      isLocked: isLocked ?? this.isLocked,
      cvv: cvv ?? this.cvv,
      expiryDate: expiryDate ?? this.expiryDate,
      label: label ?? this.label,
    );
  }
}

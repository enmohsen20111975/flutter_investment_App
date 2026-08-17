// ============================================================================
// مساعد الاستثمار Flutter - Price Alert Model
// ============================================================================

class PriceAlert {
  final String id;
  final String symbol;
  final String companyName;
  final double targetPrice;
  final String condition; // 'ABOVE', 'BELOW'
  final bool isActive;
  final DateTime createdAt;
  final String? note;

  PriceAlert({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.targetPrice,
    required this.condition,
    this.isActive = true,
    required this.createdAt,
    this.note,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: json['symbol'] ?? json['ticker'] ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? json['symbol'] ?? '',
      targetPrice: (json['target_price'] ?? json['price'] as num?)?.toDouble() ?? 0.0,
      condition: json['condition'] ?? (json['type'] == 'stop_loss' ? 'BELOW' : 'ABOVE'),
      isActive: json['is_active'] ?? json['active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'company_name': companyName,
        'target_price': targetPrice,
        'condition': condition,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'note': note,
      };
}

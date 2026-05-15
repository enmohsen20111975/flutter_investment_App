// ============================================================================
// مساعد الاستثمار Flutter - Crypto Types
// ============================================================================

import 'json_helpers.dart';

class CryptoAsset {
  final String id;
  final String symbol;
  final String name;
  final String? image;
  final double? currentPrice;
  final int? marketCapRank;
  final double? priceChangePercentage24h;
  final double? priceChangePercentage7d;
  final double? totalVolume;
  final double? marketCap;
  final List<double>? sparkline7d;
  
  CryptoAsset({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    this.currentPrice,
    this.marketCapRank,
    this.priceChangePercentage24h,
    this.priceChangePercentage7d,
    this.totalVolume,
    this.marketCap,
    this.sparkline7d
  });
  
  factory CryptoAsset.fromJson(Map<String, dynamic> json) => CryptoAsset(
        id: json['id'] ?? '',
        symbol: json['symbol'] ?? '',
        name: json['name'] ?? '',
        image: json['image'],
        currentPrice: parseDouble(json['current_price']),
        marketCapRank: parseInt(json['market_cap_rank']),
        priceChangePercentage24h: parseDouble(json['price_change_percentage_24h']),
        priceChangePercentage7d: parseDouble(json['price_change_percentage_7d_in_currency']),
        totalVolume: parseDouble(json['total_volume']),
        marketCap: parseDouble(json['market_cap']),
        sparkline7d: _parseSparkline(json['sparkline_in_7d']),
      );

  static List<double>? _parseSparkline(dynamic value) {
    if (value == null) return null;
    // Handle array format
    if (value is List) {
      return value.map((e) => parseDouble(e)).where((e) => e != null).cast<double>().toList();
    }
    // Handle object with 'price' key (CoinGecko standard format)
    if (value is Map) {
      final priceData = value['price'];
      if (priceData is List) {
        return priceData.map((e) => parseDouble(e)).where((e) => e != null).cast<double>().toList();
      }
    }
    // Handle space-separated string format
    if (value is String && value.isNotEmpty) {
      return value.split(' ')
          .map((s) => double.tryParse(s.trim()))
          .where((e) => e != null)
          .cast<double>()
          .toList();
    }
    return null;
  }
}
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
        id: json['id'] ?? json['symbol'] ?? '',
        symbol: json['symbol'] ?? '',
        name: json['name'] ?? '',
        image: json['image'] ?? json['logo_url'],
        // FIX: API returns 'price_usd' not 'current_price'
        currentPrice: parseDouble(json['current_price'] ?? json['price_usd'] ?? json['price']),
        marketCapRank: parseInt(json['market_cap_rank'] ?? json['rank']),
        // FIX: API returns 'change_24h' not 'price_change_percentage_24h'
        priceChangePercentage24h: parseDouble(json['price_change_percentage_24h'] ?? json['change_24h'] ?? json['change_percentage_24h']),
        priceChangePercentage7d: parseDouble(json['price_change_percentage_7d_in_currency'] ?? json['change_7d'] ?? json['change_percentage_7d']),
        totalVolume: parseDouble(json['total_volume'] ?? json['volume_24h']),
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
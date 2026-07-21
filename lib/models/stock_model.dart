// ============================================================================
// مساعد الاستثمار Flutter - Stock Model
// Typed stock data model with fromJson/toJson
// ============================================================================

import 'json_helpers.dart';

class StockModel {
  final String ticker;
  final String? name;
  final String? nameAr;
  final String? sector;
  final String? industry;
  final double? currentPrice;
  final double? previousClose;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final double? priceChange;
  final double? changePercent;
  final int? volume;
  final double? marketCap;
  final double? peRatio;
  final double? pbRatio;
  final double? dividendYield;
  final double? rsi;
  final double? ma50;
  final double? ma200;
  final double? supportLevel;
  final double? resistanceLevel;
  final bool? egx30Member;
  final bool? egx70Member;
  final bool? egx100Member;
  final String? lastUpdate;

  StockModel({
    required this.ticker,
    this.name,
    this.nameAr,
    this.sector,
    this.industry,
    this.currentPrice,
    this.previousClose,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.priceChange,
    this.changePercent,
    this.volume,
    this.marketCap,
    this.peRatio,
    this.pbRatio,
    this.dividendYield,
    this.rsi,
    this.ma50,
    this.ma200,
    this.supportLevel,
    this.resistanceLevel,
    this.egx30Member,
    this.egx70Member,
    this.egx100Member,
    this.lastUpdate,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) => StockModel(
        ticker: json['ticker'] ?? json['symbol'] ?? '',
        name: json['name']?.toString(),
        nameAr: json['name_ar']?.toString(),
        sector: json['sector']?.toString(),
        industry: json['industry']?.toString(),
        currentPrice: _toDouble(json['current_price'] ?? json['price']),
        previousClose: _toDouble(json['previous_close']),
        openPrice: _toDouble(json['open_price'] ?? json['open']),
        highPrice: _toDouble(json['high_price'] ?? json['high']),
        lowPrice: _toDouble(json['low_price'] ?? json['low']),
        priceChange: _toDouble(json['price_change'] ?? json['change']),
        changePercent: _toDouble(json['change_percent'] ?? json['change_percent']),
        volume: _toInt(json['volume']),
        marketCap: _toDouble(json['market_cap']),
        peRatio: _toDouble(json['pe_ratio']),
        pbRatio: _toDouble(json['pb_ratio']),
        dividendYield: _toDouble(json['dividend_yield']),
        rsi: _toDouble(json['rsi']),
        ma50: _toDouble(json['ma_50']),
        ma200: _toDouble(json['ma_200']),
        supportLevel: _toDouble(json['support_level']),
        resistanceLevel: _toDouble(json['resistance_level']),
        egx30Member: _toBool(json['egx30_member']),
        egx70Member: _toBool(json['egx70_member']),
        egx100Member: _toBool(json['egx100_member']),
        lastUpdate: json['last_update']?.toString() ?? json['last_updated']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'name_ar': nameAr,
        'sector': sector,
        'industry': industry,
        'current_price': currentPrice,
        'previous_close': previousClose,
        'open_price': openPrice,
        'high_price': highPrice,
        'low_price': lowPrice,
        'price_change': priceChange,
        'change_percent': changePercent,
        'volume': volume,
        'market_cap': marketCap,
        'pe_ratio': peRatio,
        'pb_ratio': pbRatio,
        'dividend_yield': dividendYield,
        'rsi': rsi,
        'ma_50': ma50,
        'ma_200': ma200,
        'support_level': supportLevel,
        'resistance_level': resistanceLevel,
        'egx30_member': egx30Member,
        'egx70_member': egx70Member,
        'egx100_member': egx100Member,
        'last_update': lastUpdate,
      };

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value != 0;
    return null;
  }

  String get displayName => nameAr ?? name ?? ticker;
  bool get isPositive => (changePercent ?? 0) >= 0;
}

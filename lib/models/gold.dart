// ============================================================================
// مساعد الاستثمار Flutter - Gold & Currency Types
// ============================================================================

import 'json_helpers.dart';

// Gold Price
class GoldPrice {
  final String key;
  final String nameAr;
  final double pricePerGram;
  final double? change;
  final String? currency;
  
  GoldPrice({required this.key, required this.nameAr, required this.pricePerGram, this.change, this.currency});
  
  factory GoldPrice.fromJson(Map<String, dynamic> json) => GoldPrice(
        key: json['key'] ?? '',
        nameAr: json['name_ar'] ?? '',
        pricePerGram: parseDouble(json['price_per_gram']) ?? 0,
        change: parseDouble(json['change']),
        currency: json['currency'],
      );
}

// Gold Response
class GoldResponse {
  final bool success;
  final String? source;
  final String? fetchedAt;
  final String? lastUpdated;
  final bool? isLive;
  final GoldPrices? prices;
  
  GoldResponse({required this.success, this.source, this.fetchedAt, this.lastUpdated, this.isLive, this.prices});
  
  factory GoldResponse.fromJson(Map<String, dynamic> json) => GoldResponse(
        success: parseBool(json['success']) ?? false,
        source: json['source'],
        fetchedAt: json['fetched_at'],
        lastUpdated: json['last_updated'],
        isLive: parseBool(json['is_live']),
        prices: json['prices'] != null ? GoldPrices.fromJson(json['prices']) : null,
      );
}

class GoldPrices {
  final List<GoldPrice>? karats;
  final GoldOunce? ounce;
  final SilverPrice? silver;
  final SilverOunce? silverOunce;
  final List<GoldBullion>? bullion;
  
  GoldPrices({this.karats, this.ounce, this.silver, this.silverOunce, this.bullion});
  
  factory GoldPrices.fromJson(Map<String, dynamic> json) => GoldPrices(
        karats: (json['karats'] as List?)?.map((e) => GoldPrice.fromJson(e)).toList(),
        ounce: json['ounce'] != null ? GoldOunce.fromJson(json['ounce']) : null,
        silver: json['silver'] != null ? SilverPrice.fromJson(json['silver']) : null,
        silverOunce: json['silver_ounce'] != null ? SilverOunce.fromJson(json['silver_ounce']) : null,
        bullion: (json['bullion'] as List?)?.map((e) => GoldBullion.fromJson(e)).toList(),
      );
}

class GoldOunce {
  final double price;
  final double? change;
  final String? currency;
  final String? nameAr;
  
  GoldOunce({required this.price, this.change, this.currency, this.nameAr});
  
  factory GoldOunce.fromJson(Map<String, dynamic> json) => GoldOunce(
        price: parseDouble(json['price']) ?? 0,
        change: parseDouble(json['change']),
        currency: json['currency'],
        nameAr: json['name_ar'],
      );
}

// Silver Price
class SilverPrice {
  final double pricePerGram;
  final double? change;
  final String? currency;
  final String? nameAr;
  
  SilverPrice({required this.pricePerGram, this.change, this.currency, this.nameAr});
  
  factory SilverPrice.fromJson(Map<String, dynamic> json) => SilverPrice(
        pricePerGram: parseDouble(json['price_per_gram']) ?? 0,
        change: parseDouble(json['change']),
        currency: json['currency'],
        nameAr: json['name_ar'],
      );
}

class SilverOunce {
  final double price;
  final double? change;
  final String? currency;
  final String? nameAr;
  
  SilverOunce({required this.price, this.change, this.currency, this.nameAr});
  
  factory SilverOunce.fromJson(Map<String, dynamic> json) => SilverOunce(
        price: parseDouble(json['price']) ?? 0,
        change: parseDouble(json['change']),
        currency: json['currency'],
        nameAr: json['name_ar'],
      );
}

class GoldBullion {
  final String key;
  final String nameAr;
  final double price;
  final double? change;
  
  GoldBullion({required this.key, required this.nameAr, required this.price, this.change});
  
  factory GoldBullion.fromJson(Map<String, dynamic> json) => GoldBullion(
        key: json['key'] ?? '',
        nameAr: json['name_ar'] ?? '',
        price: parseDouble(json['price']) ?? 0,
        change: parseDouble(json['change']),
      );
}

// Gold History Point
class GoldHistoryPoint {
  final String date;
  final double price;
  final double? change;
  final String? currency;
  
  GoldHistoryPoint({required this.date, required this.price, this.change, this.currency});
  
  factory GoldHistoryPoint.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString() ?? '';
    return GoldHistoryPoint(
        date: dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
        price: parseDouble(json['price']) ?? 0,
        change: parseDouble(json['change']),
        currency: json['currency'],
      );
  }
}

// Gold History Response
class GoldHistoryResponse {
  final bool success;
  final String karat;
  final int? days;
  final int? count;
  final List<GoldHistoryPoint> data;
  
  GoldHistoryResponse({required this.success, required this.karat, this.days, this.count, required this.data});
  
  factory GoldHistoryResponse.fromJson(Map<String, dynamic> json) => GoldHistoryResponse(
        success: parseBool(json['success']) ?? true,
        karat: json['karat']?.toString() ?? '',
        days: parseInt(json['days']),
        count: parseInt(json['count']),
        data: (json['data'] as List?)?.map((e) => GoldHistoryPoint.fromJson(e)).toList() ?? [],
      );
}

// Currency
class Currency {
  final String code;
  final String? nameAr;
  final double? buyRate;
  final double? sellRate;
  final double? change;
  final bool? isMajor;
  final String? lastUpdated;
  
  Currency({required this.code, this.nameAr, this.buyRate, this.sellRate, this.change, this.isMajor, this.lastUpdated});
  
  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: (json['code'] ?? '').toString(),
        nameAr: json['name_ar'],
        buyRate: parseDouble(json['buy_rate'] ?? json['buy'] ?? json['rate_to_egp'] ?? json['rate']),
        sellRate: parseDouble(json['sell_rate'] ?? json['sell'] ?? json['rate_to_egp'] ?? json['rate']),
        change: parseDouble(json['change']),
        isMajor: parseBool(json['is_major']),
        lastUpdated: json['last_updated'],
      );
}

class CurrencyResponse {
  final bool success;
  final String? source;
  final String? fetchedAt;
  final String? lastUpdated;
  final bool? isLive;
  final double? centralBankRate;
  final List<Currency>? currencies;
  
  CurrencyResponse({required this.success, this.source, this.fetchedAt, this.lastUpdated, this.isLive, this.centralBankRate, this.currencies});
  
  factory CurrencyResponse.fromJson(Map<String, dynamic> json) => CurrencyResponse(
        success: json['success'] ?? false,
        source: json['source'],
        fetchedAt: json['fetched_at'],
        lastUpdated: json['last_updated'],
        isLive: parseBool(json['is_live']),
        centralBankRate: parseDouble(json['central_bank_rate']),
        currencies: (json['currencies'] as List?)?.map((e) => Currency.fromJson(e)).toList(),
      );
}

// Conversion Result
class ConversionResult {
  final String from;
  final String to;
  final double amount;
  final double rate;
  final double result;
  final String lastUpdated;
  
  ConversionResult({required this.from, required this.to, required this.amount, required this.rate, required this.result, required this.lastUpdated});
  
  factory ConversionResult.fromJson(Map<String, dynamic> json) => ConversionResult(
        from: json['from'] ?? '',
        to: json['to'] ?? '',
        amount: parseDouble(json['amount']) ?? 0,
        rate: parseDouble(json['rate']) ?? 0,
        result: parseDouble(json['result']) ?? 0,
        lastUpdated: json['last_updated'] ?? '',
      );
}
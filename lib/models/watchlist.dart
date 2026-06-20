// ============================================================================
// مساعد الاستثمار Flutter - Watchlist Types
// ============================================================================

import 'json_helpers.dart';

class WatchlistItem {
  final String id;
  final String ticker;
  final String? name;
  final String? nameAr;
  final String? addedAt;
  final double? currentPrice;
  final double? previousClose;
  final double? priceChange;
  final double? changePercent;
  final String? sector;
  final double? alertPriceAbove;
  final double? alertPriceBelow;
  final String? notes;
  
  WatchlistItem({
    required this.id,
    required this.ticker,
    this.name,
    this.nameAr,
    this.addedAt,
    this.currentPrice,
    this.previousClose,
    this.priceChange,
    this.changePercent,
    this.sector,
    this.alertPriceAbove,
    this.alertPriceBelow,
    this.notes
  });
  
  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
        id: json['id']?.toString() ?? '',
        ticker: (json['ticker'] ?? json['symbol'] ?? json['stock_symbol'] ?? json['stock_ticker'] ?? '').toString(),
        name: (json['name'] ?? json['company'] ?? json['company_name'] ?? json['stock_name'] ?? '').toString(),
        nameAr: (json['name_ar'] ?? json['nameAr'] ?? json['arabic_name'] ?? json['name_arabic'] ?? '').toString(),
        addedAt: json['added_at']?.toString(),
        currentPrice: parseDouble(json['current_price'] ?? json['price'] ?? json['last_price']),
        previousClose: parseDouble(json['previous_close'] ?? json['prev_close']),
        priceChange: parseDouble(json['price_change'] ?? json['change']),
        changePercent: parseDouble(json['change_percent'] ?? json['price_change_percent'] ?? json['change_percentage'] ?? json['price_change']),
        sector: json['sector']?.toString(),
        alertPriceAbove: parseDouble(json['alert_price_above'] ?? json['price_above']),
        alertPriceBelow: parseDouble(json['alert_price_below'] ?? json['price_below']),
        notes: json['notes']?.toString(),
      );
}

class WatchlistResponse {
  final bool success;
  final List<WatchlistItem> items;
  final int total;
  
  WatchlistResponse({required this.success, required this.items, required this.total});
  
  factory WatchlistResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ??
        json['watchlist'] ??
        json['data'] ??
        json['results'] ??
        json['stocks'] ??
        (json['watchlist_items']);
    final itemsList = rawItems is List ? rawItems : [];
    final items = itemsList
        .map((e) => e is Map ? WatchlistItem.fromJson(Map<String, dynamic>.from(e)) : null)
        .where((e) => e != null)
        .cast<WatchlistItem>()
        .toList();
    return WatchlistResponse(
      success: parseBool(json['success']) ?? items.isNotEmpty,
      items: items,
      total: parseInt(json['total']) ?? items.length,
    );
  }
}
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
        ticker: json['ticker'] ?? '',
        name: json['name'],
        nameAr: json['name_ar'],
        addedAt: json['added_at'],
        currentPrice: parseDouble(json['current_price']),
        previousClose: parseDouble(json['previous_close']),
        priceChange: parseDouble(json['price_change']),
        changePercent: parseDouble(json['change_percent']),
        sector: json['sector'],
        alertPriceAbove: parseDouble(json['alert_price_above']),
        alertPriceBelow: parseDouble(json['alert_price_below']),
        notes: json['notes'],
      );
}

class WatchlistResponse {
  final bool success;
  final List<WatchlistItem> items;
  final int total;
  
  WatchlistResponse({required this.success, required this.items, required this.total});
  
  factory WatchlistResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = rawItems is List ? rawItems : [];
    final items = itemsList
        .map((e) => e is Map ? WatchlistItem.fromJson(Map<String, dynamic>.from(e)) : null)
        .where((e) => e != null)
        .cast<WatchlistItem>()
        .toList();
    return WatchlistResponse(
      success: parseBool(json['success']) ?? false,
      items: items,
      total: parseInt(json['total']) ?? 0,
    );
  }
}
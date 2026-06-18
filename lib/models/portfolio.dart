// ============================================================================
// مساعد الاستثمار Flutter - Portfolio Types
// ============================================================================

import 'json_helpers.dart';

class PortfolioPosition {
  final String id;
  final String? type; // stock, gold, certificate, fund
  final String stockSymbol;
  final String? stockName;
  final int shares;
  final double avgCost;
  final double currentPrice;
  final double marketValue;
  final double costBasis;
  final double unrealizedPnl;
  final double unrealizedPnlPercent;
  final String? sector;
  final String? status;
  final String? statusAr;
  final String? notes;
  final String? addedAt;

  PortfolioPosition({
    required this.id,
    this.type,
    required this.stockSymbol,
    this.stockName,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
    required this.marketValue,
    required this.costBasis,
    required this.unrealizedPnl,
    required this.unrealizedPnlPercent,
    this.sector,
    this.status,
    this.statusAr,
    this.notes,
    this.addedAt,
  });

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    // Handle both old and new API response formats
    final ticker = json['stock_ticker'] ?? json['stock_symbol'] ?? json['ticker'] ?? '';
    final quantity = parseInt(json['quantity'] ?? json['shares'] ?? json['weight_grams']) ?? 0;
    final avgBuyPrice = parseDouble(json['avg_buy_price'] ?? json['avg_cost'] ?? json['purchase_price_per_gram']) ?? 0;
    final currentPrice = parseDouble(json['current_price']) ?? 0;

    return PortfolioPosition(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'stock',
      stockSymbol: ticker,
      stockName: json['stock_name'] ?? json['name'] ?? ticker,
      shares: quantity,
      avgCost: avgBuyPrice,
      currentPrice: currentPrice,
      marketValue: parseDouble(json['market_value']) ?? (quantity * currentPrice),
      costBasis: parseDouble(json['cost_basis']) ?? (quantity * avgBuyPrice),
      unrealizedPnl: parseDouble(json['unrealized_pnl']) ?? 0,
      unrealizedPnlPercent: parseDouble(json['unrealized_pnl_percent']) ?? 0,
      sector: json['sector'],
      status: json['status'],
      statusAr: json['status_ar'],
      notes: json['notes'],
      addedAt: json['added_at'],
    );
  }
}

class PortfolioSummary {
  final int totalPositions;
  final double totalCostBasis;
  final double totalMarketValue;
  final double totalUnrealizedPnl;
  final double totalUnrealizedPnlPercent;
  final int? stocksCount;
  final int? goldItems;
  final int? certificatesCount;
  final int? fundsCount;
  final int? winningPositions;
  final int? losingPositions;

  PortfolioSummary({
    required this.totalPositions,
    required this.totalCostBasis,
    required this.totalMarketValue,
    required this.totalUnrealizedPnl,
    required this.totalUnrealizedPnlPercent,
    this.stocksCount,
    this.goldItems,
    this.certificatesCount,
    this.fundsCount,
    this.winningPositions,
    this.losingPositions,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) => PortfolioSummary(
        totalPositions: parseInt(json['total_positions'] ?? json['total_items']) ?? 0,
        totalCostBasis: parseDouble(json['total_cost_basis'] ?? json['total_invested']) ?? 0,
        totalMarketValue: parseDouble(json['total_market_value']) ?? 0,
        totalUnrealizedPnl: parseDouble(json['total_unrealized_pnl']) ?? 0,
        totalUnrealizedPnlPercent: parseDouble(json['total_unrealized_pnl_percent']) ?? 0,
        stocksCount: parseInt(json['stocks_count']),
        goldItems: parseInt(json['gold_items']),
        certificatesCount: parseInt(json['certificates_count']),
        fundsCount: parseInt(json['funds_count']),
        winningPositions: parseInt(json['winning_positions']),
        losingPositions: parseInt(json['losing_positions']),
      );
}

class PortfolioResponse {
  final bool success;
  final List<PortfolioPosition> positions;
  final List<PortfolioPosition>? items; // All assets including gold, certificates
  final PortfolioSummary? summary;
  final Map<String, List<PortfolioPosition>>? byType;

  PortfolioResponse({
    this.success = true,
    required this.positions,
    this.items,
    this.summary,
    this.byType,
  });

  factory PortfolioResponse.fromJson(Map<String, dynamic> json) {
    List<PortfolioPosition> positionsList = [];
    List<PortfolioPosition> allItemsList = [];

    // Parse positions (stocks only)
    final rawPositions = json['positions'];
    if (rawPositions is List) {
      positionsList = rawPositions
          .map((e) => e is Map ? PortfolioPosition.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<PortfolioPosition>()
          .toList();
    }

    // Parse items (all assets)
    final rawItems = json['items'];
    if (rawItems is List) {
      allItemsList = rawItems
          .map((e) => e is Map ? PortfolioPosition.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<PortfolioPosition>()
          .toList();
    }

    // If positions is empty but items has stocks, use items
    if (positionsList.isEmpty && allItemsList.isNotEmpty) {
      positionsList = allItemsList.where((p) => p.type == 'stock' || p.type == null).toList();
    }

    // Parse by_type if available
    Map<String, List<PortfolioPosition>>? byType;
    final rawByType = json['by_type'];
    if (rawByType is Map) {
      byType = {};
      for (final entry in rawByType.entries) {
        final val = entry.value;
        if (val is List) {
          byType[entry.key.toString()] = val
              .map((e) => e is Map ? PortfolioPosition.fromJson(Map<String, dynamic>.from(e)) : null)
              .where((e) => e != null)
              .cast<PortfolioPosition>()
              .toList();
        }
      }
    }

    final rawSummary = json['summary'];
    return PortfolioResponse(
      success: parseBool(json['success']) ?? true,
      positions: positionsList,
      items: allItemsList.isNotEmpty ? allItemsList : null,
      summary: rawSummary is Map ? PortfolioSummary.fromJson(Map<String, dynamic>.from(rawSummary)) : null,
      byType: byType,
    );
  }
}

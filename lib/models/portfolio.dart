// ============================================================================
// مساعد الاستثمار Flutter - Portfolio Types
// ============================================================================

import 'json_helpers.dart';

class PortfolioPosition {
  final String id;
  final String stockSymbol;
  final String? stockName;
  final int shares;
  final double avgCost;
  final double currentPrice;
  final double marketValue;
  final double costBasis;
  final double unrealizedPnl;
  final double unrealizedPnlPercent;
  
  PortfolioPosition({
    required this.id,
    required this.stockSymbol,
    this.stockName,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
    required this.marketValue,
    required this.costBasis,
    required this.unrealizedPnl,
    required this.unrealizedPnlPercent
  });
  
  factory PortfolioPosition.fromJson(Map<String, dynamic> json) => PortfolioPosition(
        id: json['id'] ?? '',
        stockSymbol: json['stock_symbol'] ?? '',
        stockName: json['stock_name'],
        shares: parseInt(json['shares']) ?? 0,
        avgCost: parseDouble(json['avg_cost']) ?? 0,
        currentPrice: parseDouble(json['current_price']) ?? 0,
        marketValue: parseDouble(json['market_value']) ?? 0,
        costBasis: parseDouble(json['cost_basis']) ?? 0,
        unrealizedPnl: parseDouble(json['unrealized_pnl']) ?? 0,
        unrealizedPnlPercent: parseDouble(json['unrealized_pnl_percent']) ?? 0,
      );
}

class PortfolioSummary {
  final int totalPositions;
  final double totalCostBasis;
  final double totalMarketValue;
  final double totalUnrealizedPnl;
  final double totalUnrealizedPnlPercent;
  
  PortfolioSummary({
    required this.totalPositions,
    required this.totalCostBasis,
    required this.totalMarketValue,
    required this.totalUnrealizedPnl,
    required this.totalUnrealizedPnlPercent
  });
  
  factory PortfolioSummary.fromJson(Map<String, dynamic> json) => PortfolioSummary(
        totalPositions: parseInt(json['total_positions']) ?? 0,
        totalCostBasis: parseDouble(json['total_cost_basis']) ?? 0,
        totalMarketValue: parseDouble(json['total_market_value']) ?? 0,
        totalUnrealizedPnl: parseDouble(json['total_unrealized_pnl']) ?? 0,
        totalUnrealizedPnlPercent: parseDouble(json['total_unrealized_pnl_percent']) ?? 0,
      );
}

class PortfolioResponse {
  final bool success;
  final List<PortfolioPosition> positions;
  final PortfolioSummary? summary;
  
  PortfolioResponse({required this.success, required this.positions, this.summary});
  
  factory PortfolioResponse.fromJson(Map<String, dynamic> json) => PortfolioResponse(
        success: json['success'] ?? false,
        positions: (json['positions'] as List?)?.map((e) => PortfolioPosition.fromJson(e)).toList() ?? [],
        summary: json['summary'] != null ? PortfolioSummary.fromJson(json['summary']) : null,
      );
}
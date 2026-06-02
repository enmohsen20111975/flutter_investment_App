// ============================================================================
// مساعد الاستثمار Flutter - Market Types
// ============================================================================

import 'package:flutter/foundation.dart';
import 'json_helpers.dart';

// Market Status
class MarketStatus {
  final bool? isOpen;
  final bool? isMarketHours;
  final String? status;
  final String? currentSession;
  
  MarketStatus({this.isOpen, this.isMarketHours, this.status, this.currentSession});
  
  factory MarketStatus.fromJson(Map<String, dynamic> json) => MarketStatus(
        isOpen: parseBool(json['is_open']),
        isMarketHours: parseBool(json['is_market_hours']),
        status: json['status'],
        currentSession: json['current_session'],
      );
}

// Market Index
class MarketIndex {
  final String symbol;
  final String? name;
  final String? nameAr;
  final double? value;
  final double? change;
  final double? changePercent;
  
  MarketIndex({required this.symbol, this.name, this.nameAr, this.value, this.change, this.changePercent});
  
  factory MarketIndex.fromJson(Map<String, dynamic> json) => MarketIndex(
        symbol: json['symbol'] ?? '',
        name: json['name'],
        nameAr: json['name_ar'],
        value: parseDouble(json['value']),
        change: parseDouble(json['change']),
        changePercent: parseDouble(json['change_percent']),
      );
}

// Market Stock
class MarketStock {
  final String ticker;
  final String? name;
  final String? nameAr;
  final double? currentPrice;
  final double? priceChange;
  final double? changePercent;
  final int? volume;
  
  MarketStock({required this.ticker, this.name, this.nameAr, this.currentPrice, this.priceChange, this.changePercent, this.volume});
  
  factory MarketStock.fromJson(Map<String, dynamic> json) => MarketStock(
        ticker: json['ticker'] ?? '',
        name: json['name'],
        nameAr: json['name_ar'],
        currentPrice: parseDouble(json['current_price']),
        priceChange: parseDouble(json['price_change']),
        changePercent: parseDouble(json['change_percent']),
        volume: parseInt(json['volume']),
      );
}

// Market Overview
class MarketOverview {
  final MarketStatus? marketStatus;
  final MarketSummary? summary;
  final List<MarketIndex>? indices;
  final List<MarketStock>? topGainers;
  final List<MarketStock>? topLosers;
  final List<MarketStock>? mostActive;
  final String? lastUpdated;
  final String? source;
  final int? totalStocks;
  final int? gainers;
  final int? losers;

  MarketOverview({this.marketStatus, this.summary, this.indices, this.topGainers, this.topLosers, this.mostActive, this.lastUpdated, this.source, this.totalStocks, this.gainers, this.losers});
  
  factory MarketOverview.fromJson(Map<String, dynamic> json) {
    debugPrint('[MarketOverview] Parsing JSON keys: \${json.keys}');
    
    final summaryData = json['summary'] as Map<String, dynamic>?;
    final dataWrapper = json['data'] as Map<String, dynamic>?;
    
    // Handle wrapped response format: {data: {...}, source: "vps"}
    final actualData = dataWrapper ?? json;
    
    // Parse indices from different formats
    List<MarketIndex>? indicesList;
    if (actualData['indices'] is List) {
      indicesList = (actualData['indices'] as List)
          .map((e) => MarketIndex.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Parse top gainers from different formats
    List<MarketStock>? gainersList;
    if (actualData['top_gainers'] is List) {
      gainersList = (actualData['top_gainers'] as List)
          .map((e) => MarketStock.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (actualData['gainers'] is List) {
      gainersList = (actualData['gainers'] as List)
          .map((e) => MarketStock.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Parse top losers from different formats
    List<MarketStock>? losersList;
    if (actualData['top_losers'] is List) {
      losersList = (actualData['top_losers'] as List)
          .map((e) => MarketStock.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (actualData['losers'] is List) {
      losersList = (actualData['losers'] as List)
          .map((e) => MarketStock.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Parse most active
    List<MarketStock>? activeList;
    if (actualData['most_active'] is List) {
      activeList = (actualData['most_active'] as List)
          .map((e) => MarketStock.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    return MarketOverview(
      marketStatus: actualData['market_status'] != null 
          ? MarketStatus.fromJson(actualData['market_status']) 
          : actualData['marketStatus'] != null
              ? MarketStatus.fromJson(actualData['marketStatus'])
              : null,
      summary: actualData['summary'] != null 
          ? MarketSummary.fromJson(actualData['summary']) 
          : null,
      indices: indicesList,
      topGainers: gainersList,
      topLosers: losersList,
      mostActive: activeList,
      lastUpdated: actualData['last_updated'] ?? actualData['lastUpdated'],
      source: actualData['source'],
      totalStocks: parseInt(actualData['total_stocks'] ?? actualData['totalStocks']) 
          ?? parseInt(summaryData?['total_stocks']),
      gainers: parseInt(actualData['gainers']) 
          ?? parseInt(summaryData?['gainers']),
      losers: parseInt(actualData['losers']) 
          ?? parseInt(summaryData?['losers']),
    );
  }
}

class MarketSummary {
  final int? totalStocks;
  final int? gainers;
  final int? losers;
  final int? unchanged;
  final int? egx30Stocks;
  final int? egx70Stocks;
  final int? egx100Stocks;
  final double? egx30Value;
  final int? totalVolume;
  final double? totalMarketCap;
  
  MarketSummary({this.totalStocks, this.gainers, this.losers, this.unchanged, this.egx30Stocks, this.egx70Stocks, this.egx100Stocks, this.egx30Value, this.totalVolume, this.totalMarketCap});
  
  factory MarketSummary.fromJson(Map<String, dynamic> json) => MarketSummary(
        totalStocks: parseInt(json['total_stocks']),
        gainers: parseInt(json['gainers']),
        losers: parseInt(json['losers']),
        unchanged: parseInt(json['unchanged']),
        egx30Stocks: parseInt(json['egx30_stocks']),
        egx70Stocks: parseInt(json['egx70_stocks']),
        egx100Stocks: parseInt(json['egx100_stocks']),
        egx30Value: parseDouble(json['egx30_value']),
        totalVolume: parseInt(json['total_volume']),
        totalMarketCap: parseDouble(json['total_market_cap']),
      );
}
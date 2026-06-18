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
    debugPrint('[MarketOverview] Parsing JSON keys: ${json.keys}');
    
    final rawSummary = json['summary'];
    final summaryData = rawSummary is Map ? Map<String, dynamic>.from(rawSummary) : null;
    
    final rawDataWrapper = json['data'];
    final dataWrapper = rawDataWrapper is Map ? Map<String, dynamic>.from(rawDataWrapper) : null;
    
    // Handle wrapped response format: {data: {...}, source: "vps"}
    final Map<String, dynamic> actualData = dataWrapper ?? json;
    
    // Parse indices from different formats
    List<MarketIndex>? indicesList;
    final rawIndices = actualData['indices'];
    if (rawIndices is List) {
      indicesList = rawIndices
          .map((e) => e is Map ? MarketIndex.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<MarketIndex>()
          .toList();
    }
    
    // Parse top gainers from different formats
    List<MarketStock>? gainersList;
    final rawTopGainers = actualData['top_gainers'];
    final rawGainers = actualData['gainers'];
    if (rawTopGainers is List) {
      gainersList = rawTopGainers
          .map((e) => e is Map ? MarketStock.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<MarketStock>()
          .toList();
    } else if (rawGainers is List) {
      gainersList = rawGainers
          .map((e) => e is Map ? MarketStock.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<MarketStock>()
          .toList();
    }
    
    // Parse top losers from different formats
    List<MarketStock>? losersList;
    final rawTopLosers = actualData['top_losers'];
    final rawLosers = actualData['losers'];
    if (rawTopLosers is List) {
      losersList = rawTopLosers
          .map((e) => e is Map ? MarketStock.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<MarketStock>()
          .toList();
    } else if (rawLosers is List) {
      losersList = rawLosers
          .map((e) => e is Map ? MarketStock.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<MarketStock>()
          .toList();
    }
    
    // Parse most active
    List<MarketStock>? activeList;
    final rawMostActive = actualData['most_active'];
    if (rawMostActive is List) {
      activeList = rawMostActive
          .map((e) => e is Map ? MarketStock.fromJson(Map<String, dynamic>.from(e)) : null)
          .where((e) => e != null)
          .cast<MarketStock>()
          .toList();
    }
    
    final rawMarketStatus1 = actualData['market_status'];
    final rawMarketStatus2 = actualData['marketStatus'];
    final rawSummary2 = actualData['summary'];

    return MarketOverview(
      marketStatus: rawMarketStatus1 is Map 
          ? MarketStatus.fromJson(Map<String, dynamic>.from(rawMarketStatus1)) 
          : rawMarketStatus2 is Map
              ? MarketStatus.fromJson(Map<String, dynamic>.from(rawMarketStatus2))
              : null,
      summary: rawSummary2 is Map 
          ? MarketSummary.fromJson(Map<String, dynamic>.from(rawSummary2)) 
          : null,
      indices: indicesList,
      topGainers: gainersList,
      topLosers: losersList,
      mostActive: activeList,
      lastUpdated: parseString(actualData['last_updated'] ?? actualData['lastUpdated']),
      source: parseString(actualData['source']),
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
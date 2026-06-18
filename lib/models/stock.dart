// ============================================================================
// مساعد الاستثمار Flutter - Stock Types
// ============================================================================

import 'json_helpers.dart';

// Stock
class Stock {
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

  Stock({
    required this.ticker,
    this.name, this.nameAr, this.sector, this.industry,
    this.currentPrice, this.previousClose, this.openPrice,
    this.highPrice, this.lowPrice, this.priceChange,
    this.changePercent, this.volume, this.marketCap,
    this.peRatio, this.pbRatio, this.dividendYield,
    this.rsi, this.ma50, this.ma200,
    this.supportLevel, this.resistanceLevel,
    this.egx30Member, this.egx70Member, this.egx100Member,
    this.lastUpdate,
  });

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        ticker: json['ticker'] ?? json['symbol'] ?? '',
        name: json['name'],
        nameAr: json['name_ar'],
        sector: json['sector'],
        industry: json['industry'],
        currentPrice: parseDouble(json['current_price'] ?? json['price']),
        previousClose: parseDouble(json['previous_close']),
        openPrice: parseDouble(json['open_price'] ?? json['open']),
        highPrice: parseDouble(json['high_price'] ?? json['high']),
        lowPrice: parseDouble(json['low_price'] ?? json['low']),
        priceChange: parseDouble(json['price_change'] ?? json['change']),
        changePercent: parseDouble(json['change_percent'] ?? json['change_percent']),
        volume: parseInt(json['volume']),
        marketCap: parseDouble(json['market_cap']),
        peRatio: parseDouble(json['pe_ratio']),
        pbRatio: parseDouble(json['pb_ratio']),
        dividendYield: parseDouble(json['dividend_yield']),
        rsi: parseDouble(json['rsi']),
        ma50: parseDouble(json['ma_50']),
        ma200: parseDouble(json['ma_200']),
        supportLevel: parseDouble(json['support_level']),
        resistanceLevel: parseDouble(json['resistance_level']),
        egx30Member: parseBool(json['egx30_member']),
        egx70Member: parseBool(json['egx70_member']),
        egx100Member: parseBool(json['egx100_member']),
        lastUpdate: json['last_update'] ?? json['last_updated'],
      );
}

// Stock History
class StockHistory {
  final String date;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final int? volume;
  final double? rsi;
  
  StockHistory({required this.date, this.open, this.high, this.low, this.close, this.volume, this.rsi});
  
  factory StockHistory.fromJson(Map<String, dynamic> json) => StockHistory(
        date: json['date'] ?? '',
        open: parseDouble(json['open']),
        high: parseDouble(json['high']),
        low: parseDouble(json['low']),
        close: parseDouble(json['close']),
        volume: parseInt(json['volume']),
        rsi: parseDouble(json['rsi']),
      );
}

class StockHistorySummary {
  final double? highest;
  final double? lowest;
  final double? avgPrice;
  final double? changePercent;
  final int? totalVolume;
  final double? startPrice;
  final double? endPrice;
  
  StockHistorySummary({this.highest, this.lowest, this.avgPrice, this.changePercent, this.totalVolume, this.startPrice, this.endPrice});
  
  factory StockHistorySummary.fromJson(Map<String, dynamic> json) => StockHistorySummary(
        highest: parseDouble(json['highest']),
        lowest: parseDouble(json['lowest']),
        avgPrice: parseDouble(json['avg_price']),
        changePercent: parseDouble(json['change_percent']),
        totalVolume: parseInt(json['total_volume']),
        startPrice: parseDouble(json['start_price']),
        endPrice: parseDouble(json['end_price']),
      );
}

class StockHistoryResponse {
  final bool success;
  final String ticker;
  final List<StockHistory> data;
  final StockHistorySummary? summary;
  
  StockHistoryResponse({this.success = true, this.ticker = '', this.data = const [], this.summary});
  
  factory StockHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final listData = rawData is List ? rawData : [];
    final historyList = listData
        .map((e) => e is Map ? StockHistory.fromJson(Map<String, dynamic>.from(e)) : null)
        .where((e) => e != null)
        .cast<StockHistory>()
        .toList();

    final rawSummary = json['summary'];
    final summary = rawSummary is Map ? StockHistorySummary.fromJson(Map<String, dynamic>.from(rawSummary)) : null;

    return StockHistoryResponse(
      success: parseBool(json['success']) ?? true,
      ticker: parseString(json['ticker']) ?? '',
      data: historyList,
      summary: summary,
    );
  }
}

// Stock Detail Response (wraps VPS/next.js stock detail data)
class StockDetailResponse {
  final String? ticker;
  final String? symbol;
  final String? name;
  final String? nameAr;
  final double? price;
  final double? currentPrice;
  final double? change;
  final double? changePercent;
  final double? open;
  final double? high;
  final double? low;
  final double? previousClose;
  final int? volume;
  final double? valueTraded;
  final String? exchange;
  final String? lastUpdated;
  final String? source;

  StockDetailResponse({
    this.ticker, this.symbol, this.name, this.nameAr,
    this.price, this.currentPrice, this.change, this.changePercent,
    this.open, this.high, this.low, this.previousClose,
    this.volume, this.valueTraded, this.exchange, this.lastUpdated, this.source,
  });

  double? get effectivePrice => price ?? currentPrice;
  String? get effectiveTicker => ticker ?? symbol;

  factory StockDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final Map<String, dynamic> data = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : json;
    return StockDetailResponse(
      ticker: parseString(data['ticker'] ?? json['ticker']),
      symbol: parseString(data['symbol']),
      name: parseString(data['name']),
      nameAr: parseString(data['name_ar']),
      price: parseDouble(data['price']),
      currentPrice: parseDouble(data['current_price']),
      change: parseDouble(data['change']),
      changePercent: parseDouble(data['change_percent']),
      open: parseDouble(data['open']),
      high: parseDouble(data['high']),
      low: parseDouble(data['low']),
      previousClose: parseDouble(data['previous_close']),
      volume: parseInt(data['volume']),
      valueTraded: parseDouble(data['value_traded']),
      exchange: parseString(data['exchange']),
      lastUpdated: parseString(data['last_updated']),
      source: parseString(json['source']),
    );
  }

  Stock toStock() => Stock(
        ticker: effectiveTicker ?? '',
        name: name,
        nameAr: nameAr,
        currentPrice: effectivePrice,
        openPrice: open,
        highPrice: high,
        lowPrice: low,
        priceChange: change,
        changePercent: changePercent,
        volume: volume,
        previousClose: previousClose,
        lastUpdate: lastUpdated,
      );
}

// Stock Recommendation Response
class StockRecommendationResponse {
  final String ticker;
  final String? action;
  final String? actionAr;
  final double? confidence;
  final Map<String, dynamic>? scores;
  final Map<String, dynamic>? trend;
  final Map<String, dynamic>? priceRange;
  final double? targetPrice;
  final List<Map<String, dynamic>>? keyStrengths;
  final List<Map<String, dynamic>>? keyRisks;
  final String? note;
  final Map<String, dynamic>? professionalAnalysis;

  StockRecommendationResponse({
    required this.ticker,
    this.action, this.actionAr, this.confidence,
    this.scores, this.trend, this.priceRange,
    this.targetPrice, this.keyStrengths, this.keyRisks,
    this.note, this.professionalAnalysis,
  });

  factory StockRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final rawRec = json['recommendation'];
    final rec = rawRec is Map ? Map<String, dynamic>.from(rawRec) : <String, dynamic>{};

    final rawScores = json['scores'];
    final scores = rawScores is Map ? Map<String, dynamic>.from(rawScores) : null;

    final rawTrend = json['trend'];
    final trend = rawTrend is Map ? Map<String, dynamic>.from(rawTrend) : null;

    final rawPriceRange = json['price_range'];
    final priceRange = rawPriceRange is Map ? Map<String, dynamic>.from(rawPriceRange) : null;

    final rawProf = json['professional_analysis'];
    final profAnalysis = rawProf is Map ? Map<String, dynamic>.from(rawProf) : null;

    final rawStrengths = json['key_strengths'];
    final keyStrengths = rawStrengths is List
        ? rawStrengths
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
            .where((e) => e != null)
            .cast<Map<String, dynamic>>()
            .toList()
        : null;

    final rawRisks = json['key_risks'];
    final keyRisks = rawRisks is List
        ? rawRisks
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
            .where((e) => e != null)
            .cast<Map<String, dynamic>>()
            .toList()
        : null;

    return StockRecommendationResponse(
      ticker: parseString(json['ticker']) ?? '',
      action: parseString(rec['action']),
      actionAr: parseString(rec['action_ar']),
      confidence: parseDouble(rec['confidence']),
      scores: scores,
      trend: trend,
      priceRange: priceRange,
      targetPrice: parseDouble(json['target_price']),
      keyStrengths: keyStrengths,
      keyRisks: keyRisks,
      note: parseString(json['note']),
      professionalAnalysis: profAnalysis,
    );
  }
}

// Analyzed Stock
class AnalyzedStock {
  final Stock stock;
  final String? analysis;
  final dynamic recommendation;
  final double? compositeScore;
  final double? technicalScore;
  final double? fundamentalScore;
  final double? riskScore;
  final String? dataQuality;
  
  AnalyzedStock({required this.stock, this.analysis, this.recommendation, this.compositeScore, this.technicalScore, this.fundamentalScore, this.riskScore, this.dataQuality});
}

class BatchAnalysisResponse {
  final List<AnalyzedStock> analyzed;
  final BatchAnalysisSummary summary;
  BatchAnalysisResponse({required this.analyzed, required this.summary});
}

class BatchAnalysisSummary {
  final int buySignals;
  final int sellSignals;
  final int? holdSignals;
  final int? analyzedCount;
  final double? averageScore;
  BatchAnalysisSummary({required this.buySignals, required this.sellSignals, this.holdSignals, this.analyzedCount, this.averageScore});
}
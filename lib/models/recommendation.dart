// ============================================================================
// مساعد الاستثمار Flutter - Recommendation Types
// ============================================================================

import 'json_helpers.dart';

// Recommendation
class Recommendation {
  final String? ticker;
  final String? symbol;
  final String? name;
  final String? nameAr;
  final String? nameArAlt;
  final double? score;
  final double? totalScore;
  final String? action;
  final String? actionAr;
  final double? currentPrice;
  final double? targetPrice;
  final double? compositeScore;
  final String? recommendation;
  final String? sector;
  final String? riskLevel;
  final double? confidence;
  
  Recommendation({
    this.ticker,
    this.symbol,
    this.name,
    this.nameAr,
    this.nameArAlt,
    this.score,
    this.totalScore,
    this.action,
    this.actionAr,
    this.currentPrice,
    this.targetPrice,
    this.compositeScore,
    this.recommendation,
    this.sector,
    this.riskLevel,
    this.confidence
  });
  
  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        ticker: json['ticker'] ?? json['symbol'],
        symbol: json['symbol'],
        name: json['name'],
        nameAr: json['nameAr'] ?? json['name_ar'],
        nameArAlt: json['name_ar'],
        score: parseDouble(json['score']),
        totalScore: parseDouble(json['totalScore']),
        action: json['action'],
        actionAr: json['action_ar'],
        currentPrice: parseDouble(json['current_price'] ?? json['currentPrice']),
        targetPrice: parseDouble(json['target_price'] ?? json['targetPrice']),
        compositeScore: parseDouble(json['compositeScore']),
        recommendation: json['recommendation'],
        sector: json['sector'],
        riskLevel: json['risk_level'] ?? json['risk'],
        confidence: parseDouble(json['confidence']),
      );
}

// AI Recommendation (used in batch analysis responses)
class AIRecommendation {
  final String ticker;
  final String action;
  final double confidence;
  final double? priceTarget;
  final double? stopLoss;
  final List<String> reasons;
  final String technicalAnalysis;
  final String fundamentalAnalysis;
  final String newsImpact;
  final String riskLevel;
  final String timeHorizon;
  final String timestamp;
  
  AIRecommendation({
    required this.ticker,
    required this.action,
    required this.confidence,
    this.priceTarget,
    this.stopLoss,
    required this.reasons,
    required this.technicalAnalysis,
    required this.fundamentalAnalysis,
    required this.newsImpact,
    required this.riskLevel,
    required this.timeHorizon,
    required this.timestamp
  });
  
  factory AIRecommendation.fromJson(Map<String, dynamic> json) => AIRecommendation(
        ticker: json['ticker'] ?? '',
        action: json['action'] ?? '',
        confidence: parseDouble(json['confidence']) ?? 0,
        priceTarget: parseDouble(json['price_target']),
        stopLoss: parseDouble(json['stop_loss']),
        reasons: parseStringList(json['reasons']),
        technicalAnalysis: json['technical_analysis'] ?? '',
        fundamentalAnalysis: json['fundamental_analysis'] ?? '',
        newsImpact: json['news_impact'] ?? '',
        riskLevel: json['risk_level'] ?? '',
        timeHorizon: json['time_horizon'] ?? '',
        timestamp: json['timestamp'] ?? '',
      );
}

// Expert Recommendation
class ExpertRecommendation {
  final String? id;
  final String? stockSymbol;
  final String? name;
  final String? nameAr;
  final String? expertName;
  final String? action;
  final double? entryPrice;
  final double? targetPrice;
  final double? stopLoss;
  final String? recommendationDate;
  final String? status;
  final bool? hitTarget;
  final bool? hitStopLoss;
  final double? profitLossPercent;
  final String? notes;
  
  ExpertRecommendation({
    this.id,
    this.stockSymbol,
    this.name,
    this.nameAr,
    this.expertName,
    this.action,
    this.entryPrice,
    this.targetPrice,
    this.stopLoss,
    this.recommendationDate,
    this.status,
    this.hitTarget,
    this.hitStopLoss,
    this.profitLossPercent,
    this.notes
  });
  
  factory ExpertRecommendation.fromJson(Map<String, dynamic> json) => ExpertRecommendation(
        id: json['id']?.toString(),
        stockSymbol: (json['stock_symbol'] ?? json['stock_ticker'] ?? json['ticker'] ?? json['symbol'] ?? json['stock'] ?? json['company_symbol'] ?? '').toString(),
        name: (json['name'] ?? json['company'] ?? json['company_name'] ?? json['stock_name'] ?? '').toString(),
        nameAr: (json['name_ar'] ?? json['nameAr'] ?? json['arabic_name'] ?? json['name_arabic'] ?? '').toString(),
        expertName: json['expert_name'] ?? json['expertName'] ?? 'ذكاء اصطناعي',
        action: (json['action'] ?? json['recommendation'] ?? json['signal'] ?? '').toString(),
        entryPrice: parseDouble(json['entry_price'] ?? json['current_price'] ?? json['price']),
        targetPrice: parseDouble(json['target_price']),
        stopLoss: parseDouble(json['stop_loss']),
        recommendationDate: (json['recommendation_date'] ?? json['prediction_date'] ?? json['created_at'] ?? '').toString(),
        status: (json['status'] ?? 'PENDING').toString(),
        hitTarget: parseBool(json['hit_target']),
        hitStopLoss: parseBool(json['hit_stop_loss']),
        profitLossPercent: parseDouble(json['profit_loss_percent'] ?? json['change_percent'] ?? json['actual_return']),
        notes: json['notes']?.toString() ?? (json['signals'] is List ? (json['signals'] as List).join(', ') : json['reasoning']?.toString()),
      );
}

// Expert Stats
class ExpertStats {
  final String expertName;
  final int totalRecommendations;
  final int successfulRecommendations;
  final double successRate;
  final double avgReturn;
  
  ExpertStats({
    required this.expertName,
    required this.totalRecommendations,
    required this.successfulRecommendations,
    required this.successRate,
    required this.avgReturn
  });
  
  factory ExpertStats.fromJson(Map<String, dynamic> json) => ExpertStats(
        expertName: json['expert_name'] ?? '',
        totalRecommendations: parseInt(json['total_recommendations']) ?? 0,
        successfulRecommendations: parseInt(json['successful_recommendations']) ?? 0,
        successRate: parseDouble(json['success_rate']) ?? 0,
        avgReturn: parseDouble(json['avg_return']) ?? 0,
      );
}

// Prediction
class Prediction {
  final String? id;
  final String? ticker;
  final String? predictionType;
  final int? confidence;
  final double? entryPrice;
  final double? targetPrice;
  final double? stopLoss;
  final int? technicalScore;
  final int? fundamentalScore;
  final String? status;
  final String? predictionDate;
  
  Prediction({
    this.id,
    this.ticker,
    this.predictionType,
    this.confidence,
    this.entryPrice,
    this.targetPrice,
    this.stopLoss,
    this.technicalScore,
    this.fundamentalScore,
    this.status,
    this.predictionDate
  });
  
  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        id: json['id']?.toString(),
        ticker: json['ticker'] ?? '',
        predictionType: json['prediction_type'] ?? '',
        confidence: parseInt(json['confidence']),
        entryPrice: parseDouble(json['entry_price']),
        targetPrice: parseDouble(json['target_price']),
        stopLoss: parseDouble(json['stop_loss']),
        technicalScore: parseInt(json['technical_score']),
        fundamentalScore: parseInt(json['fundamental_score']),
        status: json['status'] ?? 'ACTIVE',
        predictionDate: json['prediction_date'] ?? '',
      );
}
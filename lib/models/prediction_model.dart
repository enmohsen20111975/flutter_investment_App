// ============================================================================
// مساعد الاستثمار Flutter - Prediction Model
// Typed prediction data model with fromJson/toJson
// ============================================================================

import 'package:flutter/material.dart';

class PredictionModel {
  final String? id;
  final String? ticker;
  final String predictionType;
  final int confidence;
  final double? entryPrice;
  final double? targetPrice;
  final double? stopLoss;
  final int technicalScore;
  final int fundamentalScore;
  final String status;
  final String predictionDate;
  final String? reasoning;

  PredictionModel({
    this.id,
    this.ticker,
    this.predictionType = 'general',
    this.confidence = 0,
    this.entryPrice,
    this.targetPrice,
    this.stopLoss,
    this.technicalScore = 0,
    this.fundamentalScore = 0,
    this.status = 'ACTIVE',
    this.predictionDate = '',
    this.reasoning,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) =>
      PredictionModel(
        id: json['id']?.toString(),
        ticker: json['ticker']?.toString() ?? json['symbol']?.toString(),
        predictionType: json['prediction_type']?.toString() ??
            json['type']?.toString() ??
            'general',
        confidence: _toInt(json['confidence']) ?? 0,
        entryPrice: _toDouble(json['entry_price'] ?? json['entry']),
        targetPrice: _toDouble(json['target_price'] ?? json['target']),
        stopLoss: _toDouble(json['stop_loss'] ?? json['stopLoss']),
        technicalScore: _toInt(json['technical_score'] ?? json['technicalScore']) ?? 0,
        fundamentalScore: _toInt(json['fundamental_score'] ?? json['fundamentalScore']) ?? 0,
        status: json['status']?.toString() ?? 'ACTIVE',
        predictionDate: json['prediction_date']?.toString() ??
            json['date']?.toString() ??
            json['created_at']?.toString() ??
            '',
        reasoning: json['reasoning']?.toString() ??
            json['note']?.toString() ??
            json['analysis']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticker': ticker,
        'prediction_type': predictionType,
        'confidence': confidence,
        'entry_price': entryPrice,
        'target_price': targetPrice,
        'stop_loss': stopLoss,
        'technical_score': technicalScore,
        'fundamental_score': fundamentalScore,
        'status': status,
        'prediction_date': predictionDate,
        'reasoning': reasoning,
      };

  String get actionLabel {
    if (confidence >= 70) return 'شراء';
    if (confidence >= 40) return 'حياد';
    return 'بيع';
  }

  Color get actionColor {
    if (confidence >= 70) return const Color(0xFF22C55E);
    if (confidence >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

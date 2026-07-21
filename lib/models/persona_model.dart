// ============================================================================
// مساعد الاستثمار Flutter - Persona Model
// Stock opportunity from persona-based scanning
// ============================================================================

import 'package:flutter/material.dart';

class PersonaOpportunity {
  final String ticker;
  final String? name;
  final String? nameAr;
  final String? sector;
  final double? score;
  final String? signal;
  final double? entryPrice;
  final double? targetPrice;
  final double? stopLoss;
  final double? riskReward;
  final String? reasoning;
  final List<String>? matchReasons;
  final Map<String, bool>? gates;
  final int passedGates;
  final int totalGates;

  PersonaOpportunity({
    required this.ticker,
    this.name,
    this.nameAr,
    this.sector,
    this.score,
    this.signal,
    this.entryPrice,
    this.targetPrice,
    this.stopLoss,
    this.riskReward,
    this.reasoning,
    this.matchReasons,
    this.gates,
    this.passedGates = 0,
    this.totalGates = 5,
  });

  factory PersonaOpportunity.fromJson(Map<String, dynamic> json) {
    final rawGates = json['gates'] ?? json['gate_results'] ?? json['checks'];
    Map<String, bool>? gatesMap;
    if (rawGates is Map) {
      gatesMap = rawGates.map((k, v) => MapEntry(k.toString(), v == true || v == 'true' || v == 1 || v == '1'));
    }

    final passed = gatesMap?.values.where((v) => v).length ?? 0;
    final total = gatesMap?.length ?? 5;

    return PersonaOpportunity(
      ticker: json['ticker']?.toString() ?? json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? json['company']?.toString(),
      nameAr: json['name_ar']?.toString() ?? json['arabic_name']?.toString(),
      sector: json['sector']?.toString(),
      score: _toDouble(json['score'] ?? json['total_score'] ?? json['match_score']),
      signal: json['signal']?.toString() ?? json['action']?.toString() ?? json['recommendation']?.toString(),
      entryPrice: _toDouble(json['entry_price'] ?? json['entry'] ?? json['current_price']),
      targetPrice: _toDouble(json['target_price'] ?? json['target']),
      stopLoss: _toDouble(json['stop_loss'] ?? json['stopLoss']),
      riskReward: _toDouble(json['risk_reward'] ?? json['riskReward']),
      reasoning: json['reasoning']?.toString() ?? json['note']?.toString() ?? json['analysis']?.toString(),
      matchReasons: json['match_reasons'] is List
          ? (json['match_reasons'] as List).map((e) => e.toString()).toList()
          : null,
      gates: gatesMap,
      passedGates: passed,
      totalGates: total,
    );
  }

  String get displayName => nameAr ?? name ?? ticker;
  bool get isBuy => signal != null && (signal!.toUpperCase().contains('BUY') || signal!.toUpperCase().contains('شراء'));
  bool get isSell => signal != null && (signal!.toUpperCase().contains('SELL') || signal!.toUpperCase().contains('بيع'));
  bool get isHold => !isBuy && !isSell;

  Color get signalColor {
    if (isBuy) return const Color(0xFF22C55E);
    if (isSell) return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  String get signalLabel {
    if (isBuy) return 'شراء';
    if (isSell) return 'بيع';
    return 'حياد';
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class PersonaConfig {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final int minGates;
  final String? color;

  PersonaConfig({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.minGates,
    this.color,
  });

  factory PersonaConfig.fromJson(Map<String, dynamic> json) => PersonaConfig(
        id: json['id']?.toString() ?? json['key']?.toString() ?? '',
        name: json['name']?.toString() ?? json['id']?.toString() ?? '',
        nameAr: json['name_ar']?.toString() ?? json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        descriptionAr: json['description_ar']?.toString() ?? json['description']?.toString() ?? '',
        minGates: _toInt(json['min_gates'] ?? json['minGates']) ?? 3,
        color: json['color']?.toString(),
      );

  static int _toInt(dynamic value) {
    if (value == null) return 3;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 3;
    return 3;
  }
}

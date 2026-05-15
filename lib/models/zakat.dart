// ============================================================================
// مساعد الاستثمار Flutter - Zakat Types
// ============================================================================

import 'json_helpers.dart';

class ZakatCalculation {
  final double cash;
  final double goldSilver;
  final double stocks;
  final double receivables;
  final double otherAssets;
  final double debts;
  final double totalAssets;
  final double netZakatable;
  final double nisab;
  final double zakatDue;
  final double zakatRate;
  
  ZakatCalculation({
    required this.cash,
    required this.goldSilver,
    required this.stocks,
    required this.receivables,
    required this.otherAssets,
    required this.debts,
    required this.totalAssets,
    required this.netZakatable,
    required this.nisab,
    required this.zakatDue,
    required this.zakatRate
  });
  
  factory ZakatCalculation.fromJson(Map<String, dynamic> json) => ZakatCalculation(
        cash: parseDouble(json['cash']) ?? 0,
        goldSilver: parseDouble(json['gold_silver']) ?? 0,
        stocks: parseDouble(json['stocks']) ?? 0,
        receivables: parseDouble(json['receivables']) ?? 0,
        otherAssets: parseDouble(json['other_assets']) ?? 0,
        debts: parseDouble(json['debts']) ?? 0,
        totalAssets: parseDouble(json['total_assets']) ?? 0,
        netZakatable: parseDouble(json['net_zakatable']) ?? 0,
        nisab: parseDouble(json['nisab']) ?? 0,
        zakatDue: parseDouble(json['zakat_due']) ?? 0,
        zakatRate: parseDouble(json['zakat_rate']) ?? 0.025,
      );
}
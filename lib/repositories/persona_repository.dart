// ============================================================================
// مساعد الاستثمار Flutter - Persona Repository
// Handles persona-based market scanning and analysis
// ============================================================================

import 'dart:developer';
import '../../api/client.dart';

class PersonaRepository {
  PersonaRepository._();
  static final PersonaRepository _instance = PersonaRepository._();
  static PersonaRepository get instance => _instance;

  final GLMApiClient _api = GLMApiClient.instance;

  Future<List<dynamic>> getPersonas() async {
    try {
      return await _api.getUnifiedPersonas();
    } catch (e) {
      log('[PersonaRepository] getPersonas failed: $e');
      return _defaultPersonas();
    }
  }

  Future<Map<String, dynamic>> scanMarket({
    required String market,
    required String persona,
    int topN = 20,
    int minScore = 65,
  }) async {
    try {
      return await _api.scanUnifiedMarket(
        market: market,
        persona: persona,
        topN: topN,
        minScore: minScore,
      );
    } catch (e) {
      log('[PersonaRepository] scanMarket failed: $e');
      return {'results': [], 'persona': persona, 'market': market};
    }
  }

  Future<Map<String, dynamic>> analyzeStock({
    required String ticker,
    required String market,
    required String persona,
    double? support,
    double? resistance,
  }) async {
    try {
      return await _api.analyzeUnifiedStock(
        ticker: ticker,
        market: market,
        persona: persona,
        support: support,
        resistance: resistance,
      );
    } catch (e) {
      log('[PersonaRepository] analyzeStock failed: $e');
      return {'ticker': ticker, 'persona': persona, 'analysis': null};
    }
  }

  Future<Map<String, dynamic>> getMaestroAnalysis({
    required String ticker,
    required String market,
    required String persona,
  }) async {
    try {
      return await _api.getMaestroAnalysis(ticker, market: market, persona: persona);
    } catch (e) {
      log('[PersonaRepository] getMaestroAnalysis failed: $e');
      return {'ticker': ticker, 'analysis': null};
    }
  }

  Future<Map<String, dynamic>> getPersonaConfig({
    required String market,
    required String persona,
  }) async {
    try {
      return await _api.getUnifiedConfig(market: market, persona: persona);
    } catch (e) {
      log('[PersonaRepository] getPersonaConfig failed: $e');
      return {'persona': persona, 'market': market, 'config': null};
    }
  }

  List<Map<String, dynamic>> _defaultPersonas() {
    return [
      {
        'id': 'investor',
        'name': 'Investor',
        'name_ar': 'مستثمر',
        'description': 'Long-term value investor',
        'description_ar': 'مستثمر طويل الأمد يركز على القيمة',
        'min_gates': 3,
        'color': '#8B5CF6',
      },
      {
        'id': 'trader',
        'name': 'Trader',
        'name_ar': 'مضارب',
        'description': 'Short-term momentum trader',
        'description_ar': 'مضارب قصير الأمد يركز على الزخم',
        'min_gates': 2,
        'color': '#F97316',
      },
    ];
  }
}

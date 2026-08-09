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

  /// Hardcoded fallback for the 3-persona system. Mirrors
  /// `GLMApiClient.getUnifiedPersonas()` (lib/api/client.dart:1096) and the
  /// website's `src/lib/v2/persona-config.ts`. Persona IDs MUST be lowercase
  /// `gambler` / `balanced` / `conservative` to match the backend scoring
  /// engine — never `investor` / `trader`.
  List<Map<String, dynamic>> _defaultPersonas() {
    return [
      {
        'code': 'gambler',
        'id': 'gambler',
        'name': 'Gambler',
        'name_ar': 'المضارب',
        'icon': '🔥',
        'timeframe': 'يومي-أسبوعي',
        'description': 'مخاطر عالية جداً — زخم يومي/أسبوعي وفرص انفجارية',
        'description_ar': 'مضارب قصير الأمد يركز على الزخم',
        'stop_factor': 1.5,
        'target_factor': 1.8,
        'max_risk_percent': 4.5,
        'crypto_allowed': true,
        'color': '#ef4444',
        'min_gates': 2,
      },
      {
        'code': 'balanced',
        'id': 'balanced',
        'name': 'Balanced',
        'name_ar': 'المتوازن',
        'icon': '⚖️',
        'timeframe': '1-6 شهر',
        'description': 'توازن بين العائد والمخاطر — استثمار متوسط المدى',
        'description_ar': 'متوازن بين العائد والمخاطر',
        'stop_factor': 1.0,
        'target_factor': 1.0,
        'max_risk_percent': 2.0,
        'crypto_allowed': true,
        'color': '#eab308',
        'min_gates': 3,
      },
      {
        'code': 'conservative',
        'id': 'conservative',
        'name': 'Conservative',
        'name_ar': 'المحافظ',
        'icon': '🛡️',
        'timeframe': '3-12 شهر',
        'description': 'حماية رأس المال أولاً — فرص آمنة طويلة الأمد',
        'description_ar': 'مستثمر محافظ طويل الأمد',
        'stop_factor': 0.8,
        'target_factor': 1.2,
        'max_risk_percent': 1.0,
        'crypto_allowed': false,
        'color': '#3b82f6',
        'min_gates': 3,
      },
    ];
  }
}

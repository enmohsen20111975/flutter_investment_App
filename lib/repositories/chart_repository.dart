// ============================================================================
// مساعد الاستثمار Flutter - Chart Repository
// Handles chart data retrieval with column name normalization
// Maps API column names (close_price) to standard names (close)
// ============================================================================

import 'dart:developer';
import '../../api/client.dart';
import '../../api/local_database.dart';
import '../models/chart_data_model.dart';

class ChartRepository {
  ChartRepository._();
  static final ChartRepository _instance = ChartRepository._();
  static ChartRepository get instance => _instance;

  final GLMApiClient _api = GLMApiClient.instance;
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<ChartDataModel>> getHistory({
    required String ticker,
    int days = 30,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _localDb.getStockHistory(ticker, days: days);
      if (cached.isNotEmpty) {
        return cached.map((e) => ChartDataModel.fromJson(e)).toList();
      }
    }

    try {
      final response = await _api.getStockHistory(ticker, days: days);
      final mapped = response.data
          .map((e) {
            final map = <String, dynamic>{
              'date': e.date,
              'open': e.open,
              'high': e.high,
              'low': e.low,
              'close': e.close,
              'volume': e.volume,
            };
            return _mapColumns(map);
          })
          .where((e) => e != null)
          .cast<ChartDataModel>()
          .toList();

      if (mapped.isNotEmpty) {
        await _localDb.insertStockHistory(ticker, mapped.map((e) => e.toJson()).toList());
      }

      return mapped;
    } catch (e) {
      log('[ChartRepository] getHistory failed: $e');
      return [];
    }
  }

  Future<List<ChartDataModel>> getHistoryFromLocal(String ticker, {int days = 30}) async {
    final cached = await _localDb.getStockHistory(ticker, days: days);
    return cached.map((e) => ChartDataModel.fromJson(e)).toList();
  }

  Future<ChartDataModel?> getLatest(String ticker) async {
    final history = await getHistory(ticker: ticker, forceRefresh: false);
    if (history.isEmpty) return null;
    return history.last;
  }

  Map<String, dynamic> _mapColumns(Map<String, dynamic> raw) {
    return {
      'date': raw['date'] ?? raw['time'] ?? '',
      'open': raw['open_price'] ?? raw['open'] ?? raw['o'],
      'high': raw['high_price'] ?? raw['high'] ?? raw['h'],
      'low': raw['low_price'] ?? raw['low'] ?? raw['l'],
      'close': raw['close_price'] ?? raw['close'] ?? raw['c'] ?? raw['price'] ?? raw['current_price'],
      'volume': raw['volume'] ?? raw['v'],
    };
  }
}

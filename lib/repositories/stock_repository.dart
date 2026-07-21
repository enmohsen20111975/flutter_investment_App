// ============================================================================
// مساعد الاستثمار Flutter - Stock Repository
// Data layer for stock operations — abstracts API from UI
// ============================================================================

import '../../api/client.dart';
import '../models/stock_model.dart';
import '../models/prediction_model.dart';
import '../models/recommendation.dart';

class StockRepository {
  StockRepository._();
  static final StockRepository _instance = StockRepository._();
  static StockRepository get instance => _instance;

  final GLMApiClient _api = GLMApiClient.instance;

  Future<List<StockModel>> getStocks({String? market, int page = 1, int pageSize = 20}) async {
    final data = await _api.getStocks(market: market);
    final rawList = data['stocks'] ?? data['data'] ?? data['items'] ?? [];
    if (rawList is! List) return [];
    return rawList
        .map((e) => e is Map ? StockModel.fromJson(Map<String, dynamic>.from(e)) : null)
        .where((e) => e != null)
        .cast<StockModel>()
        .toList();
  }

  Future<List<StockModel>> getMarketMovers({String type = 'gainers', String? market}) async {
    final data = await _api.getStockMovementClassification(market: market);
    final rawList = data[type] ?? data['$type'] ?? [];
    if (rawList is! List) return [];
    return rawList
        .map((e) => e is Map ? StockModel.fromJson(Map<String, dynamic>.from(e)) : null)
        .where((e) => e != null)
        .cast<StockModel>()
        .toList();
  }

  Future<StockModel?> getStockDetail(String ticker) async {
    final data = await _api.getStockDetail(ticker);
    final rawData = data['data'] ?? data;
    if (rawData is Map) {
      return StockModel.fromJson(Map<String, dynamic>.from(rawData));
    }
    return null;
  }

  Future<List<PredictionModel>> getPredictions({int? limit, String? status}) async {
    final rawList = await _api.getMobilePredictions(limit: limit, status: status);
    if (rawList is! List) return [];
    return rawList
        .map((e) => e is Map ? PredictionModel.fromJson(Map<String, dynamic>.from(e)) : null)
        .where((e) => e != null)
        .cast<PredictionModel>()
        .toList();
  }

  Future<Recommendation?> getRecommendation(String ticker) async {
    final data = await _api.getStockRecommendation(ticker);
    final rawRec = data['recommendation'] ?? data['data'];
    if (rawRec is Map) {
      return Recommendation.fromJson(Map<String, dynamic>.from(rawRec));
    }
    return null;
  }
}

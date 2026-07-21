// ============================================================================
// مساعد الاستثمار Flutter - Type Definitions (Barrel Export)
// ============================================================================

// Export all type files for backward compatibility
export 'stock.dart';
export 'stock_model.dart';
export 'prediction_model.dart';
export 'chart_data_model.dart';
export 'persona_model.dart';
export 'market.dart';
export 'gold.dart';
export 'crypto.dart';
export 'portfolio.dart';
export 'watchlist.dart';
export 'user.dart';
export 'recommendation.dart';
export 'zakat.dart';

// API Error
class ApiError {
  final String message;
  final int? status;
  ApiError({required this.message, this.status});
}
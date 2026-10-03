// ============================================================================
// مساعد الاستثمار Flutter - Sharia Compliance Models
// نماذج التوافق الشرعي + نسب التطهير
//
// Mirrors the backend tables populated by
// data_engine/scrapers/sharia_compliance_scraper.py (weekly, crontab #25)
// and read by /api/sharia (src/app/api/sharia/route.ts) +
// /api/sharia/purification (src/app/api/sharia/purification/route.ts).
//
// Tables (data_engine.db):
//   sharia_metrics             — one row per EGX stock (consensus + flags)
//   sharia_source_status       — 8 sources × many stocks (per-source verdict)
//   sharia_purification_rates  — per-method purification rate per stock
//   sharia_sources             — source catalog (name_ar, methodology, is_active)
//   sharia_symbol_map          — alias resolution (EFG↔HRHO etc.)
// ============================================================================
//
// Task 28-A Fix 10: 5 typed models for the Sharia feature.
// API methods (Fix 9): GLMApiClient.getShariaList / getShariaDetail /
// calculatePurification. UI consumes these models in a future Sharia
// screen + ShariaBadge widget (out of scope for Task 28-A per spec).
// ============================================================================

import 'json_helpers.dart';

// ============================================================================
// ShariaStockMetric — one row per EGX stock.
// Mirrors columns of sharia_metrics table (SQL schema in
// data_engine/scrapers/sharia_compliance_scraper.py).
// ============================================================================
class ShariaStockMetric {
  final String symbol;
  final String? nameAr;
  final String? categoryAr;
  final String? category;
  final String? market;

  // Purification inputs (percents 0..100).
  final double? spHaramEarningPct;       // S&P method haram-earnings %
  final double? haramEarningsPct;
  final double? loansPct;
  final double? zakatPerShare;
  final double? dividend;
  final double? dividendYield;

  // Boolean compliance gates.
  final bool? coreActivityOk;
  final bool? cashLiquidityOk;
  final bool? haramInvestmentsOk;

  // Source-count summary.
  final int? compliantSourcesCount;      // out of active_sources_count
  final int? activeSourcesCount;
  final bool? isHalalConsensus;          // compliant_sources_count ≥ consensus_min (6)

  // Sync metadata.
  final String? sourceUpdatedMax;        // ISO date of newest source verdict
  final String? syncedAt;                // ISO timestamp of last scraper run

  // Alias resolution (sharia_symbol_map).
  final String? rawSymbol;               // upstream ticker before resolution
  final String? aliasMethod;             // 'direct' | 'manual_map' | 'fuzzy'
  final String? aliasConfidence;         // 'high' | 'medium' | 'low' | null
  final bool? needsReview;               // human review required

  // Joined columns (computed by /api/sharia list query).
  final double? purificationRate;        // primary_method rate_pct (joined)
  final List<String> compliantSources;   // comma-joined source_key list (joined)

  const ShariaStockMetric({
    required this.symbol,
    this.nameAr,
    this.categoryAr,
    this.category,
    this.market,
    this.spHaramEarningPct,
    this.haramEarningsPct,
    this.loansPct,
    this.zakatPerShare,
    this.dividend,
    this.dividendYield,
    this.coreActivityOk,
    this.cashLiquidityOk,
    this.haramInvestmentsOk,
    this.compliantSourcesCount,
    this.activeSourcesCount,
    this.isHalalConsensus,
    this.sourceUpdatedMax,
    this.syncedAt,
    this.rawSymbol,
    this.aliasMethod,
    this.aliasConfidence,
    this.needsReview,
    this.purificationRate,
    this.compliantSources = const [],
  });

  factory ShariaStockMetric.fromJson(Map<String, dynamic> j) {
    return ShariaStockMetric(
      symbol: (j['symbol'] ?? j['ticker'] ?? '').toString().toUpperCase(),
      nameAr: parseString(j['name_ar']),
      categoryAr: parseString(j['category_ar']),
      category: parseString(j['category']),
      market: parseString(j['market']),
      spHaramEarningPct: parseDouble(j['sp_haram_earning_pct']),
      haramEarningsPct: parseDouble(j['haram_earnings_pct']),
      loansPct: parseDouble(j['loans_pct']),
      zakatPerShare: parseDouble(j['zakat_per_share']),
      dividend: parseDouble(j['dividend']),
      dividendYield: parseDouble(j['dividend_yield']),
      coreActivityOk: parseBool(j['core_activity_ok']),
      cashLiquidityOk: parseBool(j['cash_liquidity_ok']),
      haramInvestmentsOk: parseBool(j['haram_investments_ok']),
      compliantSourcesCount: parseInt(j['compliant_sources_count']),
      activeSourcesCount: parseInt(j['active_sources_count']),
      isHalalConsensus: parseBool(j['is_halal_consensus']),
      sourceUpdatedMax: parseString(j['source_updated_max']),
      syncedAt: parseString(j['synced_at']),
      rawSymbol: parseString(j['raw_symbol']),
      aliasMethod: parseString(j['alias_method']),
      aliasConfidence: parseString(j['alias_confidence']),
      needsReview: parseBool(j['needs_review']),
      purificationRate: parseDouble(j['purification_rate']),
      compliantSources: parseStringList(j['compliant_sources']),
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name_ar': nameAr,
        'category_ar': categoryAr,
        'category': category,
        'market': market,
        'sp_haram_earning_pct': spHaramEarningPct,
        'haram_earnings_pct': haramEarningsPct,
        'loans_pct': loansPct,
        'zakat_per_share': zakatPerShare,
        'dividend': dividend,
        'dividend_yield': dividendYield,
        'core_activity_ok': coreActivityOk,
        'cash_liquidity_ok': cashLiquidityOk,
        'haram_investments_ok': haramInvestmentsOk,
        'compliant_sources_count': compliantSourcesCount,
        'active_sources_count': activeSourcesCount,
        'is_halal_consensus': isHalalConsensus,
        'source_updated_max': sourceUpdatedMax,
        'synced_at': syncedAt,
        'raw_symbol': rawSymbol,
        'alias_method': aliasMethod,
        'alias_confidence': aliasConfidence,
        'needs_review': needsReview,
        'purification_rate': purificationRate,
        'compliant_sources': compliantSources.join(','),
      };
}

// ============================================================================
// ShariaSourceRow — per-source verdict for one stock.
// Mirrors sharia_source_status table + LEFT JOIN sharia_sources catalog.
// ============================================================================
class ShariaSourceRow {
  final String sourceKey;        // 'sp' | 'musaffa' | 'kashif' | 'osoul' | ...
  final String? sourceNameAr;
  final String? status;          // 'compliant' | 'non_compliant' | 'doubtful' | 'unknown'
  final double? percentage;      // haram-earning % per this source
  final String? note;
  final String? sector;
  final String? grade;           // 'A' | 'B' | 'C' | null
  final String? statementDate;   // ISO date of the source's statement
  final String? sourceUpdated;    // ISO timestamp of last scrape
  final String? methodology;      // from sharia_sources catalog
  final bool? isActive;           // from sharia_sources catalog

  const ShariaSourceRow({
    required this.sourceKey,
    this.sourceNameAr,
    this.status,
    this.percentage,
    this.note,
    this.sector,
    this.grade,
    this.statementDate,
    this.sourceUpdated,
    this.methodology,
    this.isActive,
  });

  factory ShariaSourceRow.fromJson(Map<String, dynamic> j) {
    return ShariaSourceRow(
      sourceKey: (j['source_key'] ?? '').toString(),
      sourceNameAr: parseString(j['source_name_ar']),
      status: parseString(j['status']),
      percentage: parseDouble(j['percentage']),
      note: parseString(j['note']),
      sector: parseString(j['sector']),
      grade: parseString(j['grade']),
      statementDate: parseString(j['statement_date']),
      sourceUpdated: parseString(j['source_updated']),
      methodology: parseString(j['methodology']),
      isActive: parseBool(j['is_active']),
    );
  }

  Map<String, dynamic> toJson() => {
        'source_key': sourceKey,
        'source_name_ar': sourceNameAr,
        'status': status,
        'percentage': percentage,
        'note': note,
        'sector': sector,
        'grade': grade,
        'statement_date': statementDate,
        'source_updated': sourceUpdated,
        'methodology': methodology,
        'is_active': isActive,
      };
}

// ============================================================================
// ShariaPurificationRate — per-method purification rate for one stock.
// Mirrors sharia_purification_rates table.
// ============================================================================
class ShariaPurificationRate {
  final String methodKey;        // 'S&P' | 'MUSAFFA' | 'KASHIF' | 'OSOUL' | ...
  final String? methodNameAr;
  final double? ratePct;         // 0..100 — % of profits to purify
  final String? basis;           // short text describing calculation basis
  final bool? isPrimary;         // true = primary method (S&P for EGX)
  final String? sourceUpdated;

  const ShariaPurificationRate({
    required this.methodKey,
    this.methodNameAr,
    this.ratePct,
    this.basis,
    this.isPrimary,
    this.sourceUpdated,
  });

  factory ShariaPurificationRate.fromJson(Map<String, dynamic> j) {
    return ShariaPurificationRate(
      methodKey: (j['method_key'] ?? '').toString(),
      methodNameAr: parseString(j['method_name_ar']),
      ratePct: parseDouble(j['rate_pct']),
      basis: parseString(j['basis']),
      isPrimary: parseBool(j['is_primary']),
      sourceUpdated: parseString(j['source_updated']),
    );
  }

  Map<String, dynamic> toJson() => {
        'method_key': methodKey,
        'method_name_ar': methodNameAr,
        'rate_pct': ratePct,
        'basis': basis,
        'is_primary': isPrimary,
        'source_updated': sourceUpdated,
      };
}

// ============================================================================
// ShariaDetailResponse — envelope of GET /api/sharia?symbol=X.
// Top-level fields + nested sources/rates arrays + price join.
// ============================================================================
class ShariaDetailResponse {
  final bool success;
  final String symbol;
  final ShariaStockMetric? metric;
  final List<ShariaSourceRow> sources;
  final List<ShariaPurificationRate> purificationRates;
  final Map<String, dynamic>? price;  // raw row from stocks.db ({ticker,name,current_price,...})
  final String? generatedAt;

  const ShariaDetailResponse({
    required this.success,
    required this.symbol,
    this.metric,
    this.sources = const [],
    this.purificationRates = const [],
    this.price,
    this.generatedAt,
  });

  factory ShariaDetailResponse.fromJson(Map<String, dynamic> j) {
    final metricRaw = j['metric'];
    return ShariaDetailResponse(
      success: parseBool(j['success']) ?? false,
      symbol: (j['symbol'] ?? '').toString().toUpperCase(),
      metric: metricRaw is Map<String, dynamic>
          ? ShariaStockMetric.fromJson(metricRaw)
          : null,
      sources: (j['sources'] is List)
          ? (j['sources'] as List)
              .whereType<Map>()
              .map((m) => ShariaSourceRow.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      purificationRates: (j['purification_rates'] is List)
          ? (j['purification_rates'] as List)
              .whereType<Map>()
              .map((m) => ShariaPurificationRate.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      price: j['price'] is Map ? Map<String, dynamic>.from(j['price']) : null,
      generatedAt: parseString(j['generated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'symbol': symbol,
        'metric': metric?.toJson(),
        'sources': sources.map((s) => s.toJson()).toList(),
        'purification_rates': purificationRates.map((r) => r.toJson()).toList(),
        'price': price,
        'generated_at': generatedAt,
      };
}

// ============================================================================
// PurificationResult — envelope of POST /api/sharia/purification.
//
// The python calculator (vps-service/portfolio/purification_calculator.py)
// returns a JSON payload whose fields depend on the input mode:
//
//   single-trade mode ({symbol, quantity, buy_price, sell_price}):
//     {purification_amount, purification_rate_pct, total_profit,
//      haram_earnings, halal_earnings, method, ...}
//
//   portfolio mode ({user_id, include_capital_gain}):
//     {purification_total, holdings:[{symbol, qty, profit, rate,
//       purification_amount, ...}], grand_totals:{...}, ...}
//
// This class captures the common envelope (success + primary_method +
// engine + raw payload) and exposes the calculator output via `payload`.
// ============================================================================
class PurificationResult {
  final bool success;
  final String? primaryMethod;    // 'S&P' for EGX (default).
  final String? engine;           // 'vps-service/portfolio/purification_calculator.py'
  final String? error;            // 'calculator_missing' | 'invalid_request' | 'calculator_failed' | ...
  final String? detail;           // human-readable error detail (on failure).
  final Map<String, dynamic> payload;  // raw payload from the python calculator.

  const PurificationResult({
    required this.success,
    this.primaryMethod,
    this.engine,
    this.error,
    this.detail,
    this.payload = const {},
  });

  factory PurificationResult.fromJson(Map<String, dynamic> j) {
    // The python calculator's payload is mixed inline with the route's
    // envelope. Keep the full body as `payload` so callers can read any
    // field they care about, without us having to predict the schema.
    final payload = Map<String, dynamic>.from(j);
    // Strip the envelope fields we already promoted to typed members.
    payload
      ..remove('success')
      ..remove('primary_method')
      ..remove('engine')
      ..remove('error')
      ..remove('detail');

    return PurificationResult(
      success: parseBool(j['success']) ?? false,
      primaryMethod: parseString(j['primary_method']),
      engine: parseString(j['engine']),
      error: parseString(j['error']),
      detail: parseString(j['detail']),
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'primary_method': primaryMethod,
        'engine': engine,
        'error': error,
        'detail': detail,
        ...payload,
      };
}

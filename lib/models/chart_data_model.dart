// ============================================================================
// مساعد الاستثمار Flutter - Chart Data Model
// Typed chart data point with date, OHLC, and volume
// ============================================================================

class ChartDataModel {
  final String date;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final int? volume;

  ChartDataModel({
    required this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
  });

  factory ChartDataModel.fromJson(Map<String, dynamic> json) => ChartDataModel(
        date: json['date']?.toString() ?? json['time']?.toString() ?? '',
        open: _toDouble(json['open'] ?? json['open_price']),
        high: _toDouble(json['high'] ?? json['high_price']),
        low: _toDouble(json['low'] ?? json['low_price']),
        close: _toDouble(json['close'] ?? json['close_price'] ?? json['price'] ?? json['current_price']),
        volume: _toInt(json['volume']),
      );

  factory ChartDataModel.fromApi(Map<String, dynamic> json) {
    final mapped = <String, dynamic>{
      'date': json['date'] ?? json['time'] ?? '',
      'open': json['open_price'] ?? json['open'],
      'high': json['high_price'] ?? json['high'],
      'low': json['low_price'] ?? json['low'],
      'close': json['close_price'] ?? json['close'] ?? json['price'] ?? json['current_price'],
      'volume': json['volume'],
    };
    return ChartDataModel.fromJson(mapped);
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
      };

  ChartDataModel copyWith({
    String? date,
    double? open,
    double? high,
    double? low,
    double? close,
    int? volume,
  }) {
    return ChartDataModel(
      date: date ?? this.date,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      volume: volume ?? this.volume,
    );
  }

  bool get isGreen => close != null && open != null && close! >= open!;
  bool get isRed => close != null && open != null && close! < open!;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ChartDataResponse {
  final bool success;
  final String? ticker;
  final List<ChartDataModel> data;
  final String? error;

  ChartDataResponse({
    this.success = true,
    this.ticker,
    this.data = const [],
    this.error,
  });

  factory ChartDataResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final listData = rawData is List ? rawData : [];
    final chartList = listData
        .map((e) => e is Map
            ? ChartDataModel.fromJson(Map<String, dynamic>.from(e))
            : null)
        .where((e) => e != null)
        .cast<ChartDataModel>()
        .toList();

    return ChartDataResponse(
      success: json['success'] != false,
      ticker: json['ticker']?.toString(),
      data: chartList,
      error: json['error']?.toString(),
    );
  }
}

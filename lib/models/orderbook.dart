// ============================================================================
// مساعد الاستثمار Flutter - OrderBook Model
// Depth of market (Bids and Asks)
// ============================================================================

class OrderBookEntry {
  final double price;
  final int volume;
  final int ordersCount;

  OrderBookEntry({
    required this.price,
    required this.volume,
    this.ordersCount = 1,
  });

  factory OrderBookEntry.fromJson(Map<String, dynamic> json) {
    return OrderBookEntry(
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      ordersCount: (json['orders_count'] ?? json['count'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'price': price,
        'volume': volume,
        'orders_count': ordersCount,
      };
}

class OrderBook {
  final String symbol;
  final List<OrderBookEntry> bids; // طلبات الشراء
  final List<OrderBookEntry> asks; // عروض البيع
  final DateTime? timestamp;

  OrderBook({
    required this.symbol,
    required this.bids,
    required this.asks,
    this.timestamp,
  });

  factory OrderBook.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json);

    var rawBids = (data['bids'] ?? json['bids']) as List? ?? [];
    var rawAsks = (data['asks'] ?? json['asks']) as List? ?? [];

    return OrderBook(
      symbol: json['symbol'] ?? json['ticker'] ?? data['symbol'] ?? data['ticker'] ?? '',
      bids: rawBids
          .map((item) => OrderBookEntry.fromJson(
              item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}))
          .toList(),
      asks: rawAsks
          .map((item) => OrderBookEntry.fromJson(
              item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}))
          .toList(),
      timestamp: json['timestamp'] != null || data['timestamp'] != null
          ? DateTime.tryParse((json['timestamp'] ?? data['timestamp']).toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'bids': bids.map((e) => e.toJson()).toList(),
        'asks': asks.map((e) => e.toJson()).toList(),
        'timestamp': timestamp?.toIso8601String(),
      };
}

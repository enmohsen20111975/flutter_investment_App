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
    var rawBids = json['bids'] as List? ?? [];
    var rawAsks = json['asks'] as List? ?? [];

    return OrderBook(
      symbol: json['symbol'] ?? json['ticker'] ?? '',
      bids: rawBids.map((item) => OrderBookEntry.fromJson(item)).toList(),
      asks: rawAsks.map((item) => OrderBookEntry.fromJson(item)).toList(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
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

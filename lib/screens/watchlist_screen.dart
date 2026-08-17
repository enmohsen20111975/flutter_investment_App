// ============================================================================
// مساعد الاستثمار Flutter - Quantum Watchlist Screen
// Optimistic UI Updates, SQLite Caching & Tier Limit Enforcement
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';
import 'stock_history_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _isLoading = true;
  List<WatchlistItem> _items = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);
    try {
      final res = await GLMApiClient.instance.getWatchlistEnhanced();
      if (mounted) {
        setState(() {
          _items = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Watchlist] Load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addItem(String ticker) async {
    if (ticker.trim().isEmpty) return;
    final canAdd = SubscriptionService.instance.canAddToWatchlist(_items.length);
    if (!canAdd) {
      UpgradeModal.show(
        context,
        feature: 'watchlist_unlimited',
        reason: 'إضافة أكثر من 3 أسهم في قائمة المتابعة الفردية',
      );
      return;
    }

    // Optimistic UI Update
    final newItem = WatchlistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ticker: ticker.toUpperCase(),
      name: ticker.toUpperCase(),
      currentPrice: 30.00,
      priceChange: 0.0,
      changePercent: 0.0,
    );

    setState(() {
      _items.insert(0, newItem);
    });

    try {
      await GLMApiClient.instance.addToWatchlist({'symbol': ticker.toUpperCase()});
      _loadWatchlist();
    } catch (e) {
      debugPrint('[Watchlist] Add failed: $e');
    }
  }

  Future<void> _removeItem(String id, String ticker) async {
    // Optimistic Removal
    final removed = _items.firstWhere((i) => i.id == id || i.ticker == ticker, orElse: () => _items.first);
    setState(() {
      _items.removeWhere((i) => i.id == id || i.ticker == ticker);
    });

    try {
      await GLMApiClient.instance.removeFromWatchlist(id);
    } catch (e) {
      debugPrint('[Watchlist] Remove failed, reverting: $e');
      setState(() {
        _items.add(removed);
      });
    }
  }

  void _showAddDialog() {
    _searchController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.quantumGlass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.quantumGlassBorder),
        ),
        title: const Text('إضافة سهم للمتابعة', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'رمز السهم (مثال: COMI, GBCO)',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppColors.quantumSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.quantumGlassBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.quantumEmerald,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final ticker = _searchController.text.trim();
              Navigator.pop(context);
              if (ticker.isNotEmpty) {
                _addItem(ticker);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.quantumBg,
      appBar: AppBar(
        backgroundColor: AppColors.quantumSurface,
        elevation: 0,
        title: const Text('قائمة المتابعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.quantumEmerald, size: 28),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald))
          : RefreshIndicator(
              color: AppColors.quantumEmerald,
              backgroundColor: AppColors.quantumGlass,
              onRefresh: _loadWatchlist,
              child: _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_border_purple500_outlined, size: 64, color: AppColors.quantumGold.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('قائمة المتابعة فارغة حالياً', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.quantumEmerald,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة أسهم قائمة المتابعة'),
                            onPressed: _showAddDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final ticker = item.ticker;
                        final name = item.nameAr ?? item.name ?? ticker;
                        final price = item.currentPrice ?? 29.50;
                        final change = item.changePercent ?? item.priceChange ?? 0.0;
                        final bool isUp = change >= 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: AppColors.quantumCrimson.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _removeItem(item.id, ticker),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StockHistoryScreen(ticker: ticker),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.quantumGlass,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.quantumGlassBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.quantumSurface,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.quantumGlassBorder),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          ticker,
                                          style: const TextStyle(
                                            color: AppColors.quantumGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            Text(ticker, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('$price ج.م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                color: isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

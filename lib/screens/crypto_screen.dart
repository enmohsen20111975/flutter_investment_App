// ============================================================================
// مساعد الاستثمار Flutter - Crypto Screen
// Shows cryptocurrency market list with navigation to detail
// Uses: GET /api/crypto
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import 'crypto_detail_screen.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});
  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  List<CryptoAsset> _assets = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer loading to post-frame callback to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });
      final response = await api.getCrypto();

      // The API may return data in different formats:
      // 1. { "data": [...] } - standard format
      // 2. { "coins": [...] } - alternative format
      // 3. Direct list
      List<dynamic> cryptoList;
      if (response['data'] is List) {
        cryptoList = response['data'] as List;
      } else if (response['coins'] is List) {
        cryptoList = response['coins'] as List;
      } else if (response is List) {
        cryptoList = response as List;
      } else {
        cryptoList = [];
      }

      final data = cryptoList.map((e) => CryptoAsset.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _assets = data; _loading = false; _refreshing = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _refreshing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async { setState(() => _refreshing = true); await _loadData(silent: true); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const HeaderCard(icon: Icons.currency_bitcoin, title: 'العملات الرقمية', subtitle: 'تتبع أسعار الكريبتو لحظياً'),
            const SizedBox(height: 16),
            StateView(loading: _loading, error: _error, onRetry: () => _loadData()),
            if (!_loading && _error == null) ...[
              if (_assets.isEmpty)
                const StateView(empty: true, emptyMessage: 'لا توجد عملات رقمية متاحة')
              else
                ..._assets.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DataRowWidget(
                    title: a.name,
                    subtitle: '${a.symbol.toUpperCase()} #${a.marketCapRank ?? '-'}',
                    value: a.currentPrice != null ? '\$${_formatPrice(a.currentPrice!)}' : '-',
                    change: a.priceChangePercentage24h,
                    icon: Icons.currency_bitcoin,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CryptoDetailScreen(coinId: a.id, coinName: a.name),
                    )),
                  ),
                )),
            ],
            const SizedBox(height: 90),
          ]),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) return price.toStringAsFixed(2);
    if (price >= 1) return price.toStringAsFixed(4);
    if (price >= 0.01) return price.toStringAsFixed(6);
    return price.toStringAsFixed(8);
  }
}

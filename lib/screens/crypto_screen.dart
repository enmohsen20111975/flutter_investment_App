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

class _CryptoScreenState extends State<CryptoScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Future<List<CryptoAsset>>? _assetsFuture;

  @override
  void initState() {
    super.initState();
    _assetsFuture = _fetchAssets();
  }

  Future<List<CryptoAsset>> _fetchAssets() async {
    final response = await api.getCrypto();
    List<dynamic> cryptoList;
    // FIX: API returns data.all_cryptos, not data as List
    final data = response['data'];
    if (data is Map && data['all_cryptos'] is List) {
      cryptoList = data['all_cryptos'] as List;
    } else if (data is List) {
      cryptoList = data;
    } else if (response['coins'] is List) {
      cryptoList = response['coins'] as List;
    } else if (response is List) {
      cryptoList = response as List;
    } else {
      cryptoList = [];
    }
    return cryptoList
        .whereType<Map<String, dynamic>>()
        .map((e) => CryptoAsset.fromJson(e))
        .toList();
  }

  Future<void> _refresh() async {
    _assetsFuture = _fetchAssets();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const HeaderCard(icon: Icons.currency_bitcoin, title: 'العملات الرقمية', subtitle: 'تتبع أسعار الكريبتو لحظياً'),
            const SizedBox(height: 16),
            FutureBuilder<List<CryptoAsset>>(
              future: _assetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return StateView(error: snapshot.error.toString(), onRetry: _refresh);
                }
                final assets = snapshot.data ?? [];
                if (assets.isEmpty) {
                  return const StateView(empty: true, emptyMessage: 'لا توجد عملات رقمية متاحة');
                }
                return Column(
                  children: [
                    ...assets.map((a) => Padding(
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
                );
              },
            ),
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

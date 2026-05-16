// ============================================================================
// مساعد الاستثمار Flutter - Dashboard Screen
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../widgets/state_view.dart' as widgets;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MarketOverview? _data;
  Map<String, dynamic>? _liveData;
  Map<String, dynamic>? _investingData;
  bool _loading = true;
  String? _error;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });
      final results = await Future.wait([
        api.getMarketOverview(),
        api.getMarketLiveData().catchError((_) => <String, dynamic>{}),
        api.getMarketInvesting().catchError((_) => <String, dynamic>{}),
      ]);
      _data = results[0] as MarketOverview;
      _liveData = results[1] as Map<String, dynamic>?;
      _investingData = results[2] as Map<String, dynamic>?;
      setState(() { _loading = false; _refreshing = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _refreshing = false; });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await _loadData(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const StateView(loading: true)
          : _error != null
              ? StateView(error: _error, onRetry: () => _loadData())
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeader(),
                        const SizedBox(height: 20),
                        _buildSummaryCards(),
                        const SizedBox(height: 20),
                        if (_liveData != null && _liveData!.isNotEmpty) ...[
                          _buildLiveDataSection(),
                          const SizedBox(height: 20),
                        ],
                        _buildIndicesSection(),
                        const SizedBox(height: 20),
                        _buildTopStocksSection(),
                        const SizedBox(height: 20),
                        if (_investingData != null && _investingData!.isNotEmpty) ...[
                          _buildInvestingSection(),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight]),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.trending_up, color: AppColors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text('مساعد الاستثمار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white)),
                    Text('لوحة التحكم', style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                _data?.marketStatus?.isMarketHours == true ? 'السوق مفتوح' : 'السوق مغلق',
                _data?.marketStatus?.isMarketHours == true ? Icons.check_circle : Icons.cancel,
              ),
              const SizedBox(width: 8),
              if (_data?.lastUpdated != null)
                _buildStatChip(_data!.lastUpdated!, Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _data?.summary;
    return Row(
      children: [
        Expanded(child: _buildMiniCard('الأسهم', '${summary?.totalStocks ?? '-'}', Icons.bar_chart, AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniCard('ارتفاعات', '${summary?.gainers ?? '-'}', Icons.trending_up, AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniCard('انخفاضات', '${summary?.losers ?? '-'}', Icons.trending_down, AppColors.danger)),
      ],
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildIndicesSection() {
    final indices = _data?.indices ?? [];
    if (indices.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SectionHeader(title: 'المؤشرات', icon: Icons.analytics),
        const SizedBox(height: 8),
        ...indices.map((idx) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DataRowWidget(
            title: idx.nameAr ?? idx.name ?? idx.symbol,
            value: idx.value?.toStringAsFixed(2) ?? '-',
            change: idx.changePercent,
            icon: Icons.show_chart,
          ),
        )),
      ],
    );
  }

  Widget _buildTopStocksSection() {
    final gainers = _data?.topGainers ?? [];
    final losers = _data?.topLosers ?? [];

    return Column(
      children: [
        if (gainers.isNotEmpty) ...[
          const SectionHeader(title: 'أعلى الأسهم ارتفاعاً', icon: Icons.trending_up),
          const SizedBox(height: 8),
          ...gainers.take(5).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DataRowWidget(
              title: s.nameAr ?? s.name ?? s.ticker,
              subtitle: s.ticker,
              value: s.currentPrice?.toStringAsFixed(2) ?? '-',
              change: s.changePercent,
              icon: Icons.trending_up,
            ),
          )),
          const SizedBox(height: 16),
        ],
        if (losers.isNotEmpty) ...[
          const SectionHeader(title: 'أعلى الأسهم انخفاضاً', icon: Icons.trending_down),
          const SizedBox(height: 8),
          ...losers.take(5).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DataRowWidget(
              title: s.nameAr ?? s.name ?? s.ticker,
              subtitle: s.ticker,
              value: s.currentPrice?.toStringAsFixed(2) ?? '-',
              change: s.changePercent,
              icon: Icons.trending_down,
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildLiveDataSection() {
    final ld = _liveData!;
    final stocks = (ld['stocks'] as List?) ?? [];
    final lastUpdated = ld['last_updated']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.live_tv, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          const Text('بيانات مباشرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (lastUpdated.isNotEmpty)
            Text(lastUpdated.substring(0, lastUpdated.length > 16 ? 16 : lastUpdated.length),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 8),
        ...stocks.take(5).map((s) {
          final m = s as Map<String, dynamic>;
          final ticker = m['ticker'] ?? m['symbol'] ?? '';
          final price = (m['current_price'] as num?)?.toDouble() ?? 0;
          final change = (m['change_percent'] as num?)?.toDouble() ?? 0;
          final isUp = change >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 16, color: isUp ? AppColors.success : AppColors.danger),
              const SizedBox(width: 8),
              Expanded(child: Text(ticker, style: AppTypography.bodyMedium)),
              Text('${price.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
              const SizedBox(width: 8),
              Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isUp ? AppColors.success : AppColors.danger)),
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildInvestingSection() {
    final inv = _investingData!;
    final items = (inv['data'] as List?) ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'بيانات Investing.com', icon: Icons.language),
        const SizedBox(height: 8),
        ...items.take(5).map((item) {
          final m = item as Map<String, dynamic>;
          final name = m['name'] ?? m['symbol'] ?? '';
          final price = (m['price'] as num?)?.toDouble() ?? 0;
          final change = (m['change_percent'] as num?)?.toDouble() ?? 0;
          final isUp = change >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 16, color: isUp ? AppColors.success : AppColors.danger),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: AppTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('${price.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
              const SizedBox(width: 8),
              Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isUp ? AppColors.success : AppColors.danger)),
            ]),
          );
        }),
      ],
    );
  }
}

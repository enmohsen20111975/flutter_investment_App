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
      final data = await api.getMarketOverview();
      setState(() { _data = data; _loading = false; _refreshing = false; });
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
                        _buildIndicesSection(),
                        const SizedBox(height: 20),
                        _buildTopStocksSection(),
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
}

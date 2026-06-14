// ============================================================================
// مساعد الاستثمار Flutter - Dashboard Screen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../widgets/bubble_buttons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.marketVersion = 0});

  final int marketVersion;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<MarketOverview?>? _overviewFuture;
  Future<Map<String, dynamic>?>? _liveDataFuture;
  Future<Map<String, dynamic>?>? _investingDataFuture;
  MarketOverview? _data;
  Map<String, dynamic>? _liveData;
  Map<String, dynamic>? _investingData;
  String _activeMarket = 'EGX';

  @override
  void initState() {
    super.initState();
    _loadMarketAndFetch();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadMarketAndFetch();
    }
  }

  Future<void> _loadMarketAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeMarket = prefs.getString('active_market') ?? 'EGX';
        _overviewFuture = _fetchOverview(_activeMarket);
        _liveDataFuture = _fetchLiveData(_activeMarket);
        _investingDataFuture = _fetchInvestingData(_activeMarket);
      });
    }
  }

  Future<MarketOverview?> _fetchOverview(String market) async {
    try {
      return await api.getMarketOverview(market);
    } catch (e) {
      debugPrint('[Dashboard] Overview error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchLiveData(String market) async {
    try {
      _liveData = await api.getMarketLiveData(market);
      return _liveData;
    } catch (e) {
      debugPrint('[Dashboard] Live data error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchInvestingData(String market) async {
    try {
      _investingData = await api.getMarketInvesting(market);
      return _investingData;
    } catch (e) {
      debugPrint('[Dashboard] Investing data error: $e');
      return null;
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _data = null;
      _liveData = null;
      _investingData = null;
    });
    await _loadMarketAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: BubbleFloatingButton(
        icon: Icons.refresh,
        label: 'تحديث',
        extended: true,
        onPressed: _refreshAll,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 20),
              FutureBuilder<MarketOverview?>(
                future: _overviewFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'خطأ في تحميل البيانات: ${snapshot.error}',
                        onRetry: _refreshAll);
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    _data = snapshot.data;
                    return Column(
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 20),
                        _buildIndicesSection(),
                        const SizedBox(height: 20),
                        _buildTopStocksSection(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>?>(
                future: _liveDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingIndicator(
                        text: 'جاري تحميل البيانات المباشرة...');
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'خطأ في البيانات المباشرة: ${snapshot.error}',
                        onRetry: _refreshAll);
                  }
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.isNotEmpty) {
                    return _buildLiveDataSection();
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>?>(
                future: _investingDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingIndicator(
                        text: 'جاري تحميل بيانات Investing.com...');
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'خطأ في بيانات Investing: ${snapshot.error}',
                        onRetry: _refreshAll);
                  }
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.isNotEmpty) {
                    return _buildInvestingSection();
                  }
                  return const SizedBox.shrink();
                },
              ),
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
        gradient: LinearGradient(colors: [
          AppColors.primaryDark,
          AppColors.primary,
          AppColors.primaryLight
        ]),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.trending_up,
                    color: AppColors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مرحباً',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white)),
                    const Text('مساعد الاستثمار',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white)),
                    Text('لوحة التحكم',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return BubbleActionMenu(
      items: [
        BubbleMenuItem(
            icon: Icons.auto_awesome,
            label: 'تحليل AI',
            onPressed: () => Navigator.of(context).pushNamed('/ai-analysis')),
        BubbleMenuItem(
            icon: Icons.lightbulb_outline,
            label: 'التوصيات',
            onPressed: () =>
                Navigator.of(context).pushNamed('/recommendations')),
        BubbleMenuItem(
            icon: Icons.visibility,
            label: 'قائمة المراقبة',
            onPressed: () => Navigator.of(context).pushNamed('/watchlist')),
        BubbleMenuItem(
            icon: Icons.wallet,
            label: 'المحفظة',
            onPressed: () => Navigator.of(context).pushNamed('/portfolio')),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final summary = _data?.summary;
    return Row(
      children: [
        Expanded(
            child: _buildMiniCard('الأسهم', '${summary?.totalStocks ?? '-'}',
                Icons.bar_chart, AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildMiniCard('ارتفاعات', '${summary?.gainers ?? '-'}',
                Icons.trending_up, AppColors.success)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildMiniCard('انخفاضات', '${summary?.losers ?? '-'}',
                Icons.trending_down, AppColors.danger)),
      ],
    );
  }

  Widget _buildMiniCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: color)),
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
          const SectionHeader(
              title: 'أعلى الأسهم ارتفاعاً', icon: Icons.trending_up),
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
          const SectionHeader(
              title: 'أعلى الأسهم انخفاضاً', icon: Icons.trending_down),
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
        Row(
          children: [
            const Icon(Icons.live_tv, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('بيانات مباشرة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (lastUpdated.isNotEmpty)
              Text(
                  lastUpdated.length > 16
                      ? lastUpdated.substring(0, 16)
                      : lastUpdated,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        if (stocks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('لا توجد بيانات مباشرة متاحة حالياً',
                style: TextStyle(color: AppColors.textMuted)),
          )
        else
          ...stocks.take(5).map((s) {
            final m = s as Map<String, dynamic>;
            final ticker = m['ticker'] ?? m['symbol'] ?? '';
            final price = (m['current_price'] as num?)?.toDouble() ?? 0;
            final change = (m['change_percent'] as num?)?.toDouble() ?? 0;
            final isUp = change >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Icon(isUp ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isUp ? AppColors.success : AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(ticker, style: AppTypography.bodyMedium)),
                  Text('$price', style: AppTypography.bodyMedium),
                  const SizedBox(width: 8),
                  Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUp ? AppColors.success : AppColors.danger)),
                ],
              ),
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
        const SectionHeader(
            title: 'بيانات Investing.com', icon: Icons.language),
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
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Icon(isUp ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isUp ? AppColors.success : AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(name,
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                Text('$price', style: AppTypography.bodyMedium),
                const SizedBox(width: 8),
                Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isUp ? AppColors.success : AppColors.danger)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final String text;
  const _LoadingIndicator({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2)),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

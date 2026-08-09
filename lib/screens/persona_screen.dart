// ============================================================================
// مساعد الاستثمار Flutter - Persona Screen
// 3-Persona tabs: gambler (المضارب), balanced (المتوازن), conservative (المحافظ)
// Uses /api/v2/unified/personas, /api/v2/unified/scan, /api/v2/unified/analyze
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../repositories/persona_repository.dart';
import '../models/persona_model.dart';
import '../widgets/persona_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state_widget.dart';

class PersonaScreen extends StatefulWidget {
  const PersonaScreen({super.key});

  @override
  State<PersonaScreen> createState() => _PersonaScreenState();
}

class _PersonaScreenState extends State<PersonaScreen>
    with SingleTickerProviderStateMixin {
  final PersonaRepository _repo = PersonaRepository.instance;

  late TabController _tabController;
  String _selectedMarket = 'EGX';
  String _selectedPersona = 'gambler';

  Future<Map<String, dynamic>>? _scanFuture;
  Map<String, dynamic>? _scanResult;

  // 3-persona definitions (display buy thresholds from maestro orchestrator).
  // NOTE: these thresholds are for DISPLAY ONLY. The backend scoring engine
  // uses them internally; we surface them so the user understands each
  // persona's risk appetite.
  static const List<_PersonaTab> _tabs = <_PersonaTab>[
    _PersonaTab(
      id: 'gambler',
      labelAr: 'المضارب',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.danger,
      buyThreshold: 28,
      description: 'مخاطر عالية جداً — زخم يومي/أسبوعي وفرص انفجارية',
      timeframe: 'يومي-أسبوعي',
    ),
    _PersonaTab(
      id: 'balanced',
      labelAr: 'المتوازن',
      icon: Icons.balance_rounded,
      color: AppColors.warning,
      buyThreshold: 42,
      description: 'توازن بين العائد والمخاطرة — استثمار متوسط المدى',
      timeframe: '1-6 شهر',
    ),
    _PersonaTab(
      id: 'conservative',
      labelAr: 'المحافظ',
      icon: Icons.shield_rounded,
      color: AppColors.info,
      buyThreshold: 50,
      description: 'حماية رأس المال أولاً — فرص آمنة طويلة الأمد',
      timeframe: '3-12 شهر',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMarket();
    _scanFuture = _scanMarket(_selectedPersona);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final persona = _tabs[_tabController.index.clamp(0, _tabs.length - 1)].id;
      setState(() {
        _selectedPersona = persona;
        _scanFuture = _scanMarket(persona);
      });
    }
  }

  Future<void> _loadMarket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final market = prefs.getString('active_market') ?? 'EGX';
      if (mounted) {
        setState(() => _selectedMarket = market);
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _scanMarket(String persona) async {
    final result =
        await _repo.scanMarket(market: _selectedMarket, persona: persona, topN: 20);
    _scanResult = result;
    return result;
  }

  Future<void> _refresh() async {
    setState(() {
      _scanFuture = _scanMarket(_selectedPersona);
    });
  }

  _PersonaTab get _activeTab =>
      _tabs.firstWhere((t) => t.id == _selectedPersona, orElse: () => _tabs.first);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('الشخصيات الاستثمارية',
              style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: _activeTab.color,
            labelColor: _activeTab.color,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: _tabs
                .map((t) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.labelAr),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        body: RefreshIndicator(
          color: _activeTab.color,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPersonaHeader(),
                  const SizedBox(height: 16),
                  _buildScanResults(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaHeader() {
    final tab = _activeTab;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [tab.color, tab.color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(tab.icon, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tab.labelAr,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white)),
                const SizedBox(height: 4),
                Text(tab.description,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _headerChip('أفق زمني: ${tab.timeframe}'),
                    _headerChip('عتبة الشراء: ${tab.buyThreshold}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.95))),
    );
  }

  Widget _buildScanResults() {
    final future = _scanFuture ?? _scanMarket(_selectedPersona);
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _scanResult == null) {
          return const SkeletonList(itemCount: 4, itemHeight: 140);
        }

        final data = snapshot.data ?? _scanResult ?? {};
        final results =
            data['results'] ?? data['opportunities'] ?? data['stocks'] ?? data['data'];
        final resultsList = results is List ? results : <dynamic>[];

        if (resultsList.isEmpty) {
          return EmptyStateWidget(
            message: 'لا توجد فرص مطابقة لشخصية "${_activeTab.labelAr}" حالياً',
            icon: Icons.search_off_rounded,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '${resultsList.length} فرصة لـ ${_activeTab.labelAr}',
                style: AppTypography.titleSmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            ...resultsList.map((item) {
              final map =
                  item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
              final opportunity = PersonaOpportunity.fromJson(map);
              return PersonaCard(
                opportunity: opportunity,
                onTap: () {
                  final ticker = opportunity.ticker;
                  if (ticker.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonaDetailScreen(
                          ticker: ticker,
                          market: _selectedMarket,
                          persona: _selectedPersona,
                        ),
                      ),
                    );
                  }
                },
              );
            }),
          ],
        );
      },
    );
  }
}

/// Internal model describing each persona tab (display + thresholds).
class _PersonaTab {
  final String id;
  final String labelAr;
  final IconData icon;
  final Color color;
  final int buyThreshold;
  final String description;
  final String timeframe;

  const _PersonaTab({
    required this.id,
    required this.labelAr,
    required this.icon,
    required this.color,
    required this.buyThreshold,
    required this.description,
    required this.timeframe,
  });
}

class PersonaDetailScreen extends StatefulWidget {
  final String ticker;
  final String market;
  final String persona;

  const PersonaDetailScreen({
    super.key,
    required this.ticker,
    required this.market,
    required this.persona,
  });

  @override
  State<PersonaDetailScreen> createState() => _PersonaDetailScreenState();
}

class _PersonaDetailScreenState extends State<PersonaDetailScreen> {
  final PersonaRepository _repo = PersonaRepository.instance;

  Future<Map<String, dynamic>>? _analysisFuture;
  Map<String, dynamic>? _analysisData;

  @override
  void initState() {
    super.initState();
    _analysisFuture = _loadAnalysis();
  }

  Future<Map<String, dynamic>> _loadAnalysis() async {
    final analysis = await _repo.analyzeStock(
      ticker: widget.ticker,
      market: widget.market,
      persona: widget.persona,
    );
    final maestro = await _repo.getMaestroAnalysis(
      ticker: widget.ticker,
      market: widget.market,
      persona: widget.persona,
    );
    final combined = <String, dynamic>{...analysis};
    combined['maestro'] = maestro;
    _analysisData = combined;
    return combined;
  }

  /// Map the 3-persona id to display info.
  _PersonaDisplay _personaDisplay(String persona) {
    switch (persona) {
      case 'gambler':
        return const _PersonaDisplay('المضارب', AppColors.danger);
      case 'balanced':
        return const _PersonaDisplay('المتوازن', AppColors.warning);
      case 'conservative':
        return const _PersonaDisplay('المحافظ', AppColors.info);
      default:
        return const _PersonaDisplay('الشخصية', AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = _personaDisplay(widget.persona);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('${widget.ticker} - ${display.name}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
        ),
        body: RefreshIndicator(
          color: display.color,
          onRefresh: () async {
            setState(() {
              _analysisFuture = _loadAnalysis();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _analysisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _analysisData == null) {
                  return const SkeletonList(itemCount: 4, itemHeight: 120);
                }
                final data = snapshot.data ?? _analysisData ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalysisCard(data, display.color),
                    if (data['maestro'] is Map) ...[
                      const SizedBox(height: 16),
                      _buildMaestroCard(data['maestro'] as Map<String, dynamic>),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> data, Color personaColor) {
    final analysis = data['analysis'] ?? data['data'] ?? data;
    final analysisMap =
        analysis is Map ? Map<String, dynamic>.from(analysis) : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [personaColor, personaColor.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التحليل الشخصي',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
          const SizedBox(height: 12),
          if (analysisMap['signal'] != null)
            _buildAnalysisRow(
                'الإشارة', analysisMap['signal']?.toString() ?? '—', AppColors.white),
          if (analysisMap['confidence'] != null)
            _buildAnalysisRow('الثقة', '${analysisMap['confidence']}%', AppColors.white),
          if (analysisMap['entry_price'] != null)
            _buildAnalysisRow(
                'سعر الدخول', analysisMap['entry_price']?.toString() ?? '—', AppColors.white),
          if (analysisMap['target_price'] != null)
            _buildAnalysisRow('السعر المستهدف',
                analysisMap['target_price']?.toString() ?? '—', AppColors.white),
          if (analysisMap['stop_loss'] != null)
            _buildAnalysisRow(
                'وقف الخسارة', analysisMap['stop_loss']?.toString() ?? '—', AppColors.white),
          if (analysisMap['reasoning'] != null)
            _buildAnalysisRow(
                'التحليل', analysisMap['reasoning']?.toString() ?? '—', AppColors.white),
        ],
      ),
    );
  }

  Widget _buildMaestroCard(Map<String, dynamic> maestro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('تحليل Maestro', style: AppTypography.titleMedium),
          ]),
          const SizedBox(height: 12),
          if (maestro['analysis'] != null)
            Text(maestro['analysis']?.toString() ?? '', style: AppTypography.bodyMedium)
          else
            Text('لا يوجد تحليل إضافي متاح',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.white.withValues(alpha: 0.8))),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _PersonaDisplay {
  final String name;
  final Color color;
  const _PersonaDisplay(this.name, this.color);
}

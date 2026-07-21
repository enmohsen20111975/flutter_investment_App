// ============================================================================
// مساعد الاستثمار Flutter - Persona Screen
// Dual Persona tabs: Investor (مستثمر) and Trader (مضارب)
// Uses /api/v2/unified/personas, /api/v2/unified/scan, /api/v2/unified/analyze
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
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

class _PersonaScreenState extends State<PersonaScreen> with SingleTickerProviderStateMixin {
  final PersonaRepository _repo = PersonaRepository.instance;

  late TabController _tabController;
  String _selectedMarket = 'EGX';
  String _selectedPersona = 'investor';

  Future<Map<String, dynamic>>? _scanFuture;
  Map<String, dynamic>? _scanResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final persona = _tabController.index == 0 ? 'investor' : 'trader';
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
    return _repo.scanMarket(market: _selectedMarket, persona: persona, topN: 20);
  }

  Future<void> _refresh() async {
    setState(() {
      _scanFuture = _scanMarket(_selectedPersona);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('المضارب والمستثمر', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'مستثمر'),
              Tab(text: 'مضارب'),
            ],
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
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
    final isInvestor = _selectedPersona == 'investor';
    final personaName = isInvestor ? 'المستثمر' : 'المضارب';
    final personaDesc = isInvestor
        ? 'فرص استثمارية طويلة الأمد بناءً على القيمة الأساسية'
        : 'فرص مضاربة قصيرة الأمد بناءً على الزخم';
    final personaColor = isInvestor ? AppColors.primary : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [personaColor, personaColor.withValues(alpha: 0.7)]),
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
            child: Icon(
              isInvestor ? Icons.person_rounded : Icons.flash_on_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(personaName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white)),
                const SizedBox(height: 4),
                Text(personaDesc, style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    if (_scanFuture == null) {
      _scanFuture = _scanMarket(_selectedPersona);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _scanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _scanResult == null) {
          return const SkeletonList(itemCount: 4, itemHeight: 140);
        }

        final data = snapshot.data ?? _scanResult ?? {};
        final results = data['results'] ?? data['opportunities'] ?? data['stocks'] ?? data['data'] ?? [];
        final resultsList = results is List ? results : [];

        if (resultsList.isEmpty) {
          return EmptyStateWidget(
            message: 'لا توجد فرص مطابقة حالياً',
            icon: Icons.search_off_rounded,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '${resultsList.length} فرصة',
                style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ...resultsList.map((item) {
              final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
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

  @override
  Widget build(BuildContext context) {
    final isInvestor = widget.persona == 'investor';
    final personaName = isInvestor ? 'المستثمر' : 'المضارب';
    final personaColor = isInvestor ? AppColors.primary : AppColors.accent;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('${widget.ticker} - $personaName', style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
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
                if (snapshot.connectionState == ConnectionState.waiting && _analysisData == null) {
                  return const SkeletonList(itemCount: 4, itemHeight: 120);
                }
                final data = snapshot.data ?? _analysisData ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalysisCard(data, personaColor),
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
    final analysisMap = analysis is Map ? Map<String, dynamic>.from(analysis) : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [personaColor, personaColor.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التحليل الشخصي', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
          const SizedBox(height: 12),
          if (analysisMap['signal'] != null)
            _buildAnalysisRow('الإشارة', analysisMap['signal']?.toString() ?? '—', AppColors.white),
          if (analysisMap['confidence'] != null)
            _buildAnalysisRow('الثقة', '${analysisMap['confidence']}%', AppColors.white),
          if (analysisMap['entry_price'] != null)
            _buildAnalysisRow('سعر الدخول', analysisMap['entry_price']?.toString() ?? '—', AppColors.white),
          if (analysisMap['target_price'] != null)
            _buildAnalysisRow('السعر المستهدف', analysisMap['target_price']?.toString() ?? '—', AppColors.white),
          if (analysisMap['stop_loss'] != null)
            _buildAnalysisRow('وقف الخسارة', analysisMap['stop_loss']?.toString() ?? '—', AppColors.white),
          if (analysisMap['reasoning'] != null)
            _buildAnalysisRow('التحليل', analysisMap['reasoning']?.toString() ?? '—', AppColors.white),
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
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('تحليل Maestro', style: AppTypography.titleMedium),
          ]),
          const SizedBox(height: 12),
          if (maestro['analysis'] != null)
            Text(maestro['analysis']?.toString() ?? '', style: AppTypography.bodyMedium)
          else
            Text('لا يوجد تحليل إضافي متاح', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
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
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8))),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

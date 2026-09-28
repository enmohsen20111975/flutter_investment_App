// ============================================================================
// مساعد الاستثمار Flutter - Radar & Explosive Hub Screen
// يجمع بين:
//   - صائد الأسهم الانفجارية (Hunter)
//   - رادار السيولة والميكرز (Radar)
//   - حالة السوق (Market Regime) — DEFENSIVE/NORMAL/AGGRESSIVE
//   - رادار الخروج (Exit Radar) — 5 مسارات خروج
//   - الرادار الموحّد (Multi-Market Radar) — 7 أسواق في لوحة واحدة
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'hunter_screen.dart';
import 'radar_screen.dart';
import 'market_regime_screen.dart';
import 'exit_radar_screen.dart';
import 'multi_market_radar_screen.dart';

class RadarHubScreen extends StatefulWidget {
  final int marketVersion;
  final int initialTabIndex;

  const RadarHubScreen({
    super.key,
    this.marketVersion = 0,
    this.initialTabIndex = 0,
  });

  @override
  State<RadarHubScreen> createState() => _RadarHubScreenState();
}

class _RadarHubScreenState extends State<RadarHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = <_HubTab>[
    _HubTab(
      label: 'الانفجارية',
      icon: Icons.local_fire_department_rounded,
    ),
    _HubTab(
      label: 'رادار السيولة',
      icon: Icons.radar_rounded,
    ),
    _HubTab(
      label: 'حالة السوق',
      icon: Icons.shield_moon_outlined,
    ),
    _HubTab(
      label: 'رادار الخروج',
      icon: Icons.logout_outlined,
    ),
    _HubTab(
      label: 'الرادار الموحّد',
      icon: Icons.public,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.quantumBg,
        appBar: AppBar(
          backgroundColor: AppColors.quantumBg,
          elevation: 0,
          title: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.quantumSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.quantumGlassBorder),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.quantumEmerald,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: _tabs
                  .map((t) => Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.icon, size: 15),
                              const SizedBox(width: 5),
                              Text(t.label),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          centerTitle: true,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            HunterScreen(marketVersion: widget.marketVersion),
            const RadarScreen(),
            const MarketRegimeScreen(),
            const ExitRadarScreen(),
            const MultiMarketRadarScreen(),
          ],
        ),
      ),
    );
  }
}

class _HubTab {
  final String label;
  final IconData icon;
  const _HubTab({required this.label, required this.icon});
}

// ============================================================================
// مساعد الاستثمار Flutter - Radar & Explosive Hub Screen
// يجمع بين: صائد الأسهم الانفجارية (Hunter) + رادار السيولة والميكرز (Radar)
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'hunter_screen.dart';
import 'radar_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
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
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.quantumSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.quantumGlassBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.quantumEmerald,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('الأسهم الانفجارية'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('رادار السيولة'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            HunterScreen(marketVersion: widget.marketVersion),
            const RadarScreen(),
          ],
        ),
      ),
    );
  }
}

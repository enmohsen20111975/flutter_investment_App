// ============================================================================
// مساعد الاستثمار Flutter - Explore & Tools Hub Screen (استكشف والأدوات)
// بوابة الوصول الفوري لكافة أدوات المنصة وشارتات TradingView والذهب والعملات والمستثمرين
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/stock_search_dialog.dart';
import 'trading_chart_screen.dart';
import 'metals_screen.dart';
import 'currency_screen.dart';
import 'investors_screen.dart';
import 'radar_screen.dart';
import 'hunter_screen.dart';
import 'ai_analysis_screen.dart';
import 'screener_screen.dart';
import 'crypto_screen.dart';
import 'zakat_screen.dart';
import 'academy_screen.dart';
import 'news_screen.dart';
import 'reports_screen.dart';
import 'subscription_screen.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.quantumBg,
        appBar: AppBar(
          backgroundColor: AppColors.quantumBg,
          elevation: 0,
          title: const Text(
            'استكشف الأدوات والإمكانيات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Search & Inspect Banner
            InkWell(
              onTap: () => StockSearchDialog.show(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF104A3E), Color(0xFF0B2B24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.quantumEmerald.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.quantumEmerald.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.quantumEmerald,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'فحص وتحليل أي سهم فوري',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ابحث برمز السهم للانتقال المباشر للتحليل والشارت',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.quantumEmerald, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: الأدوات الرئيسية الأكثر طلباً
            _buildSectionHeader('الأدوات الفنية والمؤشرات 📈'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildToolCard(
                  title: 'TradingView Chart',
                  subtitle: 'الرسم البياني التفاعلي',
                  icon: Icons.candlestick_chart_rounded,
                  color: AppColors.quantumGold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TradingChartScreen(ticker: 'EGX30', displayName: 'مؤشر EGX 30'),
                      ),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'حركة المستثمرين',
                  subtitle: 'أجانب • عرب • مصريين',
                  icon: Icons.groups_rounded,
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvestorsScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'صائد الانفجارات',
                  subtitle: 'الأسهم ذات الفرص العالية',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.quantumCrimson,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HunterScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'رادار السيولة',
                  subtitle: 'تجميع الميكرز والحيتان',
                  icon: Icons.radar_rounded,
                  color: AppColors.quantumEmerald,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RadarScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 2: الأسواق والمعادن والعملات
            _buildSectionHeader('الذهب والعملات والأسواق 🥇'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildToolCard(
                  title: 'أسعار الذهب والفضة',
                  subtitle: 'عيار 21 و 24 وسبائك',
                  icon: Icons.diamond_rounded,
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MetalsScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'أسعار صرف العملات',
                  subtitle: 'الدولار واليورو والعملات',
                  icon: Icons.currency_exchange_rounded,
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CurrencyScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'العملات الرقمية',
                  subtitle: 'البيتكوين والعملات المشفرة',
                  icon: Icons.currency_bitcoin_rounded,
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CryptoScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'المسح الفني Screener',
                  subtitle: 'تصفية وفلترة متقدمة',
                  icon: Icons.filter_alt_rounded,
                  color: Colors.tealAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScreenerScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 3: الذكاء الاصطناعي والمحاكاة والتقارير
            _buildSectionHeader('الذكاء الاصطناعي والأكاديمية 🤖'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildToolCard(
                  title: 'تحليل الذكاء الاصطناعي',
                  subtitle: 'توقعات ورؤى الذكاء الاصطناعي',
                  icon: Icons.psychology_rounded,
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiAnalysisScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'أكاديمية الاستثمار',
                  subtitle: 'دروس وموسوعة التداول',
                  icon: Icons.school_rounded,
                  color: Colors.lightBlueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AcademyScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'التقارير اليومية',
                  subtitle: 'التقرير الصباحي والتحليلات',
                  icon: Icons.article_rounded,
                  color: Colors.cyanAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'الأخبار العاجلة',
                  subtitle: 'أخبار البورصة لحظة بلحظة',
                  icon: Icons.newspaper_rounded,
                  color: Colors.amberAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewsScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'حاسبة الزكاة',
                  subtitle: 'حساب زكاة الأسهم والأموال',
                  icon: Icons.calculate_rounded,
                  color: AppColors.quantumEmerald,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ZakatScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  title: 'باقات الاشتراك',
                  subtitle: 'ترقية وتفعيل الميزات',
                  icon: Icons.card_membership_rounded,
                  color: AppColors.quantumGold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.quantumSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.quantumGlassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

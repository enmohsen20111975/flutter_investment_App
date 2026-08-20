// ============================================================================
// مساعد الاستثمار Flutter - Quantum News & Disclosures Screen
// Economic News & Company Disclosures with Filters & Offline Support
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';
import 'stock_history_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _newsFuture = GLMApiClient.instance.getLatestNews();
  late Future<List<CompanyDisclosure>> _disclosuresFuture = GLMApiClient.instance.getCompanyDisclosures('EGX');
  String _selectedCategory = 'الكل';

  final List<String> _categories = ['الكل', 'البورصة المصرية', 'الاقتصاد الكلي', 'الذهب والعملات'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _newsFuture = GLMApiClient.instance.getLatestNews();
      _disclosuresFuture = GLMApiClient.instance.getCompanyDisclosures('EGX');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.quantumBg,
      appBar: AppBar(
        backgroundColor: AppColors.quantumSurface,
        elevation: 0,
        title: const Text('الأخبار والإفصاحات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.quantumEmerald,
          labelColor: AppColors.quantumEmerald,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'الأخبار الاقتصادية 📰'),
            Tab(text: 'إفصاحات الشركات 📜'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsTab(),
          _buildDisclosuresTab(),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.quantumCrimson),
                const SizedBox(height: 12),
                const Text('حدث خطأ في جلب الأخبار', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.quantumEmerald, foregroundColor: Colors.black),
                  onPressed: _refreshData,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final newsList = snapshot.data ?? [];

        return RefreshIndicator(
          color: AppColors.quantumEmerald,
          backgroundColor: AppColors.quantumGlass,
          onRefresh: () async => _refreshData(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Filter chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.quantumEmerald,
                        backgroundColor: AppColors.quantumGlass,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.quantumEmerald : AppColors.quantumGlassBorder,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              if (newsList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('لا توجد أخبار حديثة حالياً', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                )
              else
                ...newsList.map((item) {
                  final title = item['title'] ?? item['headline'] ?? 'خبر اقتصادي عاجل';
                  final source = item['source'] ?? 'البورصة المصرية';
                  final time = item['published_at'] ?? item['time'] ?? 'منذ ساعتين';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.quantumGlass,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.quantumGlassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.quantumEmerald.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(source, style: const TextStyle(color: AppColors.quantumEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.4)),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisclosuresTab() {
    return FutureBuilder<List<CompanyDisclosure>>(
      future: _disclosuresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.quantumCrimson),
                const SizedBox(height: 12),
                const Text('حدث خطأ في جلب الإفصاحات', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.quantumEmerald, foregroundColor: Colors.black),
                  onPressed: _refreshData,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final disclosures = snapshot.data ?? [];

        return RefreshIndicator(
          color: AppColors.quantumEmerald,
          backgroundColor: AppColors.quantumGlass,
          onRefresh: () async => _refreshData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: disclosures.isEmpty ? 1 : disclosures.length,
            itemBuilder: (context, index) {
              if (disclosures.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('لا توجد إفصاحات شركات مسجلة', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                );
              }
              final item = disclosures[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.quantumGlass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.quantumGlassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StockHistoryScreen(ticker: item.symbol),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.quantumGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.quantumGold.withOpacity(0.4)),
                            ),
                            child: Text(
                              item.symbol,
                              style: const TextStyle(color: AppColors.quantumGold, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        Text(
                          '${item.date.day}/${item.date.month}/${item.date.year}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (item.summary != null) ...[
                      const SizedBox(height: 6),
                      Text(item.summary!, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// مساعد الاستثمار Flutter - Quantum Investment & Zakat Calculator Screen
// Offline Purchase Cost, Commission, Dividend Yield & Zakat Calculations
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Investment Calculator Controllers
  final TextEditingController _sharesCtrl = TextEditingController(text: '1000');
  final TextEditingController _priceCtrl = TextEditingController(text: '25.50');
  final TextEditingController _commissionCtrl = TextEditingController(text: '0.00155'); // EGX standard ~0.155%
  final TextEditingController _divCtrl = TextEditingController(text: '1.50');

  // Zakat Calculator Controllers
  final TextEditingController _cashCtrl = TextEditingController(text: '50000');
  final TextEditingController _stocksValueCtrl = TextEditingController(text: '100000');
  final TextEditingController _goldValueCtrl = TextEditingController(text: '30000');

  // Results
  double _totalBuyCost = 0.0;
  double _commissionFee = 0.0;
  double _totalAnnualDividend = 0.0;
  double _dividendYieldPercent = 0.0;

  double _totalZakatBase = 0.0;
  double _totalZakatDue = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateInvestment();
    _calculateZakat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sharesCtrl.dispose();
    _priceCtrl.dispose();
    _commissionCtrl.dispose();
    _divCtrl.dispose();
    _cashCtrl.dispose();
    _stocksValueCtrl.dispose();
    _goldValueCtrl.dispose();
    super.dispose();
  }

  void _calculateInvestment() {
    final shares = double.tryParse(_sharesCtrl.text) ?? 0.0;
    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final commissionRate = double.tryParse(_commissionCtrl.text) ?? 0.00155;
    final divPerShare = double.tryParse(_divCtrl.text) ?? 0.0;

    final rawCost = shares * price;
    final fee = rawCost * commissionRate;
    final totalCost = rawCost + fee;

    final totalDiv = shares * divPerShare;
    final divYield = totalCost > 0 ? (totalDiv / totalCost) * 100 : 0.0;

    setState(() {
      _totalBuyCost = totalCost;
      _commissionFee = fee;
      _totalAnnualDividend = totalDiv;
      _dividendYieldPercent = divYield;
    });
  }

  void _calculateZakat() {
    final cash = double.tryParse(_cashCtrl.text) ?? 0.0;
    final stocks = double.tryParse(_stocksValueCtrl.text) ?? 0.0;
    final gold = double.tryParse(_goldValueCtrl.text) ?? 0.0;

    final totalBase = cash + stocks + gold;
    final zakatDue = totalBase * 0.025; // 2.5% Hijri year Zakat rate

    setState(() {
      _totalZakatBase = totalBase;
      _totalZakatDue = zakatDue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.quantumBg,
      appBar: AppBar(
        backgroundColor: AppColors.quantumSurface,
        elevation: 0,
        title: const Text('الحاسبة الاستثمارية والزكاة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.quantumEmerald,
          labelColor: AppColors.quantumEmerald,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'حاسبة التكاليف والأرباح 📊'),
            Tab(text: 'حاسبة زكاة المال والأسهم 🌙'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvestmentCalcTab(),
          _buildZakatCalcTab(),
        ],
      ),
    );
  }

  Widget _buildInvestmentCalcTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('بيانات الصفقة والتكلفة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildInputRow(_sharesCtrl, 'عدد الأسهم', 'أدخل عدد الأسهم', _calculateInvestment),
        const SizedBox(height: 10),
        _buildInputRow(_priceCtrl, 'سعر الشراء للسهم (ج.م)', 'أدخل سعر السهم', _calculateInvestment),
        const SizedBox(height: 10),
        _buildInputRow(_commissionCtrl, 'نسبة عمولة السمسرة (0.00155 للمصرية)', 'عمولة البورصة والسمسرة', _calculateInvestment),
        const SizedBox(height: 10),
        _buildInputRow(_divCtrl, 'التوزيع السنوي المتوقع/السهم (ج.م)', 'توزيعات الأرباح', _calculateInvestment),
        const SizedBox(height: 20),

        // Result Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.quantumGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.quantumEmerald.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.quantumEmerald.withOpacity(0.05),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ملخص التكاليف والعائد المتوقع', style: TextStyle(color: AppColors.quantumEmerald, fontWeight: FontWeight.bold, fontSize: 15)),
              const Divider(color: AppColors.quantumGlassBorder, height: 24),
              _buildResultRow('إجمالي تكلفة الشراء المباشر', '${(_sharesCtrl.text.isEmpty ? 0 : double.parse(_sharesCtrl.text) * double.parse(_priceCtrl.text)).toStringAsFixed(2)} ج.م'),
              _buildResultRow('عمولة الشراء والسمسرة', '${_commissionFee.toStringAsFixed(2)} ج.م'),
              _buildResultRow('التكلفة الكلية للصفقة', '${_totalBuyCost.toStringAsFixed(2)} ج.م', isBold: true),
              const Divider(color: AppColors.quantumGlassBorder, height: 24),
              _buildResultRow('إجمالي التوزيعات النقديّة السنوية', '${_totalAnnualDividend.toStringAsFixed(2)} ج.م', color: AppColors.quantumGold),
              _buildResultRow('عائد التوزيعات السنوي (Dividend Yield)', '${_dividendYieldPercent.toStringAsFixed(2)}%', color: AppColors.quantumEmerald, isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZakatCalcTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('أوعية الزكاة (السيولة والأسهم والذهب)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildInputRow(_cashCtrl, 'النقدية والسيولة بالبنوك (ج.م)', 'السيولة المتاحة', _calculateZakat),
        const SizedBox(height: 10),
        _buildInputRow(_stocksValueCtrl, 'القيمة السوقية للأسهم المملوكة (ج.م)', 'محفظة الأسهم', _calculateZakat),
        const SizedBox(height: 10),
        _buildInputRow(_goldValueCtrl, 'قيمة الذهب والمعادن (ج.م)', 'الذهب للادخار والاستثمار', _calculateZakat),
        const SizedBox(height: 20),

        // Zakat Output Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.quantumGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.quantumGold.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.quantumGold.withOpacity(0.05),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('حساب زكاة المال الشريعة (2.5%)', style: TextStyle(color: AppColors.quantumGold, fontWeight: FontWeight.bold, fontSize: 15)),
                  Icon(Icons.nights_stay_outlined, color: AppColors.quantumGold, size: 20),
                ],
              ),
              const Divider(color: AppColors.quantumGlassBorder, height: 24),
              _buildResultRow('إجمالي الوعاء الزكوي الخاضع', '${_totalZakatBase.toStringAsFixed(2)} ج.م'),
              const SizedBox(height: 8),
              _buildResultRow('مقدار الزكاة الواجب إخراجها شرعاً', '${_totalZakatDue.toStringAsFixed(2)} ج.م', color: AppColors.quantumGold, isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow(TextEditingController controller, String label, String hint, VoidCallback onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppColors.quantumSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.quantumGlassBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String title, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

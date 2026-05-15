// ============================================================================
// مساعد الاستثمار Flutter - Zakat Calculator Screen
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});
  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _cashCtrl = TextEditingController();
  final _goldCtrl = TextEditingController();
  final _stocksCtrl = TextEditingController();
  final _receivablesCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _debtsCtrl = TextEditingController();

  ZakatCalculation? _result;
  bool _loading = false;
  String? _error;

  Future<void> _calculate() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = {
        'cash': double.tryParse(_cashCtrl.text) ?? 0,
        'gold_silver': double.tryParse(_goldCtrl.text) ?? 0,
        'stocks': double.tryParse(_stocksCtrl.text) ?? 0,
        'receivables': double.tryParse(_receivablesCtrl.text) ?? 0,
        'other_assets': double.tryParse(_otherCtrl.text) ?? 0,
        'debts': double.tryParse(_debtsCtrl.text) ?? 0,
      };
      final result = await api.calculateZakat(data);
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _reset() {
    _cashCtrl.clear(); _goldCtrl.clear(); _stocksCtrl.clear();
    _receivablesCtrl.clear(); _otherCtrl.clear(); _debtsCtrl.clear();
    setState(() { _result = null; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const HeaderCard(icon: Icons.calculate, title: 'حاسبة الزكاة', subtitle: 'احسب زكاة أموالك بسهولة'),
            const SizedBox(height: 16),
            _buildInputField(_cashCtrl, 'النقود والمدخرات', Icons.money),
            const SizedBox(height: 10),
            _buildInputField(_goldCtrl, 'الذهب والفضة', Icons.diamond),
            const SizedBox(height: 10),
            _buildInputField(_stocksCtrl, 'الأسهم والاستثمارات', Icons.trending_up),
            const SizedBox(height: 10),
            _buildInputField(_receivablesCtrl, 'المستحقات', Icons.receipt),
            const SizedBox(height: 10),
            _buildInputField(_otherCtrl, 'أصول أخرى', Icons.inventory),
            const SizedBox(height: 10),
            _buildInputField(_debtsCtrl, 'الديون', Icons.account_balance),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ActionButton(title: _loading ? 'جاري الحساب...' : 'احسب الزكاة', onPress: _loading ? null : _calculate, loading: _loading, fullWidth: true)),
              const SizedBox(width: 12),
              ActionButton(title: 'مسح', onPress: _reset, variant: 'outline'),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(8)), child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('زكاتك المستحقة', style: TextStyle(color: AppColors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('${_result!.zakatDue.toStringAsFixed(2)} ج.م', style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildResultItem('إجمالي الأصول', _result!.totalAssets)),
                    Expanded(child: _buildResultItem('صافي الزكاة', _result!.netZakatable)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _buildResultItem('النصاب', _result!.nisab)),
                    Expanded(child: _buildResultItem('نسبة الزكاة', _result!.zakatRate * 100, suffix: '%')),
                  ]),
                ]),
              ),
            ],
            const SizedBox(height: 90),
          ]),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixText: 'ج.م',
      ),
    );
  }

  Widget _buildResultItem(String label, double value, {String suffix = ' ج.م'}) {
    return Column(children: [
      Text(label, style: const TextStyle(color: AppColors.white, fontSize: 11)),
      const SizedBox(height: 4),
      Text('${value.toStringAsFixed(2)}$suffix', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}

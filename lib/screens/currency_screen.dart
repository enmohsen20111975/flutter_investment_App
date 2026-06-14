// ============================================================================
// مساعد الاستثمار Flutter - Currency Converter Screen
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  Future<List<Currency>>? _currenciesFuture;

  String _amount = '1';
  String _fromCurrency = 'USD';
  String _toCurrency = 'EGP';
  ConversionResult? _result;
  bool _converting = false;

  @override
  void initState() {
    super.initState();
    _currenciesFuture = _fetchCurrencies();
  }

  Future<List<Currency>> _fetchCurrencies() async {
    try {
      final response = await api.getCurrency();
      if (response is Map && response['data'] is List) {
        return (response['data'] as List)
            .map((e) => Currency.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _convert() async {
    final amt = double.tryParse(_amount) ?? 0;
    if (amt <= 0) return;
    setState(() => _converting = true);
    try {
      final dynamic resultData =
          await api.convertCurrency(_fromCurrency, _toCurrency, amt);
      final ConversionResult result = ConversionResult.fromJson(resultData);
      setState(() {
        _result = result;
        _converting = false;
      });
    } catch (e) {
      setState(() => _converting = false);
    }
  }

  Future<void> _refresh() async {
    _currenciesFuture = _fetchCurrencies();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FutureBuilder<List<Currency>>(
          future: _currenciesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final currencies = snapshot.data ?? [];
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const HeaderCard(
                      icon: Icons.swap_horiz,
                      title: 'محول العملات',
                      subtitle: 'تحويل بين العملات لحظياً'),
                  const SizedBox(height: 16),
                  // Converter Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border)),
                    child: Column(children: [
                      TextField(
                        decoration: const InputDecoration(
                            hintText: 'المبلغ',
                            prefixIcon: Icon(Icons.attach_money)),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _amount = v,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _buildCurrencyDropdown(
                                _fromCurrency,
                                (v) => setState(() {
                                      _fromCurrency = v!;
                                      _result = null;
                                    }))),
                        IconButton(
                            icon: const Icon(Icons.swap_horiz,
                                color: AppColors.primary),
                            onPressed: () => setState(() {
                                  final t = _fromCurrency;
                                  _fromCurrency = _toCurrency;
                                  _toCurrency = t;
                                  _result = null;
                                })),
                        Expanded(
                            child: _buildCurrencyDropdown(
                                _toCurrency,
                                (v) => setState(() {
                                      _toCurrency = v!;
                                      _result = null;
                                    }))),
                      ]),
                      const SizedBox(height: 12),
                      ActionButton(
                          title: _converting ? 'جاري التحويل...' : 'تحويل',
                          onPress: _converting ? null : _convert,
                          loading: _converting,
                          fullWidth: true),
                      if (_result != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            Text(
                                '${_result!.result.toStringAsFixed(2)} ${_result!.to}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success)),
                            const SizedBox(height: 4),
                            Text(
                                'سعر الصرف: ${_result!.rate.toStringAsFixed(4)}',
                                style: AppTypography.bodySmall),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (currencies.isEmpty)
                    const StateView(
                        empty: true, emptyMessage: 'لا توجد عملات متاحة')
                  else ...[
                    const SectionHeader(
                        title: 'أسعار العملات', icon: Icons.public),
                    const SizedBox(height: 8),
                    ...currencies.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DataRowWidget(
                              title: c.nameAr ?? c.code,
                              subtitle: c.code,
                              value: c.buyRate?.toStringAsFixed(2) ?? '-',
                              change: c.change,
                              icon: Icons.public),
                        )),
                  ],
                  const SizedBox(height: 90),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(String value, ValueChanged<String?> onChanged) {
    final currenciesSnapshot = _currenciesFuture;

    return FutureBuilder<List<Currency>>(
      future: currenciesSnapshot,
      builder: (context, snapshot) {
        final currencies = snapshot.data ?? [];
        if (currencies.isEmpty) {
          return Container(
            height: 60,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8)),
            child: const Text('اختر العملة',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        final validValue =
            currencies.any((c) => c.code == value) ? value : null;
        return DropdownButtonFormField<String>(
          initialValue: validValue,
          decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none)),
          items: currencies
              .map((c) => DropdownMenuItem(
                  value: c.code,
                  child: Text(c.code, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

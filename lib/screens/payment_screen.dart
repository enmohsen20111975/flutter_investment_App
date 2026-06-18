// ============================================================================
// مساعد الاستثمار Flutter - Payment Screen
// Paymob payment flow with WebView and subscription polling
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/colors.dart';
import '../api/client.dart';

class PaymentScreen extends StatefulWidget {
  final String planId;
  final double price;
  final String planName;
  final String? planPeriod;

  const PaymentScreen({
    super.key,
    required this.planId,
    required this.price,
    required this.planName,
    this.planPeriod = 'شهرياً',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late WebViewController _controller;
  bool _loading = true;
  String? _paymentUrl;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int _maxAttempts = 36; // 3 minutes at 5s each

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            // Block external navigation except payment URLs
            final url = request.url;
            if (url.contains('invist.m2y.net') || url.contains('paymob')) {
              return NavigationDecision.navigate;
            }
            // Detect success callback
            if (url.contains('/payment/success') ||
                url.contains('?status=success')) {
              _onPaymentSuccess();
              return NavigationDecision.prevent;
            }
            if (url.contains('/payment/failed') ||
                url.contains('?status=failed')) {
              _onPaymentFailed();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _initPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPayment() async {
    try {
      final result = await api.createPaymobPayment(
        amount: widget.price,
        currency: 'EGP',
        planId: widget.planId,
      );
      final url = result['iframe_url'] ??
          result['payment_url'] ??
          result['redirect_url'] ??
          result['url'];
      if (url != null && url.toString().isNotEmpty) {
        _paymentUrl = url.toString();
        _controller.loadRequest(Uri.parse(_paymentUrl!));
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل تهيئة الدفع: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _onPaymentSuccess() {
    _pollTimer?.cancel();
    setState(() {});
    // Poll subscription status
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      _pollAttempts++;
      if (_pollAttempts > _maxAttempts) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final sub = await api.getSubscriptionCurrent();
        final active = sub['is_active'] == true || sub['active'] == true;
        if (active && mounted) {
          _pollTimer?.cancel();
          Navigator.pop(context, true);
        }
      } catch (_) {}
    });
  }

  void _onPaymentFailed() {
    _pollTimer?.cancel();
    setState(() {});
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
          title: Text('دفع - ${widget.planName}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _pollTimer?.cancel();
              Navigator.pop(context, false);
            },
          ),
        ),
        body: _paymentUrl == null
            ? _buildLoading('جاري تحضير صفحة الدفع...')
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading) _buildLoading('جاري تحميل صفحة الدفع...'),
                ],
              ),
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text(message,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ]),
    );
  }
}

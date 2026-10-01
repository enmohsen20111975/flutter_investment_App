// ============================================================================
// مساعد الاستثمار Flutter - WebView Screen
// Opens the live website for browsing, login, and account management
// Uses: webview_flutter to load https://invist.m2y.net
// ============================================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/colors.dart';

class WebViewScreen extends StatefulWidget {
  final String? initialUrl;
  const WebViewScreen({super.key, this.initialUrl});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _loading = true;
  double _progress = 0;
  String _title = 'الموقع';

  @override
  void initState() {
    super.initState();
    final url = widget.initialUrl ?? 'https://invist.m2y.net';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          setState(() { _progress = progress / 100; });
        },
        onPageStarted: (_) {
          setState(() { _loading = true; });
        },
        onPageFinished: (_) async {
          setState(() { _loading = false; });
          try {
            final title = await _controller.getTitle();
            if (title != null && title.isNotEmpty) {
              setState(() { _title = title; });
            }
          } catch (_) {}
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_title, style: const TextStyle(fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _loading
                ? LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.surfaceMuted,
                    color: AppColors.primary,
                  )
                : const SizedBox.shrink(),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}

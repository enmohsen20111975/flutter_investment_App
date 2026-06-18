// ============================================================================
// مساعد الاستثمار Flutter - Market Status Banner
// Shows live market open/close status at top of screens
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../api/mobile_api.dart';

/// Status of the market with convenience getters
class MarketStatusInfo {
  final bool isOpen;
  final String? remainingTime;
  final String? nextOpen;
  final String? marketName;
  final String? holidayMessage;

  const MarketStatusInfo({
    required this.isOpen,
    this.remainingTime,
    this.nextOpen,
    this.marketName,
    this.holidayMessage,
  });

  factory MarketStatusInfo.fromJson(Map<String, dynamic> json) {
    final status = json['status'] ?? json['market_status'] ?? '';
    final open = status is bool
        ? status
        : (status.toString().toLowerCase() == 'open' ||
            status.toString().toLowerCase() == 'مفتوح');
    return MarketStatusInfo(
      isOpen: open,
      remainingTime: json['remaining_time'] ?? json['time_remaining'],
      nextOpen: json['next_open'] ?? json['opening_time'],
      marketName: json['market'] ?? json['name'],
      holidayMessage: json['holiday'] ?? json['message'],
    );
  }

  static const empty = MarketStatusInfo(isOpen: false);
}

/// Reusable market status banner widget
class MarketStatusBanner extends StatefulWidget {
  /// Optional market code to check
  final String? market;

  /// Whether to auto-poll for updates
  final bool autoPoll;

  const MarketStatusBanner({
    super.key,
    this.market,
    this.autoPoll = true,
  });

  @override
  State<MarketStatusBanner> createState() => _MarketStatusBannerState();
}

class _MarketStatusBannerState extends State<MarketStatusBanner> {
  MarketStatusInfo _status = MarketStatusInfo.empty;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    if (widget.autoPoll) _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 5 minutes if market is open, 30 minutes if closed
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await mobileApi.getMarketStatus();
      if (mounted && data.isNotEmpty) {
        setState(() {
          _status = MarketStatusInfo.fromJson(data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[MarketBanner] Failed to fetch status: $e');
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final isOpen = _status.isOpen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? const Color(0xFF76FF03) : const Color(0xFFFF5252),
              boxShadow: isOpen
                  ? [
                      BoxShadow(
                          color: const Color(0xFF76FF03).withValues(alpha: 0.6),
                          blurRadius: 6)
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOpen
                  ? 'السوق ${_status.marketName ?? ''} مفتوح الآن'
                  : 'السوق ${_status.marketName ?? ''} مغلق الآن',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_status.remainingTime != null)
            Text(
              isOpen
                  ? 'متبقي ${_status.remainingTime}'
                  : 'يفتح ${_status.nextOpen ?? _status.remainingTime}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

/// Persistent market status banner that sits below the AppBar
class PersistentMarketBanner extends StatelessWidget {
  final String? market;

  const PersistentMarketBanner({super.key, this.market});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarketStatusBanner(market: market),
      ],
    );
  }
}

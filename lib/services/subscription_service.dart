import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';

class FeatureAccessResult {
  final String feature;
  final bool hasAccess;
  final String? reason;
  final String? reasonEn;
  final String tier;
  final int remainingToday;
  final int? limitPerDay;
  final DateTime? resetsAt;
  final String? upgradeTo;

  FeatureAccessResult({
    required this.feature,
    required this.hasAccess,
    this.reason,
    this.reasonEn,
    required this.tier,
    this.remainingToday = 0,
    this.limitPerDay,
    this.resetsAt,
    this.upgradeTo,
  });

  factory FeatureAccessResult.fromJson(Map<String, dynamic> json) =>
      FeatureAccessResult(
        feature: json['feature'] ?? '',
        hasAccess: json['has_access'] ?? false,
        reason: json['reason'],
        reasonEn: json['reason_en'],
        tier: json['tier'] ?? 'free',
        remainingToday: json['remaining_today'] ?? 0,
        limitPerDay: json['limit_per_day'] as int?,
        resetsAt: json['resets_at'] != null
            ? DateTime.tryParse(json['resets_at'].toString())
            : null,
        upgradeTo: json['upgrade_to'],
      );
}

class SubscriptionStatus {
  final String tier;
  final bool isTrial;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? trialEndsAt;
  final String? paymentProvider;
  final Map<String, int> usageToday;
  final Map<String, int?> limits;
  final int maxWatchlist;
  final int maxPortfolio;
  final int maxDailyAiAnalysis;

  SubscriptionStatus({
    required this.tier,
    this.isTrial = false,
    this.isActive = true,
    this.expiresAt,
    this.trialEndsAt,
    this.paymentProvider,
    this.usageToday = const {},
    this.limits = const {},
    this.maxWatchlist = 3,
    this.maxPortfolio = 3,
    this.maxDailyAiAnalysis = 2,
  });

  bool get isPlus => tier == 'plus';
  bool get isPremium => tier == 'premium';
  bool get isFree => tier == 'free' || tier.isEmpty;

  bool hasFeature(String feature) {
    if (isPremium) return true;
    switch (feature) {
      case 'ai_analysis':
        if (isPlus) return true;
        return (usageToday['ai_analysis'] ?? 0) < maxDailyAiAnalysis;
      case 'backtesting':
      case 'ai_learning':
      case 'portfolio_analysis':
        return isPlus || isPremium;
      case 'recommendations':
        return isPlus || isPremium;
      case 'predictions':
        return isPremium;
      case 'reports_export':
        return isPremium;
      case 'portfolio_unlimited':
        return isPlus || isPremium;
      case 'watchlist_unlimited':
        return isPlus || isPremium;
      default:
        return true;
    }
  }

  int remainingToday(String feature) {
    if (isPlus || isPremium) return -1;
    switch (feature) {
      case 'ai_analysis':
        return (maxDailyAiAnalysis - (usageToday['ai_analysis'] ?? 0))
            .clamp(0, maxDailyAiAnalysis);
      default:
        return 0;
    }
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>? ?? json;
    final usage = json['usage_today'] as Map<String, dynamic>? ?? {};
    final limitMap = json['limits'] as Map<String, dynamic>? ?? {};

    return SubscriptionStatus(
      tier: (sub['tier'] ?? sub['plan_id'] ?? 'free').toString().toLowerCase(),
      isTrial: sub['is_trial'] == true,
      isActive: (sub['status'] ?? 'active') == 'active' ||
          (sub['status'] ?? 'active') == 'trialing',
      expiresAt: sub['expires_at'] != null
          ? DateTime.tryParse(sub['expires_at'].toString())
          : null,
      trialEndsAt: sub['trial_ends_at'] != null
          ? DateTime.tryParse(sub['trial_ends_at'].toString())
          : null,
      paymentProvider: sub['payment_provider']?.toString(),
      usageToday: usage.map((k, v) => MapEntry(k, v as int? ?? 0)),
      limits: limitMap.map((k, v) => MapEntry(k, v as int?)),
      maxWatchlist: limitMap['max_watchlist_items'] as int? ?? 3,
      maxPortfolio: limitMap['max_portfolio_items'] as int? ?? 3,
      maxDailyAiAnalysis: limitMap['max_ai_analysis_per_day'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'is_trial': isTrial,
        'is_active': isActive,
        'expires_at': expiresAt?.toIso8601String(),
        'max_watchlist': maxWatchlist,
        'max_portfolio': maxPortfolio,
        'max_daily_ai_analysis': maxDailyAiAnalysis,
      };
}

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  SubscriptionStatus? _currentStatus;
  DateTime? _lastFetch;
  static const _ttl = Duration(minutes: 5);
  static const _cacheKey = 'subscription_status';

  SubscriptionStatus? get currentStatus => _currentStatus;
  String get tier => _currentStatus?.tier ?? 'free';
  bool get isPlus => _currentStatus?.isPlus ?? false;
  bool get isPremium => _currentStatus?.isPremium ?? false;
  bool get isFree => _currentStatus?.isFree ?? true;

  Future<void> init() async {
    await _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        _currentStatus = SubscriptionStatus.fromJson(jsonDecode(cached));
        _lastFetch = DateTime.now();
      }
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    if (_currentStatus == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_currentStatus!.toJson()));
    } catch (_) {}
  }

  Future<SubscriptionStatus> getStatus({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _currentStatus != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _ttl) {
      return _currentStatus!;
    }

    try {
      final response = await api.getCurrentSubscription();
      _currentStatus = SubscriptionStatus.fromJson(response);
      _lastFetch = DateTime.now();
      await _saveToCache();
    } catch (e) {
      debugPrint('[Subscription] Failed to fetch status: $e');
      _currentStatus ??= SubscriptionStatus(tier: 'free');
    }
    return _currentStatus!;
  }

  Future<FeatureAccessResult> checkAccess(String feature) async {
    try {
      final response = await api.dio.post(
        '/api/subscription/check-access',
        data: {'feature': feature},
      );
      return FeatureAccessResult.fromJson(response.data);
    } catch (e) {
      debugPrint('[Subscription] check-access failed: $e');
      await getStatus(forceRefresh: true);
      final has = _currentStatus?.hasFeature(feature) ?? false;
      return FeatureAccessResult(
        feature: feature,
        hasAccess: has,
        tier: _currentStatus?.tier ?? 'free',
        remainingToday: _currentStatus?.remainingToday(feature) ?? 0,
      );
    }
  }

  bool hasAccess(String feature) =>
      _currentStatus?.hasFeature(feature) ?? false;

  bool canAddToWatchlist(int currentCount) {
    if (isPlus || isPremium) return true;
    final max = _currentStatus?.maxWatchlist ?? 3;
    return currentCount < max;
  }

  bool canAddToPortfolio(int currentCount) {
    if (isPlus || isPremium) return true;
    final max = _currentStatus?.maxPortfolio ?? 3;
    return currentCount < max;
  }

  Future<void> clearCache() async {
    _currentStatus = null;
    _lastFetch = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }
}

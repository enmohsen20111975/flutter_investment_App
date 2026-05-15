// ============================================================================
// مساعد الاستثمار Flutter - User & Auth Types
// ============================================================================

import 'json_helpers.dart';

class User {
  final String id;
  final String email;
  final String? username;
  final String? name;
  final String? image;
  final bool? isAdmin;
  final String? subscriptionTier;
  final String? defaultRiskTolerance;
  final bool? isActive;
  final bool? emailVerified;
  final String? lastLogin;
  final String? createdAt;
  
  User({
    required this.id,
    required this.email,
    this.username,
    this.name,
    this.image,
    this.isAdmin,
    this.subscriptionTier,
    this.defaultRiskTolerance,
    this.isActive,
    this.emailVerified,
    this.lastLogin,
    this.createdAt
  });
  
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        username: json['username'],
        name: json['name'],
        image: json['image'],
        isAdmin: parseBool(json['is_admin']),
        subscriptionTier: json['subscription_tier'],
        defaultRiskTolerance: json['default_risk_tolerance'],
        isActive: parseBool(json['is_active']),
        emailVerified: parseBool(json['email_verified']),
        lastLogin: json['last_login'],
        createdAt: json['created_at'],
      );
}

class AuthResponse {
  final bool success;
  final String message;
  final String? messageAr;
  final User? user;
  final String? token;
  final String? tokenType;
  final int? expiresIn;
  final String? apiKey;
  final bool? isNewUser;
  
  AuthResponse({
    required this.success,
    required this.message,
    this.messageAr,
    this.user,
    this.token,
    this.tokenType,
    this.expiresIn,
    this.apiKey,
    this.isNewUser
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        messageAr: json['message_ar'],
        user: json['user'] != null ? User.fromJson(json['user']) : null,
        token: json['token'],
        tokenType: json['token_type'],
        expiresIn: parseInt(json['expires_in']),
        apiKey: json['api_key'],
        isNewUser: parseBool(json['is_new_user']),
      );
}

// Subscription Plan
class SubscriptionPlan {
  final String id;
  final String name;
  final String nameAr;
  final double price;
  final double? priceYearly;
  final String currency;
  final int durationDays;
  final int? trialDays;
  final List<String> features;
  final bool isPopular;
  final int? maxWatchlist;
  final int? maxPortfolio;
  final int? maxAlerts;
  final bool? aiAnalysis;
  final bool? deepAnalysis;
  final bool? prioritySupport;
  
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.price,
    this.priceYearly,
    required this.currency,
    required this.durationDays,
    this.trialDays,
    required this.features,
    this.isPopular = false,
    this.maxWatchlist,
    this.maxPortfolio,
    this.maxAlerts,
    this.aiAnalysis,
    this.deepAnalysis,
    this.prioritySupport,
  });
  
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        nameAr: json['name_ar'] ?? json['name'] ?? '',
        price: parseDouble(json['price']) ?? 0,
        priceYearly: parseDouble(json['price_yearly']),
        currency: json['currency'] ?? 'EGP',
        durationDays: parseInt(json['duration_days']) ?? 30,
        trialDays: parseInt(json['trial_days']),
        features: parseStringList(json['features']),
        isPopular: parseBool(json['is_popular']) ?? false,
        maxWatchlist: parseInt(json['max_watchlist']),
        maxPortfolio: parseInt(json['max_portfolio']),
        maxAlerts: parseInt(json['max_alerts']),
        aiAnalysis: parseBool(json['ai_analysis']),
        deepAnalysis: parseBool(json['deep_analysis']),
        prioritySupport: parseBool(json['priority_support']),
      );
}
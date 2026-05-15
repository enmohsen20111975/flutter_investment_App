// ============================================================================
// مساعد الاستثمار Flutter - Notification Service
// Handles local notifications for recommendations and analysis
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Background notification tapped: ${notificationResponse.payload}');
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ApiClient _api = ApiClient();

  static const String _recommendationsChannel = 'recommendations';
  static const String _analysisChannel = 'daily_analysis';
  
  static const int _recommendationNotificationId = 1001;
  static const int _dailyAnalysisNotificationId = 1002;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          debugPrint('Notification payload: $payload');
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    
    await _createNotificationChannels();
    await _scheduleDailyAnalysis();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel recommendationsChannel =
        AndroidNotificationChannel(
      _recommendationsChannel,
      'التوصيات',
      description: 'إشعارات التوصيات الجديدة',
      importance: Importance.high,
      playSound: true,
    );
    
    const AndroidNotificationChannel analysisChannel =
        AndroidNotificationChannel(
      _analysisChannel,
      'التحليل اليومي',
      description: 'إشعارات التحليل اليومي للسوق',
      importance: Importance.max,
      playSound: true,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(recommendationsChannel);
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(analysisChannel);
  }

  Future<void> _scheduleDailyAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    
    if (!notificationsEnabled) return;
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _analysisChannel,
      'التحليل اليومي',
      channelDescription: 'إشعارات التحليل اليومي للسوق',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'التحليل اليومي',
    );
    
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails();
    
    final NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    try {
      await _notificationsPlugin.periodicallyShow(
        id: _dailyAnalysisNotificationId,
        title: 'التحليل اليومي جاهز',
        body: 'تم تحميل التحليل اليومي للسوق والأسهم',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule periodic notification: $e');
    }
  }

  Future<void> showNewRecommendationNotification(
      String expertName, String ticker, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    
    if (!notificationsEnabled) return;
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _recommendationsChannel,
      'التوصيات',
      channelDescription: 'إشعارات التوصيات الجديدة',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'توصية جديدة',
    );
    
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails();
    
    final NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      id: _recommendationNotificationId,
      title: 'توصية جديدة من $expertName',
      body: '$ticker: $action',
      notificationDetails: notificationDetails,
      payload: 'recommendation_$ticker',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (enabled) {
      await _scheduleDailyAnalysis();
    } else {
      await cancelAllNotifications();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
}
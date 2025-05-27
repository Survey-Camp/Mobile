import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:survey_camp/core/services/survey_question_service.dart';
import 'package:survey_camp/features/survey_page/survey_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final SurveyQuestionService _questionService = SurveyQuestionService();
  static Timer? _exitTimer;
  static AndroidNotificationChannel? _channel;
  static bool _isFacebookActive = false;
  static DateTime? _facebookStartTime;

  // Initialize notification settings
  static Future<void> initialize() async {
    _channel = const AndroidNotificationChannel(
      'background_notification_channel',
      'Background Notifications',
      description: 'Notifications sent when app is in background',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel!);

    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        if (details.payload != null && details.payload!.isNotEmpty) {
          // Add delay to ensure app is ready for navigation
          await Future.delayed(const Duration(milliseconds: 100));
          await _handleNotificationTap(details.payload!);
        }
      },
    );

    print("Notification service initialized");
  }

  // Schedule notification for 5 minutes
  static void scheduleBackgroundNotification() {
    _exitTimer?.cancel();
    
    print("Scheduling background notification");
    _exitTimer = Timer(const Duration(seconds: 10), () {
      print("Timer completed, showing notification");
      _showNotification();
    });
  }

  static Future<void> _showNotification() async {
    print("Attempting to show notification");
    
    try {
      final result = await _questionService.getRandomQuestionFromRandomSurvey();
      if (result.isEmpty || result['question'] == null) return;

      String notificationText = result['question']!;
      String notificationTitle = 'New Survey Question! 📝';
      String surveyId = result['surveyId'] ?? '';
      String category = result['category'] ?? 'information technology';

      var androidDetails = AndroidNotificationDetails(
        _channel!.id,
        _channel!.name,
        channelDescription: _channel!.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          notificationText,
          htmlFormatBigText: true,
          contentTitle: notificationTitle,
        ),
      );

      var notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notificationsPlugin.show(
        0,
        notificationTitle,
        notificationText,
        notificationDetails,
        payload: '$surveyId|$category',
      );
      
      print("Notification displayed successfully");
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  static void onFacebookEnter() {
    _isFacebookActive = true;
    _facebookStartTime = DateTime.now();
    // Cancel any pending notifications
    _exitTimer?.cancel();
  }

  static void onFacebookExit() {
    if (!_isFacebookActive) return; // Don't trigger if Facebook wasn't active
    
    _isFacebookActive = false;
    final now = DateTime.now();
    final minUsageThreshold = const Duration(seconds: 30); // Adjust threshold as needed
    
    // Only schedule notification if user spent meaningful time on Facebook
    if (_facebookStartTime != null && 
        now.difference(_facebookStartTime!) >= minUsageThreshold) {
      scheduleFacebookExitNotification();
    }
    _facebookStartTime = null;
  }

  static void scheduleFacebookExitNotification() {
    _exitTimer?.cancel();
    
    print("Scheduling Facebook exit notification");
    // Reduced delay to 5 seconds after actual exit
    _exitTimer = Timer(const Duration(seconds: 5), () {
      print("Timer completed, showing Facebook exit notification");
      _showFacebookExitNotification();
    });
  }

  static Future<void> _showFacebookExitNotification() async {
    print("Attempting to show Facebook exit notification");
    
    try {
      final result = await _questionService.getRandomQuestionFromRandomSurvey();
      if (result.isEmpty || result['question'] == null) return;

      String notificationText = "You've just finished using Facebook. While you're taking a break, why not answer a quick survey question?\n\n${result['question']}";
      String notificationTitle = 'Quick Survey Break! 📝';
      String surveyId = result['surveyId'] ?? '';
      String category = result['category'] ?? 'information technology';

      var androidDetails = AndroidNotificationDetails(
        _channel!.id,
        _channel!.name,
        channelDescription: _channel!.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          notificationText,
          htmlFormatBigText: true,
          contentTitle: notificationTitle,
        ),
      );

      var notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notificationsPlugin.show(
        1, // Different notification ID from background notifications
        notificationTitle,
        notificationText,
        notificationDetails,
        payload: '$surveyId|$category',
      );
      
      print("Facebook exit notification displayed successfully");
    } catch (e) {
      print("Error showing Facebook exit notification: $e");
    }
  }

  static Future<void> _handleNotificationTap(String payload) async {
    try {
      final parts = payload.split('|');
      if (parts.length != 2) return;

      final surveyId = parts[0];
      final category = parts[1];
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        return;
      }

      // If app is in foreground (can pop), just push the survey page
      if (navigatorKey.currentState?.canPop() ?? false) {
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => SurveyPage(
              surveyId: surveyId,
              categoryName: category,
            ),
          ),
        );
      } else {
        // If app was closed/background, go to home first but don't clear the stack
        await navigatorKey.currentState?.pushNamed(
          '/home',
          arguments: {'initialTab': 'surveys'},
        );
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => SurveyPage(
              surveyId: surveyId,
              categoryName: category,
            ),
          ),
        );
      }

      print("Successfully navigated to survey: $surveyId");
    } catch (e) {
      print("Error handling notification tap: $e");
      // Don't remove until, just push to home
      navigatorKey.currentState?.pushNamed('/home');
    }
  }
}
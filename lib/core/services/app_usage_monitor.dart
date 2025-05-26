import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import './notification_service.dart';
import './facebook_usage_service.dart';

class AppUsageMonitor {
  static const Duration checkInterval = Duration(seconds: 5);
  static Timer? _monitorTimer;
  static bool _wasUsingFacebook = false;

  static void startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(checkInterval, (timer) async {
      await _checkFacebookUsage();
    });
  }

  static void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  static Future<void> _checkFacebookUsage() async {
    bool isUsingFacebook = await _isCurrentlyUsingFacebook();
    
    // Detect when user exits Facebook
    if (_wasUsingFacebook && !isUsingFacebook) {
      NotificationService.scheduleFacebookExitNotification();
    }
    
    _wasUsingFacebook = isUsingFacebook;
  }

  static Future<bool> _isCurrentlyUsingFacebook() async {
    try {
      List<UsageInfo> usageInfo = await UsageStats.queryUsageStats(
        DateTime.now().subtract(const Duration(seconds: 10)),
        DateTime.now(),
      );

      return usageInfo.any((info) => 
        info.packageName == FacebookUsageService.facebookPackage &&
        info.lastTimeUsed != null &&
        DateTime.fromMillisecondsSinceEpoch(int.parse(info.lastTimeUsed!))
            .isAfter(DateTime.now().subtract(const Duration(seconds: 10)))
      );
    } catch (e) {
      print('Error checking Facebook usage: $e');
      return false;
    }
  }
}
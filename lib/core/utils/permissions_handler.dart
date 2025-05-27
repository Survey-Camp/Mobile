import 'package:usage_stats/usage_stats.dart';

class PermissionsHandler {
  Future<bool> checkAndRequestUsagePermission() async {
    bool isGranted = await UsageStats.checkUsagePermission() ?? false;
    if (!isGranted) {
      await UsageStats.grantUsagePermission();
    }
    return isGranted;
  }

  static Future<bool> requestUsagePermission() async {
    await UsageStats.grantUsagePermission();
    return await UsageStats.checkUsagePermission() ?? false;
  }
}

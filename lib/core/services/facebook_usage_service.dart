import 'package:usage_stats/usage_stats.dart';
import '../utils/permissions_handler.dart';
import 'package:usage_stats/usage_stats.dart'; // Ensure this import is present for EventType

class FacebookUsageService {
  static const String facebookPackage = "com.facebook.katana";

  Future<int> getFacebookUsageDuration() async {
    bool isGranted = await (UsageStats.checkUsagePermission() as bool? ?? false);
    if (!isGranted) {
      await PermissionsHandler.requestUsagePermission();
    }

    DateTime endTime = DateTime.now();
    DateTime startTime = endTime.subtract(Duration(days: 1)); 

    List<UsageInfo> usageInfoList = await UsageStats.queryUsageStats(
        startTime, endTime);

    Map<String, UsageInfo> stats = {
      for (var info in usageInfoList) if (info.packageName != null) info.packageName!: info
    };

    if (stats.containsKey(facebookPackage)) {
      return int.parse(stats[facebookPackage]?.totalTimeInForeground ?? '0');
    }
    return 0;
  }
}

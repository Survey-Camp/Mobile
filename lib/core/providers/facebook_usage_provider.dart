import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/facebook_usage_service.dart';

class FacebookUsageNotifier extends StateNotifier<int> {
  final FacebookUsageService _service;

  FacebookUsageNotifier(this._service) : super(0);

  Future<void> updateFacebookUsage() async {
    state = await _service.getFacebookUsageDuration();
  }
}

final facebookUsageProvider =
    StateNotifierProvider<FacebookUsageNotifier, int>((ref) {
  return FacebookUsageNotifier(FacebookUsageService());
});

// lib/services/shared_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role_model.dart';

class SharedPrefsService {
  static const String _userRoleKey = 'user_role';
  static const String _themeKey = 'theme_mode';
  static const String _tokenKey = 'fcm_token';
  static const String _onboardingKey = 'completed_onboarding';
  static const String _lastLoginKey = 'last_login';

  late final SharedPreferences _prefs;

  // Singleton pattern
  static SharedPrefsService? _instance;
  static Future<SharedPrefsService> get instance async {
    if (_instance == null) {
      final service = SharedPrefsService();
      await service._init();
      _instance = service;
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // // User Role Management
  // Future<void> setUserRole(UserRole role) async {
  //   await _prefs.setString(_userRoleKey, role.name);
  // }

  // UserRole? getUserRole() {
  //   final roleStr = _prefs.getString(_userRoleKey);
  //   if (roleStr == null) return null;

  //   try {
  //     return UserRole.values.byName(roleStr);
  //   } catch (_) {
  //     return null;
  //   }
  // }

  Future<void> clearUserRole() async {
    await _prefs.remove(_userRoleKey);
  }

  // Theme Management
  Future<void> setThemeMode(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  String getThemeMode() {
    return _prefs.getString(_themeKey) ?? 'system';
  }

  // FCM Token Management
  Future<void> setFCMToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getFCMToken() {
    return _prefs.getString(_tokenKey);
  }

  // Onboarding Status
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingKey, completed);
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  // Last Login Tracking
  Future<void> updateLastLogin() async {
    await _prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
  }

  DateTime? getLastLogin() {
    final timestamp = _prefs.getInt(_lastLoginKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyBaseApiUrl = 'base_api_url';
  static const String _keyActiveBranchId = 'active_branch_id';
  static const String _keyActiveBranchName = 'active_branch_name';

  Future<void> saveBaseApiUrl(String url) async {
    await _prefs?.setString(_keyBaseApiUrl, url.trim());
  }

  String? getBaseApiUrl() {
    return _prefs?.getString(_keyBaseApiUrl);
  }

  Future<void> saveActiveBranch({String? branchId, required String branchName}) async {
    if (branchId == null || branchId.isEmpty) {
      await _prefs?.remove(_keyActiveBranchId);
    } else {
      await _prefs?.setString(_keyActiveBranchId, branchId);
    }
    await _prefs?.setString(_keyActiveBranchName, branchName);
  }

  String? getActiveBranchId() {
    return _prefs?.getString(_keyActiveBranchId);
  }

  String? getActiveBranchName() {
    return _prefs?.getString(_keyActiveBranchName);
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {
      // Web fallback
      _prefs?.setString(_keyAccessToken, accessToken);
      _prefs?.setString(_keyRefreshToken, refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _keyAccessToken);
      if (token != null) return token;
    } catch (_) {}
    return _prefs?.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _keyRefreshToken);
      if (token != null) return token;
    } catch (_) {}
    return _prefs?.getString(_keyRefreshToken);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs?.setString(_keyUserData, jsonEncode(user));
  }

  Map<String, dynamic>? getUser() {
    final raw = _prefs?.getString(_keyUserData);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? getUserRole() {
    final user = getUser();
    return user?['role'] as String?;
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    await _prefs?.clear();
  }
}

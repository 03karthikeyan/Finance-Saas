import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response_model.dart';
import '../../../core/storage/storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  Future<ApiResponseModel<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final cleanInput = email.trim();
    String identifier = cleanInput;
    if (!cleanInput.contains('@')) {
      final digits = cleanInput.replaceAll(RegExp(r'\D'), '');
      final phone10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
      identifier = '$phone10@mwtfinance.com';
    }

    var response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': identifier, 'password': password},
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    // If formatted email attempt failed and raw input was different, retry with raw input
    if (!response.success && identifier != cleanInput) {
      final retry = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': cleanInput, 'password': password},
        fromJsonT: (data) => data as Map<String, dynamic>,
      );
      if (retry.success) {
        response = retry;
      }
    }

    if (response.success && response.data != null) {
      final data = response.data!;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final user = data['user'] as Map<String, dynamic>?;

      if (accessToken != null && refreshToken != null) {
        await _storageService.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      }
      if (user != null) {
        await _storageService.saveUser(user);
      }
    }

    return response;
  }

  Future<Map<String, dynamic>?> validateSession() async {
    final token = await _storageService.getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final user = response.data!['user'] as Map<String, dynamic>? ?? response.data!;
        await _storageService.saveUser(user);
        return user;
      }
    } catch (_) {}

    // If profile verification fails (e.g. user deleted or fresh DB), wipe local storage
    await _storageService.clearAll();
    return null;
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Map<String, dynamic>? getSavedUser() {
    return _storageService.getUser();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/storage_service.dart';
import 'api_response_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final StreamController<void> _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseApiUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService().getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          log('API Error: [${error.requestOptions.method}] ${error.requestOptions.path} => ${error.response?.statusCode} ${error.message}');
          if (error.response?.statusCode == 401) {
            // Token is invalid/expired/user not found in active database -> wipe stale session
            await StorageService().clearAll();
            _unauthorizedController.add(null);
          }
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    AppConfig.setBaseApiUrl(cleanUrl);
    dio.options.baseUrl = cleanUrl;
  }

  /// Test connectivity to a specific server URL or the current active baseUrl
  Future<Map<String, dynamic>> testConnection([String? targetUrl]) async {
    final url = (targetUrl != null && targetUrl.trim().isNotEmpty)
        ? targetUrl.trim()
        : dio.options.baseUrl;
    
    // Normalise health endpoint
    String healthEndpoint = url;
    if (!healthEndpoint.endsWith('/health')) {
      if (healthEndpoint.endsWith('/api/v1')) {
        healthEndpoint = '$healthEndpoint/health';
      } else if (healthEndpoint.endsWith('/api/v1/')) {
        healthEndpoint = '${healthEndpoint}health';
      } else {
        healthEndpoint = '$healthEndpoint/api/v1/health';
      }
    }

    final stopwatch = Stopwatch()..start();
    try {
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await testDio.get(healthEndpoint);
      stopwatch.stop();
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connected successfully! (Status 200 OK)',
          'latencyMs': stopwatch.elapsedMilliseconds,
          'data': res.data,
        };
      } else {
        return {
          'success': false,
          'message': 'Server responded with HTTP ${res.statusCode}',
          'latencyMs': stopwatch.elapsedMilliseconds,
        };
      }
    } on DioException catch (e) {
      stopwatch.stop();
      String errorMsg;
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Connection timed out. Ensure PC and Phone are on the same Wi-Fi.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Connection refused. Verify backend is running on port 5000.';
      } else {
        errorMsg = e.message ?? 'Failed to reach server endpoint.';
      }
      return {
        'success': false,
        'message': errorMsg,
        'latencyMs': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'message': 'Failed: $e',
        'latencyMs': stopwatch.elapsedMilliseconds,
      };
    }
  }

  Future<ApiResponseModel<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await dio.get(endpoint, queryParameters: queryParameters);
      return ApiResponseModel<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponseModel<T>(success: false, message: 'Unexpected client error: $e');
    }
  }

  Future<ApiResponseModel<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await dio.post(endpoint, data: data, queryParameters: queryParameters);
      return ApiResponseModel<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponseModel<T>(success: false, message: 'Unexpected client error: $e');
    }
  }

  Future<ApiResponseModel<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await dio.put(endpoint, data: data, queryParameters: queryParameters);
      return ApiResponseModel<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponseModel<T>(success: false, message: 'Unexpected client error: $e');
    }
  }

  Future<ApiResponseModel<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await dio.delete(endpoint, data: data, queryParameters: queryParameters);
      return ApiResponseModel<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponseModel<T>(success: false, message: 'Unexpected client error: $e');
    }
  }

  ApiResponseModel<T> _handleDioError<T>(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final map = error.response!.data as Map<String, dynamic>;
      return ApiResponseModel<T>(
        success: false,
        message: map['message']?.toString() ?? 'Server error occurred',
        errors: map['errors'] as List<dynamic>?,
      );
    }
    return ApiResponseModel<T>(
      success: false,
      message: error.message ?? 'Network connection error. Please verify backend is running on ${dio.options.baseUrl}.',
    );
  }
}

import 'package:dio/dio.dart';

import '../../config/env_config.dart';
import '../../constants/app_constants.dart';
import '../error/exceptions.dart';
import '../utils/app_logger.dart';

/// Configured [Dio] instance for the SurePass verification API.
///
/// Adds the bearer token, sensible timeouts, structured logging (with PII
/// redaction) and centralised error mapping to [ServerException]/
/// [NetworkException].
class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio
      ..options.baseUrl = EnvConfig.surepassBaseUrl
      ..options.connectTimeout = AppConstants.networkTimeout
      ..options.receiveTimeout = AppConstants.networkTimeout
      ..options.headers = {
        'Authorization': 'Bearer ${EnvConfig.surepassApiToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          AppLogger.e(
            'API error: ${error.requestOptions.path}',
            error: error.message,
          );
          handler.next(error);
        },
      ),
    );

    if (!EnvConfig.isProduction) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          // Never log Authorization headers.
          requestHeader: false,
          logPrint: (obj) => AppLogger.d(obj),
        ),
      );
    }
  }

  final Dio _dio;

  Dio get raw => _dio;

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _wrap(() => _dio.post<T>(path, data: data, queryParameters: queryParameters));

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _wrap(() => _dio.get<T>(path, queryParameters: queryParameters));

  /// Maps Dio transport errors to domain exceptions.
  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw NetworkException('Request timed out. Please try again.');
        case DioExceptionType.connectionError:
          throw NetworkException();
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          final message = _extractMessage(e.response?.data) ??
              'Server error. Please try again later.';
          throw ServerException(message, statusCode: status);
        default:
          throw ServerException(e.message ?? 'Unexpected network error.');
      }
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? data['msg']) as String?;
    }
    return null;
  }
}

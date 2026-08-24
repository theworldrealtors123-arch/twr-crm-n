import 'package:dio/dio.dart';

import '../../services/secure_storage_service.dart';
import '../config/app_config.dart';
import '../errors/api_exception.dart';

/// Thin wrapper over Dio that
///  * attaches the access token to every request,
///  * transparently refreshes an expired access token exactly once,
///  * signals the app to return to Login when the refresh token is dead,
///  * converts every failure into an [ApiException] with a readable message.
class ApiClient {
  ApiClient({
    required SecureStorageService storage,
    Dio? dio,
    this.onAuthenticationLost,
  })  : _storage = storage,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..headers = <String, dynamic>{'Content-Type': 'application/json'}
      ..validateStatus = (int? status) => status != null && status < 400;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          if (options.extra['skipAuth'] != true) {
            final String? token = await _storage.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final bool canRetry = error.response?.statusCode == 401 &&
              error.requestOptions.extra['retried'] != true &&
              error.requestOptions.extra['skipAuth'] != true;

          if (canRetry) {
            final bool refreshed = await _refreshTokens();
            if (refreshed) {
              try {
                error.requestOptions.extra['retried'] = true;
                final String? token = await _storage.readAccessToken();
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                final Response<dynamic> response =
                    await _dio.fetch<dynamic>(error.requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
            await _storage.clear();
            onAuthenticationLost?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStorageService _storage;

  /// Invoked when the session cannot be recovered - the app returns to Login.
  final void Function()? onAuthenticationLost;

  Dio get dio => _dio;

  bool _refreshing = false;

  Future<bool> _refreshTokens() async {
    if (_refreshing) {
      return false;
    }
    _refreshing = true;
    try {
      final String? refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      final Response<dynamic> response = await Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
        ),
      ).post<dynamic>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      final Map<String, dynamic> body =
          Map<String, dynamic>.from(response.data as Map<dynamic, dynamic>);
      await _storage.saveTokens(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool skipAuth = false,
  }) async {
    return _request(() => _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
          options: Options(extra: <String, dynamic>{'skipAuth': skipAuth}),
        ));
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) async {
    return _request(() => _dio.post<dynamic>(
          path,
          data: data,
          options: Options(extra: <String, dynamic>{'skipAuth': skipAuth}),
        ));
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    return _request(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<dynamic> delete(String path) async {
    return _request(() => _dio.delete<dynamic>(path));
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() send) async {
    try {
      final Response<dynamic> response = await send();
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return ApiException('Unable to connect. Please try again.');
    }

    final int? status = error.response?.statusCode;
    final dynamic data = error.response?.data;

    String message = 'Something went wrong. Please try again.';
    List<String>? fieldErrors;

    if (data is Map) {
      final dynamic raw = data['message'];
      if (raw is String) {
        message = raw;
      } else if (raw is List) {
        fieldErrors = raw.map((dynamic e) => e.toString()).toList();
        message = fieldErrors.first;
      }
    }

    if (status == 401) {
      message = data is Map && data['message'] is String
          ? data['message'] as String
          : 'Your session has expired. Please log in again.';
    } else if (status == 403) {
      message = data is Map && data['message'] is String
          ? data['message'] as String
          : 'You do not have permission to perform this action.';
    } else if (status == 404) {
      message = data is Map && data['message'] is String
          ? data['message'] as String
          : 'Not found.';
    } else if (status != null && status >= 500) {
      message = 'The server is not responding. Please try again shortly.';
    }

    return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
  }
}

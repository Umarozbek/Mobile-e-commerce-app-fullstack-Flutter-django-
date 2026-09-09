import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constans/api_consts.dart';
import '../service/logout_storage.dart';
import '../service/secure_storage.dart';
import '../service/session_expired_service.dart';
import '../utils/logger.dart';

class ApiClient {
  final SessionExpiredService _sessionExpiredService;
  final String baseUrl = ApiConsts.baseUrl;
  late final Dio dio;
  String? token;

  ApiClient(this._sessionExpiredService) {
    dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..interceptors.add(CustomErrorInterceptor(_sessionExpiredService));
  }

  /// Default headers
  Future<Map<String, String>> _defaultHeader({bool isMultiPart = false}) async {
    token = await SecureStorage().read(key: 'accessToken') ?? "";
    final headers = <String, String>{
      'Accept': '*/*',
    };
    if ((token ?? "").isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      headers['Content-Type'] = "application/json";
    }
    if (isMultiPart) {
      // multipart uchun qo'shimcha header kerak bo'lsa
    }
    return headers;
  }

  /// Generic request method
  Future<StatusModel> _request(
      String path, {
        required String method,
        Map<String, dynamic>? body,
        Map<String, dynamic>? queryParams,
        bool isHeader = true,
        bool isMultiPart = false,
        bool anotherLink = false,
        Map<String, String>? customHeaders,
      }) async {
    final url = anotherLink ? path : "$baseUrl$path";
    final Map<String, String> headers = isHeader ? await _defaultHeader(isMultiPart: isMultiPart) : {"Content-Type": "application/json"};

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    try {
      final response = await dio.request(
        url,
        data: isMultiPart && body is Map ? FormData.fromMap(body!) : body is Map ? jsonEncode(body) : body,
        queryParameters: queryParams,
        options: Options(
          method: method,
          headers: headers,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      if (kDebugMode) {
        // Token, headers va response logda chiqmasin — xavfsizlik
        logger.i("$method $url → ${response.statusCode} \n headers: $headers");
      }

      if ((response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300) {
        return StatusModel(response: response.data, isSuccess: true, code: response.statusCode);
      }

      final errorData = _parseErrorData(response.data);
      return StatusModel(
        response: errorData,
        isSuccess: false,
        code: response.statusCode,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        logger.e(
          "$method request failed URL: $url\nError: ${e.response?.statusCode}",
        );
      }
      return _handleDioError(e);
    }
  }

  Future<StatusModel> post(String path, {Map<String, dynamic>? body, bool isHeader = true, bool isMultiPart = false, bool anotherLink = false, Map<String, String>? customHeaders}) =>
      _request(path, method: "POST", body: body, isHeader: isHeader, isMultiPart: isMultiPart, anotherLink: anotherLink, customHeaders: customHeaders);

  Future<StatusModel> get(String path, {Map<String, dynamic>? queryParams, bool isHeader = true, bool anotherLink = false, Map<String, String>? customHeaders}) =>
      _request(path, method: "GET", queryParams: queryParams, isHeader: isHeader, anotherLink: anotherLink, customHeaders: customHeaders);

  Future<StatusModel> put(String path, {dynamic body, bool isHeader = true, bool isMultiPart = false, Map<String, String>? customHeaders}) =>
      _request(path, method: "PUT", body: body, isHeader: isHeader, isMultiPart: isMultiPart, customHeaders: customHeaders);

  Future<StatusModel> patch(String path, {Map<String, dynamic>? body, bool isHeader = true, Map<String, String>? customHeaders}) =>
      _request(path, method: "PATCH", body: body, isHeader: isHeader, customHeaders: customHeaders);

  Future<StatusModel> delete(String path, {Map<String, dynamic>? body, bool isHeader = true, Map<String, String>? customHeaders}) =>
      _request(path, method: "DELETE", body: body ?? {}, isHeader: isHeader, customHeaders: customHeaders);

  StatusModel _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return StatusModel(response: "Connection Error", isSuccess: false, code: 600);
    }
    if ((e.response?.statusCode ?? 0) >= 500) {
      return StatusModel(response: "Server Error", isSuccess: false, code: 500);
    }
    final errorData = _parseErrorData(e.response?.data);
    return StatusModel(response: errorData, isSuccess: false, code: e.response?.statusCode ?? 500);
  }

  dynamic _parseErrorData(dynamic data) {
    dynamic errorData = data;
    if (errorData is Map) {
      if (errorData['error'] != null) {
        errorData = errorData['error'];
      } else if (errorData['message'] != null) {
        errorData = errorData['message'];
      }
    }
    return errorData ?? "Error";
  }
}

class StatusModel {
  final dynamic response;
  final int? code;
  final bool isSuccess;

  StatusModel({required this.response, required this.isSuccess, required this.code});

  factory StatusModel.defaultValue() => StatusModel(response: "Error", isSuccess: false, code: 700);
}

class CustomErrorInterceptor extends Interceptor {
  final SessionExpiredService _sessionExpiredService;

  CustomErrorInterceptor(this._sessionExpiredService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains("/login") ||
        path.contains("/register") ||
        path.contains("/verify-otp") ||
        path.contains("/set-password");

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      try {
        final refreshToken = await SecureStorage().read(key: 'refreshToken') ?? "";
        final dio = Dio();
        dio.interceptors.clear();
        final response = await dio.post(
          ApiConsts.refreshTokenUrl,
          options: Options(headers: {"Authorization": "Bearer $refreshToken"}),
        );
        if (response.statusCode == 200) {
          final newAccessToken = response.data['access_token'].toString();
          final newRefreshToken = response.data['refresh_token'].toString();
          await SecureStorage().write(key: "accessToken", value: newAccessToken);
          await SecureStorage().write(key: "refreshToken", value: newRefreshToken);

          err.requestOptions.headers["Authorization"] = "Bearer $newAccessToken";
          final cloneReq = await dio.fetch(err.requestOptions);
          handler.resolve(cloneReq);
          return;
        }
      } catch (_) {
        await LogoutStorage.clearForLogout();
        _sessionExpiredService.notifySessionExpired();
      }
    }
    handler.next(err);
  }
}

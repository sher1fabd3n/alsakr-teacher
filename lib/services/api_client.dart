import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            ),
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            sendTimeout: ApiConfig.connectTimeout,
            followRedirects: true,
            maxRedirects: 5,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Accept-Language': 'ar',
            },
          ),
        ) {
    attachSchoolHttps(_dio);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path.toLowerCase();
          final isLogin = path.contains('/login');
          if (!isLogin) {
            try {
              final token = await _storage.read(key: _tokenKey);
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (_) {}
          }
          handler.next(options);
        },
      ),
    );
  }

  static const _tokenKey = 'auth_token';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Dio get dio => _dio;

  static void attachSchoolHttps(Dio dio) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 20);
        client.connectionTimeout = ApiConfig.connectTimeout;
        client.userAgent = 'Mozilla/5.0 AlSakrTeacher/1.0';
        client.badCertificateCallback = (cert, host, port) =>
            isSchoolCertificate(host, cert);
        return client;
      },
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        return isSchoolCertificate(host, cert);
      },
    );
  }

  static const _trustedHosts = {
    'alsakrschools.com',
    'www.alsakrschools.com',
  };

  static bool isSchoolCertificate(String host, X509Certificate cert) {
    final normalized = host.toLowerCase().trim();
    if (!_trustedHosts.contains(normalized)) return false;

    final now = DateTime.now().toUtc();
    if (now.isBefore(cert.startValidity.toUtc()) ||
        now.isAfter(cert.endValidity.toUtc())) {
      return false;
    }

    return true;
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  Future<void> writeSecure(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> readSecure(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteSecure(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<Response<T>> postWithRetry<T>(
    String path, {
    Object? data,
    int attempts = 3,
  }) async {
    DioException? lastError;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        return await _dio.post<T>(path, data: data);
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        final retryable = code == 500 ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.badCertificate;
        if (!retryable || attempt == attempts - 1) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw lastError!;
  }

  String extractErrorMessage(DioException error) {
    final data = error.response?.data;
    final fromJson = _messageFromBody(data);
    if (fromJson != null && fromJson.isNotEmpty) return fromJson;

    final statusCode = error.response?.statusCode;
    final inner = '${error.error ?? ''} ${error.message ?? ''}'.toLowerCase();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة الاتصال بالسيرفر. حاول مرة أخرى مع شبكة مستقرة.';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالسيرفر. تأكد من الإنترنت وأن الموقع https://alsakrschools.com يعمل.';
      case DioExceptionType.badCertificate:
        return 'تعذر التحقق من شهادة الموقع على هذا الجهاز. حدّث التطبيق وأعد المحاولة.';
      default:
        break;
    }

    if (inner.contains('handshake') ||
        inner.contains('certificate') ||
        inner.contains('tls') ||
        inner.contains('ssl')) {
      return 'تعذر إنشاء اتصال آمن على هذا الجهاز. تأكد من الإنترنت وحدّث التطبيق.';
    }
    if (inner.contains('socket') ||
        inner.contains('failed host lookup') ||
        inner.contains('network is unreachable') ||
        inner.contains('connection refused')) {
      return 'لا يمكن الوصول إلى السيرفر من هذا الجهاز. تحقق من الإنترنت وعنوان الموقع.';
    }

    if (statusCode == 500) {
      return 'السيرفر أرجع خطأ داخلي. حاول مرة أخرى بعد قليل.';
    }
    if (statusCode == 401) {
      return 'بيانات الدخول غير صحيحة.';
    }
    if (statusCode == 404 || statusCode == 405) {
      return 'مسار تسجيل الدخول غير موجود على السيرفر. تأكد أن نسخة الويب المنشورة هي الأحدث.';
    }
    if (data is String && data.contains('An error occurred')) {
      return 'الموقع على السيرفر توقف بخطأ. أعد رفع المشروع بدون استبدال ملف إعدادات الاستضافة.';
    }
    if (statusCode != null) {
      return 'تعذر تسجيل الدخول (رمز $statusCode). حاول مرة أخرى.';
    }
    return 'تعذر الاتصال بخدمة الدخول. تحقق من الإنترنت ثم حاول مرة أخرى.';
  }

  static String? _messageFromBody(dynamic data) {
    if (data is Map) {
      final message = data['message'] ?? data['Message'];
      if (message != null) return message.toString();
    }
    if (data is String && data.trim().isNotEmpty) {
      final trimmed = data.trim();
      if (trimmed.startsWith('{') && trimmed.contains('message')) {
        final match = RegExp(r'"[Mm]essage"\s*:\s*"([^"]+)"').firstMatch(trimmed);
        if (match != null) return match.group(1);
      }
    }
    return null;
  }
}

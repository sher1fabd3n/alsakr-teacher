import 'package:dio/dio.dart';

import '../features/admin/models/parent_account_models.dart';
import '../models/student_models.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  StudentProfile? _currentStudent;
  ParentProfile? _currentParent;
  static const _mobileRoleKey = 'mobile_auth_role';

  StudentProfile? get currentStudent => _currentStudent;
  ParentProfile? get currentParent => _currentParent;

  Future<String?> readMobileToken() => _apiClient.readToken();
  Future<String?> readMobileRole() => _apiClient.readSecure(_mobileRoleKey);

  Future<void> restoreSession() async {
    final token = await _apiClient.readToken();
    if (token == null || token.isEmpty) {
      _currentStudent = null;
      _currentParent = null;
      return;
    }

    final role = await readMobileRole();
    if (role == 'Parent') {
      _currentStudent = null;
      try {
        final response = await _apiClient.dio.get('/api/parent/profile');
        _currentParent = ParentProfile.fromJson(response.data as Map<String, dynamic>);
      } on DioException {
        await _apiClient.clearToken();
        _currentParent = null;
      }
      return;
    }
    if (role == 'Teacher' || role == 'Admin' || role == 'Driver') {
      _currentStudent = null;
      _currentParent = null;
      return;
    }

    try {
      final response = await _apiClient.dio.get('/api/student/profile');
      _currentStudent = StudentProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException {
      await _apiClient.clearToken();
      _currentStudent = null;
    }
  }

  Future<StudentProfile> loginStudent(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _apiClient.saveToken(loginResponse.token);
      await _apiClient.writeSecure(_mobileRoleKey, 'Student');
      _currentStudent = loginResponse.student;
      return loginResponse.student;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ParentLoginResponse> loginParent(String nationalId, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/communication/auth/parent/login',
        data: {'username': nationalId.trim(), 'password': password},
      );
      final loginResponse = ParentLoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (!loginResponse.profile.canLogin) {
        throw Exception(
          loginResponse.profile.status == ParentAccountStatus.inactive
              ? 'الحساب غير نشط. تواصل مع الإدارة.'
              : 'لا يمكن تسجيل الدخول. حالة الحساب: ${loginResponse.profile.status.labelAr}',
        );
      }
      await _apiClient.saveToken(loginResponse.token);
      await _apiClient.writeSecure(_mobileRoleKey, 'Parent');
      _currentParent = loginResponse.profile;
      return loginResponse;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  void updateCurrentParent(ParentProfile profile) => _currentParent = profile;

  Future<Map<String, dynamic>> loginTeacher(String email, String password) async {
    try {
      final response = await _apiClient.postWithRetry(
        '/api/communication/auth/teacher/login',
        data: {'username': email.trim(), 'password': password.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      await _apiClient.saveToken(data['token'] as String);
      await _apiClient.writeSecure(_mobileRoleKey, 'Teacher');
      return data;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    await _apiClient.deleteSecure(_mobileRoleKey);
    _currentStudent = null;
    _currentParent = null;
  }
}

class StudentService {
  StudentService(this._apiClient);

  final ApiClient _apiClient;

  Future<StudentProfile> getProfile() async {
    return _get(() => _apiClient.dio.get('/api/student/profile'), StudentProfile.fromJson);
  }

  Future<StudentResultsResponse> getResults() async {
    return _get(
      () => _apiClient.dio.get('/api/student/results'),
      StudentResultsResponse.fromJson,
    );
  }

  Future<StudentFeesResponse> getFees() async {
    return _get(
      () => _apiClient.dio.get('/api/student/fees'),
      StudentFeesResponse.fromJson,
    );
  }

  Future<List<StudentVideo>> getVideos() async {
    try {
      final response = await _apiClient.dio.get('/api/student/videos');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => StudentVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<T> _get<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      return fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}

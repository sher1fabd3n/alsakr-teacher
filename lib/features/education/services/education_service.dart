import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import '../models/education_models.dart';

class EducationService {
  EducationService(this._apiClient);

  final ApiClient _apiClient;

  // ── المراحل التعليمية ───────────────────────────────────────────────────

  Future<List<EducationStage>> getEducationStages() async {
    try {
      final response = await _apiClient.dio.get('/api/education/stages');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => EducationStage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<EducationStage?> getEducationStage(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/education/stages/$id');
      return EducationStage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── المستويات التعليمية ─────────────────────────────────────────────────

  Future<List<EducationLevel>> getEducationLevels({int? stageId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/levels',
        queryParameters: {if (stageId != null) 'stageId': stageId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => EducationLevel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<EducationLevel?> getEducationLevel(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/education/levels/$id');
      return EducationLevel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── الفصول الدراسية ─────────────────────────────────────────────────────

  Future<List<AcademicClass>> getAcademicClasses({
    int? levelId,
    int? academicYearId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/classes',
        queryParameters: {
          if (levelId != null) 'levelId': levelId,
          if (academicYearId != null) 'academicYearId': academicYearId,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AcademicClass.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<AcademicClass?> getAcademicClass(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/education/classes/$id');
      return AcademicClass.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── المواد الدراسية ─────────────────────────────────────────────────────

  Future<List<Subject>> getSubjects() async {
    try {
      final response = await _apiClient.dio.get('/api/education/subjects');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<Subject?> getSubject(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/education/subjects/$id');
      return Subject.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── السنة الدراسية ─────────────────────────────────────────────────────

  Future<AcademicYear?> getActiveAcademicYear() async {
    try {
      final response = await _apiClient.dio.get('/api/education/academic-years/active');
      return AcademicYear.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<AcademicYear>> getAcademicYears() async {
    try {
      final response = await _apiClient.dio.get('/api/education/academic-years');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AcademicYear.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── البيانات الخاصة بالمعلم ─────────────────────────────────────────────

  Future<TeacherMobileProfile> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/education/teacher/profile');
      return TeacherMobileProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/education/teacher/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<TeacherAssignment>> getMyAssignments({int? academicYearId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/teacher/my-assignments',
        queryParameters: {if (academicYearId != null) 'academicYearId': academicYearId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => TeacherAssignment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<AcademicClass>> getMyClasses({int? academicYearId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/teacher/my-classes',
        queryParameters: {if (academicYearId != null) 'academicYearId': academicYearId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AcademicClass.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    } catch (e) {
      throw Exception('تعذر قراءة قائمة الفصول.');
    }
  }

  Future<List<Student>> getClassStudents(int classId, {int? academicYearId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/teacher/class/$classId/students',
        queryParameters: {if (academicYearId != null) 'academicYearId': academicYearId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getMyParentReports() async {
    try {
      final response = await _apiClient.dio.get('/api/education/teacher/parent-reports');
      final data = response.data;
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getMyParentReportTargets() async {
    try {
      final response = await _apiClient.dio.get('/api/education/teacher/parent-reports/targets');
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<String> createParentReport({
    required String title,
    required String body,
    required String targetType,
    int? academicClassId,
    int? educationLevelId,
    int? educationStageId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/education/teacher/parent-reports',
        data: {
          'title': title,
          'body': body,
          'targetType': targetType,
          'academicClassId': ?academicClassId,
          'educationLevelId': ?educationLevelId,
          'educationStageId': ?educationStageId,
        },
      );
      final data = response.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return 'تم إرسال التقرير.';
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> listControlExams() async {
    try {
      final response = await _apiClient.dio.get('/api/education/teacher/exam-control/exams');
      final data = response.data;
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> listControlTargets() async {
    try {
      final response = await _apiClient.dio.get('/api/education/teacher/exam-control/targets');
      final data = response.data;
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getControlSheet({required int examId, required int classId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/teacher/exam-control/sheet',
        queryParameters: {'examId': examId, 'classId': classId},
      );
      return (response.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<String> saveControlGrades({
    required int examId,
    required int classId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/education/teacher/exam-control/grades',
        data: {'examId': examId, 'academicClassId': classId, 'items': items},
      );
      final data = response.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return 'تم حفظ الدرجات.';
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<String> submitControlGrades({required int examId, required int classId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/education/teacher/exam-control/submit',
        data: {'examId': examId, 'academicClassId': classId},
      );
      final data = response.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return 'تم الإرسال للاعتماد.';
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<Subject>> getClassSubjects(int classId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/teacher/class/$classId/subjects',
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}
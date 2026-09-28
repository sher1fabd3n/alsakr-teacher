import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import '../models/education_content_models.dart';

class EducationContentService {
  EducationContentService(this._apiClient);

  final ApiClient _apiClient;

  // ── Attendance ──────────────────────────────────────────────────────

  Future<List<AttendanceStudent>> getClassAttendance(
    int classId, {
    DateTime? date,
  }) async {
    try {
      final dateStr = date != null
          ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
          : null;
      final response = await _apiClient.dio.get(
        '/api/education/attendance/class/$classId/date',
        queryParameters: {if (dateStr != null) 'date': dateStr},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AttendanceStudent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<int> saveAttendance({
    required int classId,
    required int academicYearId,
    required DateTime date,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiClient.dio.post(
        '/api/education/attendance/save',
        data: {
          'academicClassId': classId,
          'academicYearId': academicYearId,
          'date': dateStr,
          'items': items,
        },
      );
      return (response.data as Map<String, dynamic>)['savedCount'] as int? ?? 0;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<AttendanceReport> getAttendanceReport(
    int classId, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/attendance/report',
        queryParameters: {
          'classId': classId,
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
      );
      return AttendanceReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<int>> downloadAttendanceReport({
    required int classId,
    int? year,
    int? month,
    String format = 'xlsx',
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/attendance/report/export',
        queryParameters: {
          'classId': classId,
          if (year != null) 'year': year,
          if (month != null) 'month': month,
          'format': format,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data is List<int>) return data;
      if (data is List) return data.cast<int>();
      throw Exception('تعذر تنزيل التقرير.');
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── Quizzes ─────────────────────────────────────────────────────────

  Future<List<QuizSummary>> getMyQuizzes({int? classId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/quizzes/mine',
        queryParameters: {if (classId != null) 'classId': classId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => QuizSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<QuizDetail> getQuizDetail(int quizId) async {
    try {
      final response = await _apiClient.dio.get('/api/education/quizzes/$quizId');
      return QuizDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<int> createQuiz({
    required int classId,
    required int subjectId,
    required int academicYearId,
    required String title,
    String? description,
    int timeLimitMinutes = 30,
    bool publishNow = false,
    List<Map<String, dynamic>>? questions,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/education/quizzes',
        data: {
          'academicClassId': classId,
          'subjectId': subjectId,
          'academicYearId': academicYearId,
          'title': title,
          'description': description,
          'timeLimitMinutes': timeLimitMinutes,
          'publishNow': publishNow,
          'questions': questions ?? [],
        },
      );
      return (response.data as Map<String, dynamic>)['quizId'] as int;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> publishQuiz(int quizId) async {
    try {
      await _apiClient.dio.post('/api/education/quizzes/$quizId/publish');
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> addQuestion({
    required int quizId,
    required String questionText,
    required int points,
    required QuizQuestionType questionType,
    bool? trueFalseCorrect,
    List<Map<String, dynamic>>? answers,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/education/quizzes/$quizId/questions',
        data: {
          'questionText': questionText,
          'points': points,
          'questionType': questionType.apiValue,
          if (trueFalseCorrect != null) 'trueFalseCorrect': trueFalseCorrect,
          'answers': answers ?? [],
        },
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> deleteQuestion(int quizId, int questionId) async {
    try {
      await _apiClient.dio.delete(
        '/api/education/quizzes/$quizId/questions/$questionId',
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}

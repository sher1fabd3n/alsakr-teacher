import '../../../services/api_client.dart';
import '../../../models/student_models.dart';
import '../models/parent_family_models.dart';

class ParentFamilyService {
  ParentFamilyService(this._apiClient);

  final ApiClient _apiClient;

  Future<FamilyDashboardSummary> getFamilyDashboard() async {
    final response = await _apiClient.dio.get('/api/parent/children');
    return FamilyDashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FamilyDashboardSummary> getFamilyOverview() async {
    final response = await _apiClient.dio.get('/api/parent/family/summary');
    final children = (response.data['children'] as List<dynamic>? ?? [])
        .map((e) => ChildDashboardSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    return FamilyDashboardSummary(
      totalChildren: children.length,
      children: children,
    );
  }

  Future<FamilyTransportationSummary> getFamilyTransportation() async {
    final response = await _apiClient.dio.get('/api/parent/family/transportation');
    return FamilyTransportationSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ChildDashboardSummary> switchActiveChild(int studentId) async {
    final response = await _apiClient.dio.post(
      '/api/parent/active-child',
      data: {'studentId': studentId},
    );
    final data = response.data as Map<String, dynamic>;
    return ChildDashboardSummary.fromJson(data['child'] as Map<String, dynamic>);
  }

  Future<({int? activeStudentId, ChildDashboardSummary? child})> getActiveChild() async {
    final response = await _apiClient.dio.get('/api/parent/active-child');
    final data = response.data as Map<String, dynamic>;
    final childJson = data['child'];
    return (
      activeStudentId: data['activeStudentId'] as int?,
      child: childJson != null
          ? ChildDashboardSummary.fromJson(childJson as Map<String, dynamic>)
          : null,
    );
  }

  Future<ChildDashboardSummary> getChildSummary(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/summary');
    return ChildDashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentResultsResponse> getChildResults(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/results');
    return StudentResultsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentFeesResponse> getChildFees(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/fees');
    return StudentFeesResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ParentHomeworkItem>> getChildHomework(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/homework');
    final list = response.data as List<dynamic>;
    return list.map((e) => ParentHomeworkItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ParentAttendanceSummary> getChildAttendance(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/attendance');
    return ParentAttendanceSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ParentChildNotification>> getNotifications({int take = 50}) async {
    final response = await _apiClient.dio.get('/api/parent/notifications', queryParameters: {'take': take});
    final list = response.data as List<dynamic>;
    return list.map((e) => ParentChildNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refreshChildData(int studentId) async {
    await Future.wait([
      getChildSummary(studentId),
      getChildResults(studentId),
      getChildFees(studentId),
      getChildHomework(studentId),
      getChildAttendance(studentId),
    ], eagerError: false);
  }
}

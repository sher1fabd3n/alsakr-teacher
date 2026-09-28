import 'package:flutter/foundation.dart';

import 'services/student_services.dart';

enum AppRole { student, parent, teacher, admin, driver }

class AppState extends ChangeNotifier {
  AppState(this._authService);

  final AuthService _authService;
  bool _bootstrapping = true;
  AppRole _role = AppRole.student;
  String? _mobileRole;
  bool _teacherCanClasses = true;
  bool _teacherCanStudents = true;
  bool _teacherCanAttendance = true;
  bool _teacherCanQuizzes = true;
  bool _teacherCanChat = true;
  bool _teacherCanReports = true;
  bool _teacherCanParentReports = false;

  bool get bootstrapping => _bootstrapping;
  bool get isLoggedIn =>
      _authService.currentStudent != null ||
      _authService.currentParent != null ||
      _mobileRole != null;
  AppRole get role => _role;
  bool get isAdmin => _mobileRole == 'Admin';
  bool get isDriver => _mobileRole == 'Driver';
  bool get isParent => _mobileRole == 'Parent';
  String get communicationRole => _mobileRole ?? 'Student';
  bool get teacherCanClasses => _teacherCanClasses;
  bool get teacherCanStudents => _teacherCanStudents;
  bool get teacherCanAttendance => _teacherCanAttendance;
  bool get teacherCanQuizzes => _teacherCanQuizzes;
  bool get teacherCanChat => _teacherCanChat;
  bool get teacherCanReports => _teacherCanReports;
  bool get teacherCanParentReports => _teacherCanParentReports;

  Future<void> bootstrap() async {
    await _authService.restoreSession();
    _mobileRole = await _authService.readMobileRole();
    _bootstrapping = false;
    notifyListeners();
  }

  void setRole(AppRole role) {
    _role = role;
    notifyListeners();
  }

  void setMobileRole(String role) {
    _mobileRole = role;
    notifyListeners();
  }

  void setTeacherPermissions({
    bool? classes,
    bool? students,
    bool? attendance,
    bool? quizzes,
    bool? chat,
    bool? reports,
    bool? parentReports,
    Map<String, bool>? map,
  }) {
    _teacherCanClasses = map?['classes'] ?? classes ?? _teacherCanClasses;
    _teacherCanStudents = map?['students'] ?? students ?? _teacherCanStudents;
    _teacherCanAttendance = map?['attendance'] ?? attendance ?? _teacherCanAttendance;
    _teacherCanQuizzes = map?['quizzes'] ?? quizzes ?? _teacherCanQuizzes;
    _teacherCanChat = map?['chat'] ?? chat ?? _teacherCanChat;
    _teacherCanReports = map?['reports'] ?? reports ?? _teacherCanReports;
    _teacherCanParentReports = map?['parentReports'] ?? parentReports ?? _teacherCanParentReports;
    notifyListeners();
  }

  void applyTeacherAuthData(Map<String, dynamic> data) {
    final raw = data['profile'];
    final source = raw is Map ? Map<String, dynamic>.from(raw) : data;
    final perms = source['permissions'];
    setTeacherPermissions(
      map: perms is Map ? perms.map((k, v) => MapEntry(k.toString(), v == true)) : null,
      classes: source['canClasses'] as bool?,
      students: source['canStudents'] as bool?,
      attendance: source['canAttendance'] as bool?,
      quizzes: source['canQuizzes'] as bool?,
      chat: source['canChat'] as bool?,
      reports: source['canReports'] as bool?,
      parentReports: source['canParentReports'] as bool?,
    );
  }

  void clearSession() {
    _mobileRole = null;
    _teacherCanClasses = true;
    _teacherCanStudents = true;
    _teacherCanAttendance = true;
    _teacherCanQuizzes = true;
    _teacherCanChat = true;
    _teacherCanReports = true;
    _teacherCanParentReports = false;
    notifyListeners();
  }

  void refresh() => notifyListeners();
}

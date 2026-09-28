import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../models/education_models.dart';
import '../services/education_service.dart';
import 'attendance_screen.dart';
import 'attendance_report_screen.dart';
import 'quiz_management_screen.dart';
import 'teacher_exam_grades_screen.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  const TeacherClassDetailScreen({
    super.key,
    required this.classItem,
    this.academicYearId,
    this.mySubjects = const [],
  });

  final AcademicClass classItem;
  final int? academicYearId;
  final List<TeacherAssignment> mySubjects;

  @override
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Student> _students = [];
  bool _loading = true;
  String? _error;
  bool _showStudents = true;
  bool _showAttendance = true;
  bool _showQuizzes = true;
  bool _showReports = true;

  int get _tabCount => (_showStudents ? 1 : 1) + (_showAttendance ? 1 : 0) + (_showQuizzes ? 1 : 0);

  @override
  void initState() {
    super.initState();
    final perms = context.read<AppState>();
    _showStudents = perms.teacherCanStudents;
    _showAttendance = perms.teacherCanAttendance;
    _showQuizzes = perms.teacherCanQuizzes;
    _showReports = perms.teacherCanReports;
    _tabController = TabController(length: _tabCount, vsync: this);
    if (_showStudents) {
      _loadStudents();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = context.read<EducationService>();
      final students = await service.getClassStudents(
        widget.classItem.id,
        academicYearId: widget.academicYearId,
      );
      if (!mounted) return;
      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classItem = widget.classItem;

    return Scaffold(
      appBar: AppBar(
        title: Text(classItem.displayName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.people), text: 'الطلاب'),
            if (_showAttendance) const Tab(icon: Icon(Icons.how_to_reg), text: 'الحضور'),
            if (_showQuizzes) const Tab(icon: Icon(Icons.quiz), text: 'الكويزات'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'رصد الدرجات',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeacherExamGradesScreen(
                    initialClassId: widget.classItem.id,
                    initialSubjectId: widget.mySubjects.isEmpty ? null : widget.mySubjects.first.subjectId,
                  ),
                ),
              );
            },
          ),
          if (_showReports)
            IconButton(
              tooltip: 'تقرير الغياب',
              icon: const Icon(Icons.assessment_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AttendanceReportScreen(
                      classItem: classItem,
                      academicYearId: widget.academicYearId,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStudents,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentsTab(),
                    if (_showAttendance)
                      AttendanceScreen(
                        classItem: classItem,
                        academicYearId: widget.academicYearId ?? widget.classItem.academicYearId,
                        mySubjects: widget.mySubjects,
                      ),
                    if (_showQuizzes)
                      QuizManagementScreen(
                        classItem: classItem,
                        academicYearId: widget.academicYearId ?? widget.classItem.academicYearId,
                        mySubjects: widget.mySubjects,
                      ),
                  ],
                ),
    );
  }

  Widget _buildStudentsTab() {
    final classItem = widget.classItem;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classItem.educationLevel?.nameAr ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('عدد الطلاب: ${classItem.currentCount}/${classItem.maxCapacity}'),
                if (widget.mySubjects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('موادي في هذا الفصل:'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.mySubjects
                        .map((a) => Chip(label: Text(a.subjectNameAr)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_showStudents)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا توجد صلاحية لعرض قائمة الطلاب.'),
            ),
          )
        else ...[
        Text(
          'قائمة الطلاب (${_students.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_students.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا يوجد طلاب مسجلون في هذا الفصل'),
            ),
          )
        else
          ..._students.map(
            (student) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(student.rollNo.toString()),
                ),
                title: Text(student.name),
                subtitle: Text(
                  [
                    if (student.fatherPhone != null) 'ولي الأمر: ${student.fatherPhone}',
                  ].join('\n'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

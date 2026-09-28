import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/education_models.dart';
import '../services/education_service.dart';
import 'teacher_classes_screen.dart';
import 'teacher_class_detail_screen.dart';
import 'teacher_exam_grades_screen.dart';
import '../../../app_state.dart';
import '../../communication/screens/teacher_reports_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<TeacherAssignment> _assignments = [];
  int? _academicYearId;
  String _academicYearName = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = context.read<EducationService>();
      final profile = await service.getMyProfile();
      final assignments = profile.assignments;

      if (!mounted) return;
      context.read<AppState>().setTeacherPermissions(
            classes: profile.canClasses,
            students: profile.canStudents,
            attendance: profile.canAttendance,
            quizzes: profile.canQuizzes,
            chat: profile.canChat,
            reports: profile.canReports,
            parentReports: profile.canParentReports,
          );
      setState(() {
        _assignments = assignments;
        _academicYearId = profile.activeAcademicYearId;
        _academicYearName = profile.activeAcademicYearName;
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

  Map<int, List<TeacherAssignment>> get _groupedByClass {
    final map = <int, List<TeacherAssignment>>{};
    for (final a in _assignments) {
      map.putIfAbsent(a.academicClassId, () => []).add(a);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المعلم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (!context.watch<AppState>().teacherCanClasses) {
      return const Center(child: Text('لا توجد صلاحية لعرض الفصول في هذا الحساب.'));
    }

    final grouped = _groupedByClass;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_academicYearName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'السنة الدراسية: $_academicYearName',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          _buildStatsCards(grouped.length),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherExamGradesScreen()));
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('رصد درجات الامتحانات'),
            ),
          ),
          if (context.watch<AppState>().teacherCanParentReports) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherReportsScreen()),
                  );
                },
                icon: const Icon(Icons.description_rounded),
                label: const Text('تقارير أولياء الأمور'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildClassesSection(grouped),
        ],
      ),
    );
  }

  Widget _buildStatsCards(int classCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'فصولي',
            classCount.toString(),
            Icons.class_,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'التعيينات',
            _assignments.length.toString(),
            Icons.menu_book,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesSection(Map<int, List<TeacherAssignment>> grouped) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'فصولي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherClassesScreen()),
                );
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (grouped.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا توجد فصول مسندة إليك'),
            ),
          )
        else
          ...grouped.entries.take(3).map((entry) {
            final first = entry.value.first;
            return _buildClassCard(first, entry.value);
          }),
      ],
    );
  }

  Widget _buildClassCard(TeacherAssignment assignment, List<TeacherAssignment> subjects) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            assignment.classDisplayName.split('-').last,
            style: TextStyle(color: Colors.blue.shade700),
          ),
        ),
        title: Text(assignment.classDisplayName),
        subtitle: Text(
          '${assignment.levelNameAr} - ${subjects.map((s) => s.subjectNameAr).join('، ')}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openClassDetail(assignment, subjects),
      ),
    );
  }

  void _openClassDetail(TeacherAssignment assignment, List<TeacherAssignment> subjects) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherClassDetailScreen(
          classItem: AcademicClass(
            id: assignment.academicClassId,
            educationLevelId: 0,
            academicYearId: assignment.academicYearId,
            classCode: assignment.classDisplayName,
            displayName: assignment.classDisplayName,
            maxCapacity: 0,
            currentCount: 0,
            isActive: true,
            educationLevel: EducationLevel(
              id: 0,
              educationStageId: 0,
              nameAr: assignment.levelNameAr,
              nameEn: assignment.levelNameAr,
              code: '',
              gradeNumber: 0,
              displayOrder: 0,
              isActive: true,
            ),
          ),
          academicYearId: _academicYearId,
          mySubjects: subjects,
        ),
      ),
    );
  }
}

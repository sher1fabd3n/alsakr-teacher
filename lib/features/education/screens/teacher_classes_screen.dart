import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../models/education_models.dart';
import '../services/education_service.dart';
import 'teacher_class_detail_screen.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  List<TeacherAssignment> _assignments = [];
  int? _academicYearId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
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
    final grouped = _groupedByClass;

    return Scaffold(
      appBar: AppBar(
        title: const Text('فصولي'),
      ),
      body: _buildBody(grouped),
    );
  }

  Widget _buildBody(Map<int, List<TeacherAssignment>> grouped) {
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
              onPressed: _loadClasses,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (grouped.isEmpty) {
      return const Center(child: Text('لا توجد فصول مسندة إليك'));
    }

    return ListView.builder(
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        final first = entry.value.first;
        final subjects = entry.value;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(first.classDisplayName),
            subtitle: Text(
              '${first.levelNameAr} - ${subjects.map((s) => s.subjectNameAr).join('، ')}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherClassDetailScreen(
                    classItem: AcademicClass(
                      id: first.academicClassId,
                      educationLevelId: 0,
                      academicYearId: first.academicYearId,
                      classCode: first.classDisplayName,
                      displayName: first.classDisplayName,
                      maxCapacity: 0,
                      currentCount: 0,
                      isActive: true,
                      educationLevel: EducationLevel(
                        id: 0,
                        educationStageId: 0,
                        nameAr: first.levelNameAr,
                        nameEn: first.levelNameAr,
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
            },
          ),
        );
      },
    );
  }
}

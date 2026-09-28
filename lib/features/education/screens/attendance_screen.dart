import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/education_models.dart';
import '../services/education_content_service.dart';
import '../services/education_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.classItem,
    required this.academicYearId,
    required this.mySubjects,
  });

  final AcademicClass classItem;
  final int academicYearId;
  final List<TeacherAssignment> mySubjects;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Student> _students = [];
  Map<int, String> _attendanceMap = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  int get _effectiveAcademicYearId =>
      widget.academicYearId > 0 ? widget.academicYearId : widget.classItem.academicYearId;

  static int _attendanceStatusValue(String status) {
    switch (status) {
      case 'Absent':
        return 1;
      case 'Late':
        return 2;
      case 'Excused':
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final eduService = context.read<EducationService>();
      final students = await eduService.getClassStudents(
        widget.classItem.id,
        academicYearId: _effectiveAcademicYearId,
      );
      final attendanceService = context.read<EducationContentService>();

      final existing = await attendanceService.getClassAttendance(
        widget.classItem.id,
        date: _selectedDate,
      );

      final map = <int, String>{};
      for (final s in students) {
        final record = existing.where((a) => a.studentId == s.id).toList();
        map[s.id] = record.isNotEmpty ? record.first.status : 'Present';
      }

      if (!mounted) return;
      setState(() {
        _students = students;
        _attendanceMap = map;
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

  Future<void> _saveAttendance() async {
    if (_effectiveAcademicYearId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ: السنة الدراسية غير محددة')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final service = context.read<EducationContentService>();
      final items = _attendanceMap.entries
          .map((e) => {
                'studentId': e.key,
                'status': _attendanceStatusValue(e.value),
              })
          .toList();

      await service.saveAttendance(
        classId: widget.classItem.id,
        academicYearId: _effectiveAcademicYearId,
        date: _selectedDate,
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحضور والغياب بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حضور - ${widget.classItem.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadStudents();
              }
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
              : _buildAttendanceList(),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAttendance,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ الحضور'),
                ),
              ),
            ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final currentStatus = _attendanceMap[student.id] ?? 'Present';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(student.rollNo.toString()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        student.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Present', label: Text('حاضر')),
                    ButtonSegment(value: 'Absent', label: Text('غائب')),
                    ButtonSegment(value: 'Late', label: Text('متأخر')),
                    ButtonSegment(value: 'Excused', label: Text('بعذر')),
                  ],
                  selected: {currentStatus},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _attendanceMap[student.id] = selected.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: WidgetStateProperty.all(
                      Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

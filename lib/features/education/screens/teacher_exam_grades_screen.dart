import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../services/education_service.dart';

class TeacherExamGradesScreen extends StatefulWidget {
  const TeacherExamGradesScreen({super.key, this.initialClassId, this.initialSubjectId});

  final int? initialClassId;
  final int? initialSubjectId;

  @override
  State<TeacherExamGradesScreen> createState() => _TeacherExamGradesScreenState();
}

class _TeacherExamGradesScreenState extends State<TeacherExamGradesScreen> {
  List<Map<String, dynamic>> _exams = const [];
  List<Map<String, dynamic>> _targets = const [];
  Map<String, dynamic>? _sheet;
  int? _examId;
  int? _classId;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _scores = <int, TextEditingController>{};
  final _yearWorks = <int, TextEditingController>{};
  bool _hideNames = false;

  @override
  void initState() {
    super.initState();
    _classId = widget.initialClassId;
    _load();
  }

  @override
  void dispose() {
    for (final c in _scores.values) {
      c.dispose();
    }
    for (final c in _yearWorks.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EducationService>();
      final exams = await service.listControlExams();
      final targets = await service.listControlTargets();
      if (!mounted) return;
      var filtered = exams;
      if (widget.initialSubjectId != null) {
        filtered = exams.where((e) => (e['subjectId'] as num?)?.toInt() == widget.initialSubjectId).toList();
      }
      setState(() {
        _exams = filtered;
        _targets = targets;
        _examId ??= filtered.where((e) => e['isOpen'] == true).map((e) => (e['id'] as num?)?.toInt()).firstWhere((id) => id != null, orElse: () => filtered.isEmpty ? null : (filtered.first['id'] as num?)?.toInt());
        _loading = false;
      });
      if (_examId != null && _classId != null) await _loadSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _classesForExam {
    final exam = _exams.cast<Map<String, dynamic>?>().firstWhere(
          (e) => (e?['id'] as num?)?.toInt() == _examId,
          orElse: () => null,
        );
    final subjectId = (exam?['subjectId'] as num?)?.toInt();
    return _targets.where((t) => subjectId == null || (t['subjectId'] as num?)?.toInt() == subjectId).toList();
  }

  Future<void> _loadSheet() async {
    if (_examId == null || _classId == null) return;
    setState(() => _loading = true);
    try {
      final sheet = await context.read<EducationService>().getControlSheet(examId: _examId!, classId: _classId!);
      if (!mounted) return;
      for (final c in _scores.values) {
        c.dispose();
      }
      for (final c in _yearWorks.values) {
        c.dispose();
      }
      _scores.clear();
      _yearWorks.clear();
      final rows = ((sheet['rows'] as List?) ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e));
      for (final row in rows) {
        final id = (row['studentId'] as num).toInt();
        _scores[id] = TextEditingController(text: row['score']?.toString() ?? '');
        _yearWorks[id] = TextEditingController(text: row['yearWorkScore']?.toString() ?? '');
      }
      setState(() {
        _sheet = sheet;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  num? _parseScore(String? raw) {
    final text = (raw ?? '').trim().replaceAll(',', '.').replaceAll('٫', '.').replaceAll('،', '.');
    if (text.isEmpty) return null;
    return num.tryParse(text);
  }

  Future<void> _save() async {
    if (_examId == null || _classId == null || _sheet == null) return;
    setState(() => _saving = true);
    try {
      final items = _scores.entries
          .map((e) => {
                'studentId': e.key,
                'score': _parseScore(e.value.text),
                'yearWorkScore': _parseScore(_yearWorks[e.key]?.text),
              })
          .toList();
      final msg = await context.read<EducationService>().saveControlGrades(
            examId: _examId!,
            classId: _classId!,
            items: items,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _loadSheet();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رصد الامتحانات'),
        actions: [
          IconButton(
            tooltip: _hideNames ? 'إظهار الأسماء' : 'أكواد الشفافية فقط',
            onPressed: () => setState(() => _hideNames = !_hideNames),
            icon: Icon(_hideNames ? Icons.visibility_rounded : Icons.visibility_off_rounded),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading && _sheet == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _sheet == null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _examId,
                        decoration: const InputDecoration(labelText: 'الامتحان'),
                        items: _exams
                            .map((e) => DropdownMenuItem(
                                  value: (e['id'] as num).toInt(),
                                  child: Text('${e['name']} — ${e['isOpen'] == true ? 'مفتوح' : 'مغلق'}'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _examId = v;
                            _sheet = null;
                          });
                          if (_classId != null) _loadSheet();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _classId,
                        decoration: const InputDecoration(labelText: 'الفصل'),
                        items: _classesForExam
                            .map((e) => DropdownMenuItem(
                                  value: (e['academicClassId'] as num).toInt(),
                                  child: Text('${e['className']} — ${e['subjectName']}'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _classId = v);
                          _loadSheet();
                        },
                      ),
                      if (_sheet != null) ...[
                        const SizedBox(height: 16),
                        Text(_sheet!['statusName']?.toString() ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (_loading) const LinearProgressIndicator(),
                        for (final row in ((_sheet!['rows'] as List?) ?? []).whereType<Map>())
                          _gradeCard(Map<String, dynamic>.from(row)),
                        const SizedBox(height: 16),
                        if (_sheet!['canEdit'] == true)
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: const Text('حفظ'),
                          ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _gradeCard(Map<String, dynamic> row) {
    final id = (row['studentId'] as num).toInt();
    final showYear = _sheet?['showYearWork'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _hideNames ? (row['transparencyCode']?.toString() ?? 'بدون كود') : '${row['name']} • ${row['rollNo']}',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
            ),
            if (!_hideNames && (row['transparencyCode']?.toString() ?? '').isNotEmpty)
              Text('كود الشفافية: ${row['transparencyCode']}', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _scores[id],
              enabled: _sheet?['canEdit'] == true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'الدرجة / ${row['maxScore']}'),
            ),
            if (showYear) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _yearWorks[id],
                enabled: _sheet?['canEdit'] == true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'أعمال السنة / ${row['yearWorkMax']}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

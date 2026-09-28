import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/education_content_models.dart';
import '../models/education_models.dart';
import '../services/education_content_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({
    super.key,
    required this.classItem,
    this.academicYearId,
  });

  final AcademicClass classItem;
  final int? academicYearId;

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  AttendanceReport? _report;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await context.read<EducationContentService>().getAttendanceReport(
            widget.classItem.id,
            year: _month.year,
            month: _month.month,
          );
      if (!mounted) return;
      setState(() {
        _report = report;
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

  Future<void> _export() async {
    try {
      final bytes = await context.read<EducationContentService>().downloadAttendanceReport(
            classId: widget.classItem.id,
            year: _month.year,
            month: _month.month,
          );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: 'غياب-${widget.classItem.displayName}-${_month.year}-${_month.month.toString().padLeft(2, '0')}.xlsx',
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          text: 'تقرير الغياب',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير غياب ${widget.classItem.displayName}'),
        actions: [
          IconButton(
            onPressed: _report == null ? null : _export,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'تصدير',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(
                'الشهر: ${_month.year} / ${_month.month.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _month,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _month = DateTime(picked.year, picked.month));
                  _load();
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
            )
          else if (_report != null) ...[
            Text(
              '${_report!.className} — ${_report!.monthNameAr} ${_report!.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'أيام التسجيل: ${_report!.recordedDays} | الطلاب: ${_report!.totalStudents}',
            ),
            const SizedBox(height: 12),
            if (_report!.studentStats.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد بيانات غياب لهذا الشهر.'),
                ),
              )
            else
              ..._report!.studentStats.map(
                (s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${s.rollNo}')),
                    title: Text(s.name),
                    subtitle: Text(
                      'غائب ${s.absent} يوم • حاضر ${s.present} • متأخر ${s.late}'
                      '${s.absentDates.isEmpty ? '' : '\n${s.absentDates.join('، ')}'}',
                    ),
                    trailing: Text(
                      '${s.absent}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: s.absent > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

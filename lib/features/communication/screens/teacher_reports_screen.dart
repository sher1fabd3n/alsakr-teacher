import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../education/services/education_service.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<EducationService>().getMyParentReports();
    setState(() {});
  }

  Future<void> _compose() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _TeacherReportComposeScreen()),
    );
    if (created == true && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقارير أولياء الأمور')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إرسال تقرير'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                      const SizedBox(height: 16),
                      Text(
                        '${snapshot.error}'.replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'لا توجد تقارير مرسلة بعد.\nاضغط «إرسال تقرير» لإرسال تقرير لأولياء أمور فصولك.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: AppColors.textSecondary, height: 1.6),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final body = item['body']?.toString() ?? '';
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['title'] ?? ''}',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            item['targetLabel'],
                            item['createdByName'],
                          ].whereType<Object>().map((e) => e.toString()).where((e) => e.trim().isNotEmpty).join(' • '),
                          style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(body, style: GoogleFonts.cairo(height: 1.55)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TeacherReportComposeScreen extends StatefulWidget {
  const _TeacherReportComposeScreen();

  @override
  State<_TeacherReportComposeScreen> createState() => _TeacherReportComposeScreenState();
}

class _TeacherReportComposeScreenState extends State<_TeacherReportComposeScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _targetType = 'Class';
  int? _classId;
  int? _levelId;
  int? _stageId;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _stages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  int? _idOf(Map<String, dynamic> item) => (item['id'] as num?)?.toInt();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<EducationService>().getMyParentReportTargets();
      if (!mounted) return;
      final classes = ((data['classes'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final levels = ((data['levels'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final stages = ((data['stages'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _classes = classes;
        _levels = levels;
        _stages = stages;
        _classId = classes.isEmpty ? null : _idOf(classes.first);
        _levelId = levels.isEmpty ? null : _idOf(levels.first);
        _stageId = stages.isEmpty ? null : _idOf(stages.first);
        if (classes.isNotEmpty) {
          _targetType = 'Class';
        } else if (levels.isNotEmpty) {
          _targetType = 'Grade';
        } else if (stages.isNotEmpty) {
          _targetType = 'Stage';
        }
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

  bool get _hasTargets => _classes.isNotEmpty || _levels.isNotEmpty || _stages.isNotEmpty;

  bool get _canSend {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty || !_hasTargets) {
      return false;
    }
    return switch (_targetType) {
      'Class' => _classId != null,
      'Grade' => _levelId != null,
      'Stage' => _stageId != null,
      _ => false,
    };
  }

  Future<void> _save() async {
    if (!_canSend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasTargets ? 'العنوان والنص واختيار الهدف مطلوبان.' : 'لا توجد فصول معينة لإرسال التقرير.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final msg = await context.read<EducationService>().createParentReport(
            title: _title.text.trim(),
            body: _body.text.trim(),
            targetType: _targetType,
            academicClassId: _targetType == 'Class' ? _classId : null,
            educationLevelId: _targetType == 'Grade' ? _levelId : null,
            educationStageId: _targetType == 'Stage' ? _stageId : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير جديد')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.cairo()),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!_hasTargets)
                        AppCard(
                          child: Text(
                            'لا توجد فصول معينة لحسابك. بعد تفعيل صلاحية التقارير يجب أن يُعيَّن للمعلم فصل أو صف من الإدارة حتى يتمكن من الإرسال.',
                            style: GoogleFonts.cairo(height: 1.6),
                          ),
                        )
                      else ...[
                        TextField(
                          controller: _title,
                          decoration: const InputDecoration(labelText: 'العنوان'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _body,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: 'نص التقرير'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Text('إرسال إلى', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (_classes.isNotEmpty)
                              ChoiceChip(
                                label: const Text('فصل'),
                                selected: _targetType == 'Class',
                                onSelected: (_) => setState(() => _targetType = 'Class'),
                              ),
                            if (_levels.isNotEmpty)
                              ChoiceChip(
                                label: const Text('صف'),
                                selected: _targetType == 'Grade',
                                onSelected: (_) => setState(() => _targetType = 'Grade'),
                              ),
                            if (_stages.isNotEmpty)
                              ChoiceChip(
                                label: const Text('مرحلة'),
                                selected: _targetType == 'Stage',
                                onSelected: (_) => setState(() => _targetType = 'Stage'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_targetType == 'Class' && _classes.isNotEmpty)
                          DropdownButtonFormField<int>(
                            initialValue: _classId,
                            decoration: const InputDecoration(labelText: 'الفصل المعين لك'),
                            items: [
                              for (final item in _classes)
                                DropdownMenuItem(
                                  value: _idOf(item),
                                  child: Text('${item['displayName'] ?? ''}'),
                                ),
                            ],
                            onChanged: (value) => setState(() => _classId = value),
                          ),
                        if (_targetType == 'Grade' && _levels.isNotEmpty)
                          DropdownButtonFormField<int>(
                            initialValue: _levelId,
                            decoration: const InputDecoration(labelText: 'الصف المعين لك'),
                            items: [
                              for (final item in _levels)
                                DropdownMenuItem(
                                  value: _idOf(item),
                                  child: Text('${item['nameAr'] ?? ''}'),
                                ),
                            ],
                            onChanged: (value) => setState(() => _levelId = value),
                          ),
                        if (_targetType == 'Stage' && _stages.isNotEmpty)
                          DropdownButtonFormField<int>(
                            initialValue: _stageId,
                            decoration: const InputDecoration(labelText: 'المرحلة المعينة لك'),
                            items: [
                              for (final item in _stages)
                                DropdownMenuItem(
                                  value: _idOf(item),
                                  child: Text('${item['nameAr'] ?? ''}'),
                                ),
                            ],
                            onChanged: (value) => setState(() => _stageId = value),
                          ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _saving || !_canSend ? null : _save,
                          icon: const Icon(Icons.send_rounded),
                          label: Text(_saving ? 'جاري الإرسال...' : 'إرسال لولي الأمر'),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../models/communication_models.dart';
import '../services/communication_service.dart';
import '../../education/models/education_models.dart';
import '../../education/services/education_service.dart';
import 'conversation_screen.dart';

class StartConversationScreen extends StatefulWidget {
  const StartConversationScreen({super.key});

  @override
  State<StartConversationScreen> createState() => _StartConversationScreenState();
}

class _StartConversationScreenState extends State<StartConversationScreen> {
  int _step = 0;
  List<AcademicClass> _classes = [];
  List<Student> _students = [];
  List<ParentOfStudentItem> _parents = [];
  AcademicClass? _selectedClass;
  Student? _selectedStudent;
  int? _activeAcademicYearId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  EducationService get _eduService => context.read<EducationService>();
  CommunicationService get _chatService => context.read<CommunicationService>();

  Future<void> _loadClasses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await _eduService.getMyProfile();
      _activeAcademicYearId = profile.activeAcademicYearId > 0
          ? profile.activeAcademicYearId
          : null;
      _classes = await _eduService.getMyClasses(academicYearId: _activeAcademicYearId);
      setState(() { _loading = false; });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _loading = false; _error = msg; });
    }
  }

  Future<void> _loadStudents(AcademicClass cls) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedClass = cls;
      _step = 1;
    });
    try {
      _students = await _eduService.getClassStudents(
        cls.id,
        academicYearId: _activeAcademicYearId,
      );
      setState(() { _loading = false; });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _loading = false; _error = msg; });
    }
  }

  Future<void> _loadParents(Student student) async {
    setState(() { _loading = true; _error = null; _selectedStudent = student; _step = 2; });
    try {
      _parents = await _chatService.getParentsOfStudent(student.id);
      setState(() { _loading = false; });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _loading = false; _error = msg; });
    }
  }

  Future<void> _startChat(ParentOfStudentItem parent) async {
    if (_selectedStudent == null) return;
    try {
      final conversationId = await _chatService.startConversation(
        parentAccountId: parent.parentAccountId,
        studentId: _selectedStudent!.id,
      );
      if (!mounted) return;
      final conversations = await _chatService.getConversations();
      final conversation = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => ConversationItem(
          id: conversationId,
          studentId: _selectedStudent!.id,
          studentName: _selectedStudent!.name,
          studentGrade: _selectedStudent!.grade ?? '',
          teacherName: '',
          parentName: parent.fullName,
          unreadCount: 0,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conversation)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $msg'), backgroundColor: AppColors.danger),
      );
    }
  }

  String get _title => switch (_step) {
    0 => 'اختر الفصل',
    1 => 'اختر الطالب',
    2 => 'اختر ولي الأمر',
    _ => '',
  };

  void _retry() {
    switch (_step) {
      case 0: _loadClasses(); break;
      case 1:
        if (_selectedClass != null) _loadStudents(_selectedClass!);
        break;
      case 2:
        if (_selectedStudent != null) _loadParents(_selectedStudent!);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _retry, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_step == 0 && _classes.isEmpty) {
      return const Center(child: Text('لا توجد فصول مخصصة لك'));
    }
    if (_step == 1 && _students.isEmpty) {
      return const Center(child: Text('لا يوجد طلاب في هذا الفصل'));
    }
    if (_step == 2 && _parents.isEmpty) {
      return const Center(child: Text('لا يوجد أولياء أمور مرتبطون بهذا الطالب'));
    }

    final items = _step == 0
        ? _classes
        : _step == 1
            ? _students
            : _parents;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: 40 * index),
          child: _buildItemTile(item),
        );
      },
    );
  }

  Widget _buildItemTile(dynamic item) {
    if (item is AcademicClass) {
      return AppCard(
        onTap: () => _loadStudents(item),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (item.educationLevel?.nameAr != null)
                    Text(
                      item.educationLevel!.nameAr,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      );
    }

    if (item is Student) {
      return AppCard(
        onTap: () => _loadParents(item),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
              child: Text(
                item.name.isNotEmpty ? item.name[0] : 'ط',
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    item.grade ?? '',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      );
    }

    if (item is ParentOfStudentItem) {
      return AppCard(
        onTap: () => _startChat(item),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

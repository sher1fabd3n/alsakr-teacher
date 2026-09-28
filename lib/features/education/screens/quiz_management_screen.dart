import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/education_content_models.dart';
import '../models/education_models.dart';
import '../services/education_content_service.dart';
import 'quiz_editor_screen.dart';

class QuizManagementScreen extends StatefulWidget {
  const QuizManagementScreen({
    super.key,
    required this.classItem,
    required this.academicYearId,
    required this.mySubjects,
  });

  final AcademicClass classItem;
  final int academicYearId;
  final List<TeacherAssignment> mySubjects;

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  List<QuizSummary> _quizzes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = context.read<EducationContentService>();
      final quizzes = await service.getMyQuizzes(classId: widget.classItem.id);
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('كويزات - ${widget.classItem.displayName}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateQuizDialog(),
        icon: const Icon(Icons.add),
        label: const Text('كويز جديد'),
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
                        onPressed: _loadQuizzes,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _quizzes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا توجد كويزات بعد'),
                          Text('اضغط + لإنشاء كويز جديد'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadQuizzes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = _quizzes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuizEditorScreen(
                                      quizId: quiz.id,
                                      className: widget.classItem.displayName,
                                    ),
                                  ),
                                ).then((_) => _loadQuizzes());
                              },
                              leading: CircleAvatar(
                                backgroundColor: quiz.status == 'Published'
                                    ? Colors.green
                                    : quiz.status == 'Draft'
                                        ? Colors.orange
                                        : Colors.grey,
                                child: const Icon(Icons.quiz, color: Colors.white),
                              ),
                              title: Text(quiz.title),
                              subtitle: Text(
                                '${quiz.subjectName} | ${quiz.questionCount} أسئلة | ${quiz.totalPoints} درجة',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    quiz.status == 'Published'
                                        ? 'منشور'
                                        : quiz.status == 'Draft'
                                            ? 'مسودة'
                                            : 'مغلق',
                                    style: TextStyle(
                                      color: quiz.status == 'Published'
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${quiz.attemptCount} محاولة',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showCreateQuizDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    int selectedSubjectId = widget.mySubjects.isNotEmpty
        ? widget.mySubjects.first.subjectId
        : 0;
    int timeLimit = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'كويز جديد',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'عنوان الكويز'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'المادة'),
                  items: widget.mySubjects
                      .map((a) => DropdownMenuItem(
                            value: a.subjectId,
                            child: Text(a.subjectNameAr),
                          ))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedSubjectId = v ?? 0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('وقت الكويز (دقيقة): '),
                    Expanded(
                      child: Slider(
                        value: timeLimit.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$timeLimit دقيقة',
                        onChanged: (v) => setModalState(() => timeLimit = v.round()),
                      ),
                    ),
                    Text('$timeLimit'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'بعد «التالي» ستُضاف 5 أسئلة على الأقل ثم يُحفظ الكويز',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('أدخل عنوان الكويز')),
                      );
                      return;
                    }
                    if (selectedSubjectId <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('اختر المادة')),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    final draft = NewQuizDraft(
                      classId: widget.classItem.id,
                      subjectId: selectedSubjectId,
                      academicYearId: widget.academicYearId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      timeLimitMinutes: timeLimit,
                    );

                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizEditorScreen(
                          className: widget.classItem.displayName,
                          newQuizDraft: draft,
                        ),
                      ),
                    );
                    _loadQuizzes();
                  },
                  child: const Text('التالي: إضافة الأسئلة'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

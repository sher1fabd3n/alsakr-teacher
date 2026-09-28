import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/education_content_models.dart';
import '../services/education_content_service.dart';

const int _minQuizQuestions = 5;

class QuizEditorScreen extends StatefulWidget {
  const QuizEditorScreen({
    super.key,
    this.quizId,
    required this.className,
    this.newQuizDraft,
  });

  final int? quizId;
  final String className;
  final NewQuizDraft? newQuizDraft;

  bool get isNew => quizId == null && newQuizDraft != null;

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  QuizDetail? _quiz;
  final List<DraftQuizQuestion> _draftQuestions = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isNew) {
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.quizId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EducationContentService>();
      final quiz = await service.getQuizDetail(widget.quizId!);
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
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

  int get _questionCount => widget.isNew ? _draftQuestions.length : (_quiz?.questions.length ?? 0);

  Future<void> _saveNewQuiz() async {
    final draft = widget.newQuizDraft!;
    if (_draftQuestions.length < _minQuizQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب إضافة $_minQuizQuestions أسئلة على الأقل')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final service = context.read<EducationContentService>();
      final quizId = await service.createQuiz(
        classId: draft.classId,
        subjectId: draft.subjectId,
        academicYearId: draft.academicYearId,
        title: draft.title,
        description: draft.description,
        timeLimitMinutes: draft.timeLimitMinutes,
        questions: _draftQuestions.map((q) => q.toApiPayload()).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, quizId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    if (_quiz == null || _quiz!.questions.length < _minQuizQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب إضافة $_minQuizQuestions أسئلة على الأقل قبل النشر')),
      );
      return;
    }
    try {
      await context.read<EducationContentService>().publishQuiz(widget.quizId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر الكويز بنجاح')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  void _showAddQuestionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddQuestionSheet(
        quizId: widget.isNew ? null : widget.quizId,
        onAdded: _load,
        onDraftAdded: widget.isNew
            ? (question) {
                setState(() => _draftQuestions.add(question));
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isNew ? widget.newQuizDraft!.title : (_quiz?.title ?? 'تحرير الكويز');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.isNew)
            TextButton.icon(
              onPressed: _saving || _draftQuestions.length < _minQuizQuestions ? null : _saveNewQuiz,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                'حفظ (${_draftQuestions.length}/$_minQuizQuestions)',
                style: const TextStyle(color: Colors.white),
              ),
            )
          else if (_quiz?.status == 'Draft')
            TextButton.icon(
              onPressed: _publish,
              icon: const Icon(Icons.publish, color: Colors.white),
              label: const Text('نشر', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      floatingActionButton: widget.isNew || _quiz?.status == 'Draft'
          ? FloatingActionButton.extended(
              onPressed: _showAddQuestionSheet,
              icon: const Icon(Icons.add),
              label: const Text('إضافة سؤال'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: widget.isNew ? () async {} : _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(
                                widget.isNew
                                    ? '${widget.className} • ${widget.newQuizDraft!.timeLimitMinutes} دقيقة'
                                    : '${widget.className} • ${_quiz!.totalPoints} درجة • ${_quiz!.timeLimitMinutes} دقيقة',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.isNew
                                    ? 'مسودة جديدة — أضف $_minQuizQuestions أسئلة على الأقل'
                                    : (_quiz!.status == 'Published' ? 'منشور' : 'مسودة'),
                                style: TextStyle(
                                  color: widget.isNew || _quiz!.status != 'Published'
                                      ? Colors.orange
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'الأسئلة ($_questionCount)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_questionCount == 0)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                widget.isNew
                                    ? 'أضف $_minQuizQuestions أسئلة على الأقل ثم اضغط «حفظ»'
                                    : 'لا توجد أسئلة — اضغط «إضافة سؤال»',
                              ),
                            ),
                          ),
                        )
                      else if (widget.isNew)
                        ..._draftQuestions.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final q = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(child: Text('$index')),
                              title: Text(q.questionText),
                              subtitle: Text('${q.typeLabel} • ${q.points} درجة'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => setState(() => _draftQuestions.removeAt(entry.key)),
                              ),
                            ),
                          );
                        })
                      else
                        ..._quiz!.questions.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final q = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(child: Text('$index')),
                              title: Text(q.questionText),
                              subtitle: Text(
                                '${q.typeLabel} • ${q.points} ${q.points == 1 ? 'درجة' : 'درجات'} • ${q.answers.length} إجابة',
                              ),
                              trailing: _quiz!.status == 'Draft'
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        try {
                                          await context
                                              .read<EducationContentService>()
                                              .deleteQuestion(widget.quizId!, q.id);
                                          _load();
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('خطأ: $e')),
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _AddQuestionSheet extends StatefulWidget {
  const _AddQuestionSheet({
    required this.onAdded,
    this.quizId,
    this.onDraftAdded,
  });

  final int? quizId;
  final VoidCallback onAdded;
  final void Function(DraftQuizQuestion question)? onDraftAdded;

  @override
  State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _textController = TextEditingController();
  QuizQuestionType _type = QuizQuestionType.multipleChoice;
  int _points = 1;
  bool _trueIsCorrect = true;
  bool _saving = false;

  final List<_AnswerRow> _answers = [
    _AnswerRow(text: '', isCorrect: true),
    _AnswerRow(text: '', isCorrect: false),
    _AnswerRow(text: '', isCorrect: false),
    _AnswerRow(text: '', isCorrect: false),
  ];

  @override
  void dispose() {
    _textController.dispose();
    for (final a in _answers) {
      a.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل نص السؤال')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.onDraftAdded != null) {
        widget.onDraftAdded!(DraftQuizQuestion(
          questionText: _textController.text.trim(),
          points: _points,
          questionType: _type,
          trueFalseCorrect: _trueIsCorrect,
          answers: _type == QuizQuestionType.multipleChoice
              ? _answers
                  .where((a) => a.controller.text.trim().isNotEmpty)
                  .map((a) => {
                        'answerText': a.controller.text.trim(),
                        'isCorrect': a.isCorrect,
                      })
                  .toList()
              : const [],
        ));
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      final service = context.read<EducationContentService>();
      await service.addQuestion(
        quizId: widget.quizId!,
        questionText: _textController.text.trim(),
        points: _points,
        questionType: _type,
        trueFalseCorrect: _trueIsCorrect,
        answers: _type == QuizQuestionType.multipleChoice
            ? _answers
                .where((a) => a.controller.text.trim().isNotEmpty)
                .map((a) => {
                      'answerText': a.controller.text.trim(),
                      'isCorrect': a.isCorrect,
                    })
                .toList()
            : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onAdded();
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إضافة سؤال', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<QuizQuestionType>(
              segments: const [
                ButtonSegment(
                  value: QuizQuestionType.multipleChoice,
                  label: Text('اختيار'),
                  icon: Icon(Icons.list_alt),
                ),
                ButtonSegment(
                  value: QuizQuestionType.trueFalse,
                  label: Text('صح/خطأ'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment(
                  value: QuizQuestionType.essay,
                  label: Text('مقالي'),
                  icon: Icon(Icons.edit_note),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'نص السؤال',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('الدرجة: '),
                DropdownButton<int>(
                  value: _points,
                  items: List.generate(10, (i) => i + 1)
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) => setState(() => _points = v ?? 1),
                ),
              ],
            ),
            if (_type == QuizQuestionType.trueFalse) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('الإجابة الصحيحة: صح'),
                subtitle: const Text('إذا أُوقف = الإجابة الصحيحة «خطأ»'),
                value: _trueIsCorrect,
                onChanged: (v) => setState(() => _trueIsCorrect = v),
              ),
            ],
            if (_type == QuizQuestionType.multipleChoice) ...[
              const SizedBox(height: 8),
              const Text('الإجابات (حدد الصحيحة):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._answers.asMap().entries.map((entry) {
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: row.isCorrect,
                        onChanged: (_) {
                          setState(() {
                            for (final a in _answers) {
                              a.isCorrect = false;
                            }
                            row.isCorrect = true;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: row.controller,
                          decoration: InputDecoration(
                            labelText: 'إجابة ${entry.key + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (_type == QuizQuestionType.essay)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'السؤال المقالي يُجيب عليه الطالب بنص حر — يُراجع لاحقاً.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ السؤال'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AnswerRow {
  _AnswerRow({required String text, required this.isCorrect})
      : controller = TextEditingController(text: text);

  final TextEditingController controller;
  bool isCorrect;
}

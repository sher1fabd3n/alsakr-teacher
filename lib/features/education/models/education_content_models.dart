enum QuizQuestionType {
  multipleChoice,
  trueFalse,
  essay;

  static QuizQuestionType fromApi(dynamic value) {
    if (value == null) return QuizQuestionType.multipleChoice;
    if (value is int) {
      switch (value) {
        case 1:
          return QuizQuestionType.trueFalse;
        case 2:
          return QuizQuestionType.essay;
        default:
          return QuizQuestionType.multipleChoice;
      }
    }
    switch (value.toString()) {
      case 'TrueFalse':
      case '1':
        return QuizQuestionType.trueFalse;
      case 'Essay':
      case '2':
        return QuizQuestionType.essay;
      default:
        return QuizQuestionType.multipleChoice;
    }
  }

  String get apiValue {
    switch (this) {
      case QuizQuestionType.trueFalse:
        return 'TrueFalse';
      case QuizQuestionType.essay:
        return 'Essay';
      case QuizQuestionType.multipleChoice:
        return 'MultipleChoice';
    }
  }
}

class NewQuizDraft {
  const NewQuizDraft({
    required this.classId,
    required this.subjectId,
    required this.academicYearId,
    required this.title,
    this.description,
    required this.timeLimitMinutes,
  });

  final int classId;
  final int subjectId;
  final int academicYearId;
  final String title;
  final String? description;
  final int timeLimitMinutes;
}

class DraftQuizQuestion {
  const DraftQuizQuestion({
    required this.questionText,
    required this.points,
    required this.questionType,
    this.trueFalseCorrect,
    this.answers = const [],
  });

  final String questionText;
  final int points;
  final QuizQuestionType questionType;
  final bool? trueFalseCorrect;
  final List<Map<String, dynamic>> answers;

  Map<String, dynamic> toApiPayload() => {
        'questionText': questionText,
        'points': points,
        'questionType': questionType.apiValue,
        if (trueFalseCorrect != null) 'trueFalseCorrect': trueFalseCorrect,
        'answers': answers,
      };

  String get typeLabel {
    switch (questionType) {
      case QuizQuestionType.trueFalse:
        return 'صح / خطأ';
      case QuizQuestionType.essay:
        return 'مقالي';
      case QuizQuestionType.multipleChoice:
        return 'اختيار من متعدد';
    }
  }
}

class AttendanceStudent {
  final int studentId;
  final String studentName;
  final int rollNo;
  final String status;
  final String? notes;
  final int? id;

  const AttendanceStudent({
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    this.status = 'Present',
    this.notes,
    this.id,
  });

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    return AttendanceStudent(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? '',
      rollNo: json['rollNo'] as int? ?? 0,
      status: json['status'] as String? ?? 'Present',
      notes: json['notes'] as String?,
      id: json['id'] as int?,
    );
  }
}

class QuizSummary {
  final int id;
  final String title;
  final String className;
  final String subjectName;
  final String status;
  final int totalPoints;
  final int timeLimitMinutes;
  final int questionCount;
  final int attemptCount;
  final DateTime createdAt;

  const QuizSummary({
    required this.id,
    required this.title,
    required this.className,
    required this.subjectName,
    required this.status,
    required this.totalPoints,
    required this.timeLimitMinutes,
    required this.questionCount,
    required this.attemptCount,
    required this.createdAt,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      className: json['classDisplayName'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      totalPoints: json['totalPoints'] as int? ?? 0,
      timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 30,
      questionCount: json['questionCount'] as int? ?? 0,
      attemptCount: json['attemptCount'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class QuizDetail {
  final int id;
  final String title;
  final String? description;
  final String status;
  final int totalPoints;
  final int timeLimitMinutes;
  final List<QuizQuestionDetail> questions;

  const QuizDetail({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.totalPoints,
    required this.timeLimitMinutes,
    required this.questions,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>? ?? [])
        .map((e) => QuizQuestionDetail.fromJson(e as Map<String, dynamic>))
        .toList();
    return QuizDetail(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'Draft',
      totalPoints: json['totalPoints'] as int? ?? 0,
      timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 30,
      questions: questions,
    );
  }
}

class QuizQuestionDetail {
  final int id;
  final String questionText;
  final int points;
  final QuizQuestionType questionType;
  final List<QuizAnswerDetail> answers;

  const QuizQuestionDetail({
    required this.id,
    required this.questionText,
    required this.points,
    required this.questionType,
    required this.answers,
  });

  String get typeLabel {
    switch (questionType) {
      case QuizQuestionType.trueFalse:
        return 'صح / خطأ';
      case QuizQuestionType.essay:
        return 'مقالي';
      case QuizQuestionType.multipleChoice:
        return 'اختيار من متعدد';
    }
  }

  factory QuizQuestionDetail.fromJson(Map<String, dynamic> json) {
    final answers = (json['answers'] as List<dynamic>? ?? [])
        .map((e) => QuizAnswerDetail.fromJson(e as Map<String, dynamic>))
        .toList();
    return QuizQuestionDetail(
      id: (json['id'] as num).toInt(),
      questionText: json['questionText'] as String? ?? '',
      points: json['points'] as int? ?? 1,
      questionType: QuizQuestionType.fromApi(json['questionType']),
      answers: answers,
    );
  }
}

class QuizAnswerDetail {
  final int id;
  final String answerText;
  final bool isCorrect;

  const QuizAnswerDetail({
    required this.id,
    required this.answerText,
    required this.isCorrect,
  });

  factory QuizAnswerDetail.fromJson(Map<String, dynamic> json) {
    return QuizAnswerDetail(
      id: (json['id'] as num).toInt(),
      answerText: json['answerText'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }
}

class AttendanceReport {
  final int classId;
  final String className;
  final String monthNameAr;
  final int year;
  final int month;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final int recordedDays;
  final int totalStudents;
  final List<AttendanceReportStudent> studentStats;

  const AttendanceReport({
    required this.classId,
    required this.className,
    required this.monthNameAr,
    required this.year,
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.recordedDays,
    required this.totalStudents,
    required this.studentStats,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    final stats = (json['studentStats'] as List<dynamic>? ?? [])
        .map((e) => AttendanceReportStudent.fromJson(e as Map<String, dynamic>))
        .toList();
    return AttendanceReport(
      classId: json['classId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      monthNameAr: json['monthNameAr'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? DateTime.now().month,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      totalDays: json['totalDays'] as int? ?? 0,
      recordedDays: json['recordedDays'] as int? ?? json['totalDays'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      studentStats: stats,
    );
  }
}

class AttendanceReportStudent {
  final int studentId;
  final String name;
  final int rollNo;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final double attendancePercentage;
  final List<String> absentDates;

  const AttendanceReportStudent({
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.attendancePercentage,
    this.absentDates = const [],
  });

  factory AttendanceReportStudent.fromJson(Map<String, dynamic> json) {
    return AttendanceReportStudent(
      studentId: json['studentId'] as int,
      name: json['name'] as String? ?? '',
      rollNo: json['rollNo'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      excused: json['excused'] as int? ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0,
      absentDates: (json['absentDates'] as List?)?.map((e) => '$e').toList() ?? const [],
    );
  }
}

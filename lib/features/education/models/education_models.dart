class EducationStage {
  final int id;
  final String nameAr;
  final String nameEn;
  final String code;
  final String? description;
  final int displayOrder;
  final bool isActive;

  EducationStage({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.code,
    this.description,
    required this.displayOrder,
    required this.isActive,
  });

  factory EducationStage.fromJson(Map<String, dynamic> json) {
    return EducationStage(
      id: _asInt(json['id']),
      nameAr: _asString(json['nameAr']),
      nameEn: _asString(json['nameEn']),
      code: _asString(json['code']),
      description: json['description'] as String?,
      displayOrder: _asInt(json['displayOrder'], 0),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class EducationLevel {
  final int id;
  final int educationStageId;
  final String nameAr;
  final String nameEn;
  final String code;
  final int gradeNumber;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final EducationStage? educationStage;

  EducationLevel({
    required this.id,
    required this.educationStageId,
    required this.nameAr,
    required this.nameEn,
    required this.code,
    required this.gradeNumber,
    this.description,
    required this.displayOrder,
    required this.isActive,
    this.educationStage,
  });

  factory EducationLevel.fromJson(Map<String, dynamic> json) {
    return EducationLevel(
      id: _asInt(json['id']),
      educationStageId: _asInt(json['educationStageId']),
      nameAr: _asString(json['nameAr']),
      nameEn: _asString(json['nameEn']),
      code: _asString(json['code']),
      gradeNumber: _asInt(json['gradeNumber']),
      description: json['description'] as String?,
      displayOrder: _asInt(json['displayOrder'], 0),
      isActive: json['isActive'] as bool? ?? true,
      educationStage: json['educationStage'] != null
          ? EducationStage.fromJson(json['educationStage'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AcademicClass {
  final int id;
  final int educationLevelId;
  final int academicYearId;
  final String classCode;
  final String displayName;
  final String? roomNumber;
  final int maxCapacity;
  final int currentCount;
  final bool isActive;
  final EducationLevel? educationLevel;
  final AcademicYear? academicYear;

  AcademicClass({
    required this.id,
    required this.educationLevelId,
    required this.academicYearId,
    required this.classCode,
    required this.displayName,
    this.roomNumber,
    required this.maxCapacity,
    required this.currentCount,
    required this.isActive,
    this.educationLevel,
    this.academicYear,
  });

  factory AcademicClass.fromJson(Map<String, dynamic> json) {
    return AcademicClass(
      id: _asInt(json['id']),
      educationLevelId: _asInt(json['educationLevelId']),
      academicYearId: _asInt(json['academicYearId']),
      classCode: _asString(json['classCode']),
      displayName: _asString(json['displayName']),
      roomNumber: json['roomNumber'] as String?,
      maxCapacity: _asInt(json['maxCapacity'], 30),
      currentCount: _asInt(json['currentCount'], 0),
      isActive: json['isActive'] as bool? ?? true,
      educationLevel: json['educationLevel'] != null
          ? EducationLevel.fromJson(json['educationLevel'] as Map<String, dynamic>)
          : null,
      academicYear: json['academicYear'] != null
          ? AcademicYear.fromJson(json['academicYear'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Subject {
  final int id;
  final String nameAr;
  final String nameEn;
  final String code;
  final String? description;
  final bool isActive;
  final int displayOrder;

  Subject({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.code,
    this.description,
    required this.isActive,
    required this.displayOrder,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}

class AcademicYear {
  final int id;
  final String name;
  final bool isActive;

  AcademicYear({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class TeacherAssignment {
  final int id;
  final int academicClassId;
  final String classDisplayName;
  final String levelNameAr;
  final String stageNameAr;
  final int subjectId;
  final String subjectNameAr;
  final int academicYearId;
  final String academicYearName;
  final String role;
  final bool isActive;

  TeacherAssignment({
    required this.id,
    required this.academicClassId,
    required this.classDisplayName,
    required this.levelNameAr,
    required this.stageNameAr,
    required this.subjectId,
    required this.subjectNameAr,
    required this.academicYearId,
    required this.academicYearName,
    required this.role,
    required this.isActive,
  });

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherAssignment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      academicClassId: (json['academicClassId'] as num?)?.toInt() ?? 0,
      classDisplayName: json['classDisplayName'] as String? ?? '',
      levelNameAr: json['levelNameAr'] as String? ?? '',
      stageNameAr: json['stageNameAr'] as String? ?? '',
      subjectId: (json['subjectId'] as num?)?.toInt() ?? 0,
      subjectNameAr: json['subjectNameAr'] as String? ?? '',
      academicYearId: (json['academicYearId'] as num?)?.toInt() ?? 0,
      academicYearName: json['academicYearName'] as String? ?? '',
      role: json['role']?.toString() ?? 'Primary',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class TeacherMobileProfile {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? staffCode;
  final String? jobTitle;
  final String? department;
  final String? address;
  final String? nationalId;
  final String? qualification;
  final String? insuranceStatus;
  final String? missingDocuments;
  final String? pedagogy;
  final int activeAcademicYearId;
  final String activeAcademicYearName;
  final bool canClasses;
  final bool canStudents;
  final bool canAttendance;
  final bool canQuizzes;
  final bool canChat;
  final bool canReports;
  final bool canParentReports;
  final List<TeacherAssignment> assignments;

  TeacherMobileProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.staffCode,
    this.jobTitle,
    this.department,
    this.address,
    this.nationalId,
    this.qualification,
    this.insuranceStatus,
    this.missingDocuments,
    this.pedagogy,
    required this.activeAcademicYearId,
    required this.activeAcademicYearName,
    this.canClasses = true,
    this.canStudents = true,
    this.canAttendance = true,
    this.canQuizzes = true,
    this.canChat = true,
    this.canReports = true,
    this.canParentReports = false,
    required this.assignments,
  });

  factory TeacherMobileProfile.fromJson(Map<String, dynamic> json) {
    final assignments = (json['assignments'] as List<dynamic>? ?? [])
        .map((e) => TeacherAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
    final perms = json['permissions'];
    bool flag(String key, String camel, {bool fallback = true}) {
      if (perms is Map && perms[key] is bool) return perms[key] as bool;
      if (json[camel] is bool) return json[camel] as bool;
      return fallback;
    }

    String? text(dynamic value) {
      final raw = value?.toString().trim();
      if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') return null;
      return raw;
    }

    return TeacherMobileProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: text(json['fullName']) ?? 'معلم',
      email: text(json['email']),
      phone: text(json['phone']),
      staffCode: text(json['staffCode']),
      jobTitle: text(json['jobTitle']),
      department: text(json['department']),
      address: text(json['address']),
      nationalId: text(json['nationalId']),
      qualification: text(json['qualification']),
      insuranceStatus: text(json['insuranceStatus']),
      missingDocuments: text(json['missingDocuments']),
      pedagogy: text(json['pedagogy']),
      activeAcademicYearId: (json['activeAcademicYearId'] as num?)?.toInt() ?? 0,
      activeAcademicYearName: text(json['activeAcademicYearName']) ?? '',
      canClasses: flag('classes', 'canClasses'),
      canStudents: flag('students', 'canStudents'),
      canAttendance: flag('attendance', 'canAttendance'),
      canQuizzes: flag('quizzes', 'canQuizzes'),
      canChat: flag('chat', 'canChat'),
      canReports: flag('reports', 'canReports'),
      canParentReports: flag('parentReports', 'canParentReports', fallback: false),
      assignments: assignments,
    );
  }
}

class TeacherClassAssignment {
  final int id;
  final int teacherAccountId;
  final int academicClassId;
  final int subjectId;
  final int academicYearId;
  final String role;
  final bool isActive;
  final AcademicClass? academicClass;
  final Subject? subject;

  TeacherClassAssignment({
    required this.id,
    required this.teacherAccountId,
    required this.academicClassId,
    required this.subjectId,
    required this.academicYearId,
    required this.role,
    required this.isActive,
    this.academicClass,
    this.subject,
  });

  factory TeacherClassAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherClassAssignment(
      id: json['id'] as int,
      teacherAccountId: json['teacherAccountId'] as int,
      academicClassId: json['academicClassId'] as int,
      subjectId: json['subjectId'] as int,
      academicYearId: json['academicYearId'] as int,
      role: json['role'] as String? ?? 'Primary',
      isActive: json['isActive'] as bool? ?? true,
      academicClass: json['academicClass'] != null
          ? AcademicClass.fromJson(json['academicClass'] as Map<String, dynamic>)
          : null,
      subject: json['subject'] != null
          ? Subject.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Student {
  final int id;
  final int rollNo;
  final String name;
  final String? grade;
  final String? stage;
  final String? nationalID;
  final String? gender;
  final String? religion;
  final DateTime? dateOfBirth;
  final int? phoneNumber;
  final String? emailAddress;
  final String? fatherName;
  final String? motherName;
  final String? fatherPhone;
  final String? motherPhone;
  final String? address;
  final String? profilePhotoPath;

  Student({
    required this.id,
    required this.rollNo,
    required this.name,
    this.grade,
    this.stage,
    this.nationalID,
    this.gender,
    this.religion,
    this.dateOfBirth,
    this.phoneNumber,
    this.emailAddress,
    this.fatherName,
    this.motherName,
    this.fatherPhone,
    this.motherPhone,
    this.address,
    this.profilePhotoPath,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _asInt(json['id']),
      rollNo: _asInt(json['rollNo']),
      name: _asString(json['name']),
      grade: json['grade'] as String?,
      stage: json['stage'] as String?,
      nationalID: json['nationalID'] as String?,
      gender: json['gender'] as String?,
      religion: json['religion'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      phoneNumber: json['phoneNumber'] == null ? null : _asInt(json['phoneNumber']),
      emailAddress: json['emailAddress'] as String?,
      fatherName: json['fatherName'] as String?,
      motherName: json['motherName'] as String?,
      fatherPhone: json['fatherPhone'] as String?,
      motherPhone: json['motherPhone'] as String?,
      address: json['address'] as String?,
      profilePhotoPath: json['profilePhotoPath'] as String?,
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

String _asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}
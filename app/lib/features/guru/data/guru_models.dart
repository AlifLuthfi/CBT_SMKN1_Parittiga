double _asDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class DashboardStats {
  final int    totalExams, totalQuestions, totalStudents, activeExams, violationsToday, totalSubjects;
  final double averageScore;
  const DashboardStats({required this.totalExams, required this.totalQuestions, required this.totalStudents, required this.averageScore, required this.activeExams, required this.violationsToday, required this.totalSubjects});
  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalExams:      j['total_exams']      as int? ?? 0,
    totalQuestions:  j['total_questions']  as int? ?? 0,
    totalStudents:   j['total_students']   as int? ?? 0,
    averageScore:    _asDouble(j['average_score'], 0),
    activeExams:     j['active_exams']     as int? ?? 0,
    violationsToday: j['violations_today'] as int? ?? 0,
    totalSubjects:   j['total_subjects']   as int? ?? 0,
  );
}

class ClassRoomModel {
  final int id; final String name; final String? subject; final String? academicYear; final int? studentCount, examCount;
  const ClassRoomModel({required this.id, required this.name, this.subject, this.academicYear, this.studentCount, this.examCount});
  factory ClassRoomModel.fromJson(Map<String, dynamic> j) => ClassRoomModel(
    id:           j['id']            as int,
    name:         j['name']          as String,
    subject:      j['subject']       as String?,
    academicYear: j['academic_year'] as String?,
    studentCount: j['student_count'] as int?,
    examCount:    j['exam_count']    as int?,
  );
}

class ExamModel {
  final int id; final String title; final String status;
  final int durationMinutes; final double passingGrade; final int totalQuestions;
  final int? sessionsCount, submittedCount, violationsCount;
  final String? startTime, endTime; final ClassRoomModel? classRoom;
  const ExamModel({required this.id, required this.title, required this.status, required this.durationMinutes, required this.passingGrade, required this.totalQuestions, this.sessionsCount, this.submittedCount, this.violationsCount, this.startTime, this.endTime, this.classRoom});
  factory ExamModel.fromJson(Map<String, dynamic> j) => ExamModel(
    id:              j['id']               as int,
    title:           j['title']            as String,
    status:          j['status']           as String? ?? 'draft',
    durationMinutes: j['duration_minutes'] as int?    ?? 90,
    passingGrade:    _asDouble(j['passing_grade'], 70),
    totalQuestions:  j['total_questions']  as int?    ?? 0,
    sessionsCount:   j['sessions_count']   as int?,
    submittedCount:  j['submitted_count']  as int?,
    violationsCount: j['violations_count'] as int?,
    startTime:       j['start_time']       as String?,
    endTime:         j['end_time']         as String?,
    classRoom:       j['class_room'] != null ? ClassRoomModel.fromJson(j['class_room'] as Map<String, dynamic>) : null,
  );
  bool get isActive    => status == 'active';
  bool get isDraft     => status == 'draft';
  bool get isScheduled => status == 'scheduled';
  bool get isEnded     => status == 'ended';
}

class QuestionModel {
  final int id; final String questionText, questionType, difficulty; final double weight;
  final Map<String, String>? options; final String? correctAnswer, explanation, categoryName, imageUrl;
  final int? subjectId; final String? subjectName;
  const QuestionModel({required this.id, required this.questionText, required this.questionType, required this.difficulty, required this.weight, this.options, this.correctAnswer, this.explanation, this.categoryName, this.imageUrl, this.subjectId, this.subjectName});
  factory QuestionModel.fromJson(Map<String, dynamic> j) => QuestionModel(
    id:           j['id']            as int,
    questionText: j['question_text'] as String,
    questionType: j['question_type'] as String? ?? 'multiple_choice',
    difficulty:   j['difficulty']    as String? ?? 'medium',
    weight:       _asDouble(j['weight'], 1),
    options:      (j['options']      as Map?)?.cast<String, String>(),
    correctAnswer:j['correct_answer'] as String?,
    explanation:  j['explanation']   as String?,
    categoryName: (j['category']     as Map?)?['name'] as String?,
    imageUrl:     j['image_url']     as String?,
    subjectId:    (j['subject']      as Map?)?['id'] as int?,
    subjectName:  (j['subject']      as Map?)?['name'] as String?,
  );
}

class ViolationModel {
  final String studentName, violationType, createdAt; final int count;
  const ViolationModel({required this.studentName, required this.violationType, required this.count, required this.createdAt});
  factory ViolationModel.fromJson(Map<String, dynamic> j) => ViolationModel(
    studentName:   (j['student'] as Map?)?['name'] as String? ?? '—',
    violationType: j['violation_type'] as String,
    count:         j['count'] as int,
    createdAt:     j['created_at'] as String? ?? '',
  );
  String get typeLabel {
    const m = {'tab_switch':'Pindah Tab','fullscreen_exit':'Keluar Layar','copy_paste':'Copy-Paste','blur':'Keluar App','devtools':'DevTools'};
    return m[violationType] ?? violationType;
  }
}

class QuestionImportPreviewRow {
  final int row;
  final String status;
  final String? questionText;
  final Map<String, String>? options;
  final String? correctAnswer;
  final String? difficulty;
  final double? weight;
  final String? explanation;
  final String? category;
  final List<String>? tags;
  final List<String>? errors;

  const QuestionImportPreviewRow({
    required this.row,
    required this.status,
    this.questionText,
    this.options,
    this.correctAnswer,
    this.difficulty,
    this.weight,
    this.explanation,
    this.category,
    this.tags,
    this.errors,
  });

  factory QuestionImportPreviewRow.fromJson(Map<String, dynamic> j) {
    final optionsRaw = j['options'] as Map?;
    return QuestionImportPreviewRow(
      row:           j['row']       as int,
      status:        j['status']    as String? ?? 'ok',
      questionText:  j['question_text'] as String?,
      options:       optionsRaw?.map((k, v) => MapEntry(k.toString(), v.toString())),
      correctAnswer: j['correct_answer'] as String?,
      difficulty:    j['difficulty']     as String?,
      weight:        (j['weight'] is num ? (j['weight'] as num).toDouble() : double.tryParse((j['weight'] ?? '').toString())),
      explanation:   j['explanation']    as String?,
      category:      j['category']       as String?,
      tags:          (j['tags'] as List?)?.map((e) => e.toString()).toList(),
      errors:        (j['errors'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

class QuestionImportPreview {
  final int totalRows, previewRows, validCount, errorCount;
  final List<QuestionImportPreviewRow> preview;

  const QuestionImportPreview({
    required this.totalRows,
    required this.previewRows,
    required this.validCount,
    required this.errorCount,
    required this.preview,
  });

  factory QuestionImportPreview.fromJson(Map<String, dynamic> j) => QuestionImportPreview(
    totalRows:   j['total_rows']   as int? ?? 0,
    previewRows: j['preview_rows'] as int? ?? 0,
    validCount:  j['valid_count']  as int? ?? 0,
    errorCount:  j['error_count']  as int? ?? 0,
    preview:     ((j['preview'] as List?) ?? []).map((e) => QuestionImportPreviewRow.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class QuestionImportModel {
  final int id;
  final String filename, status;
  final int totalRows, successCount, errorCount;
  final List<String>? errors;
  final String? createdAt;

  const QuestionImportModel({
    required this.id,
    required this.filename,
    required this.status,
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    this.errors,
    this.createdAt,
  });

  factory QuestionImportModel.fromJson(Map<String, dynamic> j) => QuestionImportModel(
    id:           j['id']            as int,
    filename:     j['filename']      as String? ?? '',
    status:       j['status']        as String? ?? '',
    totalRows:    j['total_rows']    as int? ?? 0,
    successCount: j['success_count'] as int? ?? 0,
    errorCount:   j['error_count']   as int? ?? 0,
    errors:       (j['errors'] as List?)?.map((e) => e.toString()).toList(),
    createdAt:    j['created_at']    as String?,
  );
}

class SubjectModel {
  final int id; final String name; final int? questionsCount;
  SubjectModel({required this.id, required this.name, this.questionsCount});
  factory SubjectModel.fromJson(Map<String, dynamic> j) => SubjectModel(
    id:       j['id']       as int,
    name:     j['name']     as String,
    questionsCount: j['questions_count'] as int?,
  );
}

double _asDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class DashboardStats {
  final int    totalExams, totalQuestions, totalStudents, activeExams, violationsToday;
  final double averageScore;
  const DashboardStats({required this.totalExams, required this.totalQuestions, required this.totalStudents, required this.averageScore, required this.activeExams, required this.violationsToday});
  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalExams:      j['total_exams']      as int? ?? 0,
    totalQuestions:  j['total_questions']  as int? ?? 0,
    totalStudents:   j['total_students']   as int? ?? 0,
    averageScore:    _asDouble(j['average_score'], 0),
    activeExams:     j['active_exams']     as int? ?? 0,
    violationsToday: j['violations_today'] as int? ?? 0,
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

class SubjectModel {
  final int id; final String name; final int? questionsCount;
  SubjectModel({required this.id, required this.name, this.questionsCount});
  factory SubjectModel.fromJson(Map<String, dynamic> j) => SubjectModel(
    id:       j['id']       as int,
    name:     j['name']     as String,
    questionsCount: j['questions_count'] as int?,
  );
}

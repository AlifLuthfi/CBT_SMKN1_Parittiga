class SiswaExamModel {
  final int id; final String title, subject, className;
  final int durationMinutes, maxViolations; final double passingGrade;
  final int totalQuestions; final String? sessionStatus; final int? sessionId;
  final bool canStart, randomizeQuestions, randomizeOptions;
  final String? startTime, endTime;
  const SiswaExamModel({required this.id, required this.title, required this.subject, required this.className, required this.durationMinutes, required this.passingGrade, required this.totalQuestions, required this.maxViolations, this.sessionStatus, this.sessionId, this.canStart = true, this.randomizeQuestions = true, this.randomizeOptions = true, this.startTime, this.endTime});
  factory SiswaExamModel.fromJson(Map<String, dynamic> j) => SiswaExamModel(
    id:                j['id']                as int,
    title:             j['title']             as String,
    subject:           j['subject']           as String? ?? j['class_room']?['subject'] as String? ?? '',
    className:         j['class_name']        as String? ?? j['class_room']?['name']    as String? ?? '',
    durationMinutes:   j['duration_minutes']  as int?    ?? 90,
    passingGrade:      (j['passing_grade']    is num ? (j['passing_grade'] as num).toDouble() : double.tryParse(j['passing_grade']?.toString() ?? '') ?? 70),
    totalQuestions:    j['total_questions']   as int?    ?? 0,
    maxViolations:     j['max_violations']    as int?    ?? 5,
    sessionStatus:     j['session_status']    as String?,
    sessionId:         j['session_id']        as int?,
    canStart:          j['can_start']         as bool?   ?? true,
    randomizeQuestions:j['randomize_questions'] as bool? ?? true,
    randomizeOptions:  j['randomize_options']   as bool? ?? true,
    startTime:         j['start_time']        as String?,
    endTime:           j['end_time']          as String?,
  );
}

class ExamSessionData {
  final int sessionId, examId, seed, remainingSeconds;
  final String status; final String? startedAt;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> savedAnswers;
  final List<int> flaggedIds;
  const ExamSessionData({required this.sessionId, required this.examId, required this.seed, required this.status, required this.remainingSeconds, this.startedAt, required this.questions, required this.savedAnswers, this.flaggedIds = const []});
  factory ExamSessionData.fromJson(Map<String, dynamic> j) {
    final raw = j['saved_answers'];
    final rawAnswers = (raw is Map) ? raw : <dynamic, dynamic>{};
    final answers = rawAnswers.map((k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, v.toString()));
    final rawFlagged = j['flagged_ids'];
    final flagged = (rawFlagged is List) ? rawFlagged.cast<int>() : <int>[];
    return ExamSessionData(
      sessionId:       j['session_id']       as int,
      examId:          j['exam_id']          as int,
      seed:            j['seed']             as int? ?? 0,
      status:          j['status']           as String,
      remainingSeconds: (j['remaining_seconds'] is num ? (j['remaining_seconds'] as num).toInt() : 0),
      startedAt:       j['started_at']       as String?,
      questions:       ((j['questions']      as List?) ?? []).cast<Map<String, dynamic>>(),
      savedAnswers:    answers,
      flaggedIds:      flagged,
    );
  }
}

class AnswerDetail {
  final int questionId; final String questionText, questionType;
  final Map<String, String>? options;
  final String? correctAnswer, explanation, userAnswer, imageUrl; final bool? isCorrect;
  final String status;
  const AnswerDetail({required this.questionId, required this.questionText, required this.questionType, this.options, this.correctAnswer, this.explanation, this.userAnswer, this.isCorrect, this.imageUrl, required this.status});
  factory AnswerDetail.fromJson(Map<String, dynamic> j) => AnswerDetail(
    questionId:   j['question_id']   as int,
    questionText: j['question_text'] as String,
    questionType: j['question_type'] as String? ?? 'multiple_choice',
    options:      (j['options']      as Map?)?.cast<String, String>(),
    correctAnswer:j['correct_answer'] as String?,
    explanation:  j['explanation']   as String?,
    userAnswer:   j['user_answer']   as String?,
    isCorrect:    j['is_correct']    as bool?,
    imageUrl:     j['image_url']     as String?,
    status:       j['status']        as String? ?? 'unanswered',
  );
}

class ExamResultModel {
  final double score, passingGrade;
  final bool   isPassed;
  final int    correct, wrong, unanswered, total, durationTaken;
  final String className;
  final List<AnswerDetail> answers;
  const ExamResultModel({required this.score, required this.isPassed, required this.passingGrade, required this.correct, required this.wrong, required this.unanswered, required this.total, required this.durationTaken, this.className = '', required this.answers});
  factory ExamResultModel.fromJson(Map<String, dynamic> j) => ExamResultModel(
    score:        (j['score'] is num ? (j['score'] as num).toDouble() : double.tryParse(j['score']?.toString() ?? '') ?? 0),
    isPassed:     j['is_passed']      as bool? ?? false,
    passingGrade: (j['passing_grade'] is num ? (j['passing_grade'] as num).toDouble() : double.tryParse(j['passing_grade']?.toString() ?? '') ?? 70),
    correct:      j['correct']        as int? ?? 0,
    wrong:        j['wrong']          as int? ?? 0,
    unanswered:   j['unanswered']     as int? ?? 0,
    total:        j['total']          as int? ?? 0,
    durationTaken:j['duration_taken'] as int? ?? 0,
    className:    j['class_name']     as String? ?? '',
    answers:      ((j['answers']      as List?) ?? []).map((a) => AnswerDetail.fromJson(a as Map<String, dynamic>)).toList(),
  );
}

class RiwayatItem {
  final int    sessionId;
  final String examTitle;
  final String subject;
  final String submittedAt;
  final String status;
  final double score;
  final double passingGrade;
  final bool   isPassed;
  final int    correct;
  final int    wrong;
  final int    unanswered;
  final int    total;

  const RiwayatItem({
    required this.sessionId,
    required this.examTitle,
    required this.subject,
    required this.submittedAt,
    required this.status,
    required this.score,
    required this.passingGrade,
    required this.isPassed,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
  });

  factory RiwayatItem.fromJson(Map<String, dynamic> j) {
    final exam = j['exam'] as Map<String, dynamic>? ?? {};
    return RiwayatItem(
      sessionId:    j['id']                       as int,
      examTitle:    exam['title']                 as String? ?? '',
      subject:      (exam['class_room'] as Map?)?['subject'] as String? ?? '',
      submittedAt:  j['submitted_at']             as String? ?? '',
      status:       j['status']                   as String? ?? '',
      score:        double.tryParse(j['score']?.toString() ?? '') ?? 0,
      passingGrade: double.tryParse((exam['passing_grade'] ?? '').toString()) ?? 70,
      isPassed:     j['is_passed']                as bool? ?? false,
      correct:      j['correct']                  as int? ?? 0,
      wrong:        j['wrong']                    as int? ?? 0,
      unanswered:   j['unanswered']               as int? ?? 0,
      total:        j['total']                    as int? ?? 0,
    );
  }
}


import 'dart:async';
import 'dart:developer' as dev;
import '../../../core/network/api_client.dart';
import 'siswa_models.dart';

class SiswaRepository {
  Future<T> _retry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        dev.log('Retry ${i + 1}/$maxRetries: $e', name: 'SiswaRepository');
        await Future.delayed(Duration(seconds: 1 << i)); // 1, 2, 4s
      }
    }
    throw StateError('Unreachable');
  }

  Future<List<SiswaExamModel>> getAvailableExams() async {
    final data = await ApiClient.get('/siswa/exams');
    final list = (data['data'] as List?) ?? (data as List? ?? []);
    return list.map((e) => SiswaExamModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SiswaExamModel> getExamDetail(int examId) async {
    final data = await ApiClient.get('/siswa/exams/$examId');
    return SiswaExamModel.fromJson(data['exam'] as Map<String, dynamic>);
  }

  Future<({ExamSessionData session, bool isResumed})> startExam(int examId, {List<int>? lcgVerify}) async {
    final data = await ApiClient.post('/siswa/exams/$examId/start', data: {
      if (lcgVerify != null) 'lcg_verify': lcgVerify,
    });
    final session   = ExamSessionData.fromJson(data['session'] as Map<String, dynamic>);
    final isResumed = data['is_resumed'] as bool? ?? false;
    return (session: session, isResumed: isResumed);
  }

  Future<void> saveAnswer(int sessionId, int questionId, String? answer) async {
    try {
      await _retry(() => ApiClient.patch('/siswa/sessions/$sessionId/answer',
          data: {'question_id': questionId, 'answer': answer}));
    } catch (_) {
      dev.log('saveAnswer failed after retries', name: 'SiswaRepository');
    }
  }

  Future<void> bulkSaveAnswers(int sessionId, Map<int, String?> answers) async {
    try {
      final list = answers.entries.map((e) => {'question_id': e.key, 'answer': e.value}).toList();
      await _retry(() => ApiClient.post('/siswa/sessions/$sessionId/answers', data: {'answers': list}));
    } catch (_) {
      dev.log('bulkSaveAnswers failed after retries', name: 'SiswaRepository');
    }
  }

  Future<ExamResultModel> submitExam(int sessionId) async {
    final data = await ApiClient.post('/siswa/sessions/$sessionId/submit');
    return ExamResultModel.fromJson(data['result'] as Map<String, dynamic>);
  }

  Future<ExamResultModel> getResult(int sessionId) async {
    final data = await ApiClient.get('/siswa/sessions/$sessionId/result');
    return ExamResultModel.fromJson(data['result'] as Map<String, dynamic>);
  }

  Future<void> recordViolation(int sessionId, String type) async {
    try { await ApiClient.post('/siswa/violations', data: {'session_id': sessionId, 'violation_type': type}); }
    catch (_) {}
  }

  Future<({int remainingSeconds})?> getSessionState(int sessionId) async {
    try {
      final data = await ApiClient.get('/siswa/sessions/$sessionId/state');
      final session = data['session'] as Map<String, dynamic>;
      final remaining = session['remaining_seconds'];
      return (remainingSeconds: (remaining is int) ? remaining : (remaining as num).toInt());
    } catch (_) {
      return null;
    }
  }

  Future<List<RiwayatItem>> getHistory() async {
    final data = await ApiClient.get('/siswa/history');
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => RiwayatItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> verifyExitPassword(int? sessionId, String password) async {
    final data = await ApiClient.post('/siswa/verify-exit', data: {
      'password': password,
      'session_id': sessionId,
      'action': 'exit_exam',
    });
    return data;
  }
}

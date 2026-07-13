import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/siswa/data/siswa_models.dart';
import '../../features/siswa/data/siswa_repository.dart';
import '../constants/app_constants.dart';
import '../security/lcg_randomizer.dart';
import '../storage/secure_storage.dart';

// ── Exam Session State ────────────────────────────────
enum SessionPhase { biodata, running, submitting, done }

class ExamSessionState {
  final SessionPhase      phase;
  final SiswaExamModel?   exam;
  final ExamSessionData?  session;
  final List<ExamQuestion> questions;    // setelah LCG shuffle
  final Map<int, String>  answers;      // questionId → key
  final Set<int>          flagged;
  final int               currentIndex;
  final int               secondsLeft;
  final int               violationCount;
  final int               seed;
  final bool              loading;
  final bool              submitting;
  final String?           error;
  final ExamResultModel?  result;

  const ExamSessionState({
    this.phase         = SessionPhase.biodata,
    this.exam,
    this.session,
    this.questions     = const [],
    this.answers       = const {},
    this.flagged       = const {},
    this.currentIndex  = 0,
    this.secondsLeft   = 0,
    this.violationCount= 0,
    this.seed          = 0,
    this.loading       = false,
    this.submitting    = false,
    this.error,
    this.result,
  });

  ExamQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  int  get answeredCount => answers.length;
  int  get totalCount    => questions.length;
  bool get isWarningTime => secondsLeft <= 300 && secondsLeft > 60;
  bool get isDangerTime  => secondsLeft <= 60;
  bool get canGoNext     => currentIndex < questions.length - 1;
  bool get canGoPrev     => currentIndex > 0;
  bool get isLastQuestion=> currentIndex == questions.length - 1;

  String get formattedTime {
    final h = secondsLeft ~/ 3600;
    final m = (secondsLeft % 3600) ~/ 60;
    final s = secondsLeft % 60;
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  ExamSessionState copyWith({
    SessionPhase?        phase,
    SiswaExamModel?      exam,
    ExamSessionData?     session,
    List<ExamQuestion>?  questions,
    Map<int, String>?    answers,
    Set<int>?            flagged,
    int?                 currentIndex,
    int?                 secondsLeft,
    int?                 violationCount,
    int?                 seed,
    bool?                loading,
    bool?                submitting,
    String?              error,
    ExamResultModel?     result,
  }) => ExamSessionState(
    phase:          phase          ?? this.phase,
    exam:           exam           ?? this.exam,
    session:        session        ?? this.session,
    questions:      questions      ?? this.questions,
    answers:        answers        ?? this.answers,
    flagged:        flagged        ?? this.flagged,
    currentIndex:   currentIndex   ?? this.currentIndex,
    secondsLeft:    secondsLeft    ?? this.secondsLeft,
    violationCount: violationCount ?? this.violationCount,
    seed:           seed           ?? this.seed,
    loading:        loading        ?? this.loading,
    submitting:     submitting     ?? this.submitting,
    error:          error,
    result:         result         ?? this.result,
  );
}

// ── Exam Session Notifier ─────────────────────────────
class ExamSessionNotifier extends StateNotifier<ExamSessionState> {
  ExamSessionNotifier() : super(const ExamSessionState());

  final _repo     = SiswaRepository();
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _totalSeconds   = 0;      // wall-clock anchor — total duration
  int _timeElapsed    = 0;      // seconds elapsed before current tick window
  DateTime? _timerStartedAt;    // when current timer window started

  // ── Load exam detail ─────────────────────────────────
  Future<void> loadExam(int examId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final exam = await _repo.getExamDetail(examId);

      // Check saved session
      final saved = await SecureStorage.getExamSession();
      if (saved != null && saved['examId'] == examId) {
        final savedAt  = DateTime.tryParse(saved['savedAt'] as String? ?? '');
        final elapsed  = savedAt != null ? DateTime.now().difference(savedAt).inSeconds : 0;
        final remaining= (saved['secondsLeft'] as int? ?? 0) - elapsed;
        if (remaining > 30) {
          final rawAnswers = (saved['answers'] as Map? ?? {})
              .map((k, v) => MapEntry(int.parse(k.toString()), v.toString()));
          final rawFlagged = Set<int>.from(
              (saved['flagged'] as List? ?? []).map((e) => e as int));
          state = state.copyWith(
            exam:         exam,
            answers:      rawAnswers,
            flagged:      rawFlagged,
            currentIndex: saved['currentIndex'] as int? ?? 0,
            secondsLeft:  remaining,
            seed:         saved['seed'] as int? ?? 0,
            loading:      false,
          );
          // Restore wall-clock anchor
          _totalSeconds = saved['totalSeconds'] as int? ?? exam.durationMinutes * 60;
          _timeElapsed  = saved['timeElapsed'] as int? ?? (_totalSeconds - remaining);
          return;
        }
      }

      state = state.copyWith(exam: exam, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── Start exam ────────────────────────────────────────
  Future<void> startExam({required String nama, required String nis, required String kelas}) async {
    if (state.exam == null) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final localSeed  = ExamRandomizer.generateSeed();
      final lcgVerify  = ExamRandomizer(localSeed).verifySeed(5);
      final result     = await _repo.startExam(state.exam!.id, lcgVerify: lcgVerify);
      final session    = result.session;
      final seed       = session.seed;
      final randomizer = ExamRandomizer(seed);

      // Build shuffled questions
      final rawQuestions = session.questions.map((q) => ExamQuestion.fromJson(q)).toList();
      final questions    = randomizer.process(rawQuestions);

      final answers      = result.isResumed ? Map<int, String>.from(session.savedAnswers) : <int, String>{};
      final secondsLeft = result.isResumed ? session.remainingSeconds : state.exam!.durationMinutes * 60;

      // Wall-clock anchor
      _totalSeconds  = state.exam!.durationMinutes * 60;
      _timeElapsed   = _totalSeconds - secondsLeft;
      _timerStartedAt = null;

      state = state.copyWith(
        phase:        SessionPhase.running,
        session:      session,
        questions:    questions,
        answers:      answers,
        flagged:      {},
        currentIndex: 0,
        secondsLeft:  secondsLeft,
        violationCount: 0,
        seed:         seed,
        loading:      false,
      );

      _startTimer();
      _startAutoSave();
      await _saveSession();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── Answer ────────────────────────────────────────────
  void selectAnswer(int questionId, String key) {
    final updated = Map<int, String>.from(state.answers);
    updated[questionId] = key;
    state = state.copyWith(answers: updated);
    _saveSession();
    // Non-blocking server save
    if (state.session != null) {
      _repo.saveAnswer(state.session!.sessionId, questionId, key);
    }
  }

  void clearAnswer(int questionId) {
    final updated = Map<int, String>.from(state.answers);
    updated.remove(questionId);
    state = state.copyWith(answers: updated);
    _saveSession();
  }

  // ── Navigation ────────────────────────────────────────
  void goToQuestion(int index) {
    if (index < 0 || index >= state.questions.length) return;
    state = state.copyWith(currentIndex: index);
  }

  void nextQuestion() { if (state.canGoNext) state = state.copyWith(currentIndex: state.currentIndex + 1); }
  void prevQuestion() { if (state.canGoPrev) state = state.copyWith(currentIndex: state.currentIndex - 1); }

  // ── Flag ─────────────────────────────────────────────
  void toggleFlag(int questionId) {
    final updated = Set<int>.from(state.flagged);
    if (updated.contains(questionId)) updated.remove(questionId);
    else updated.add(questionId);
    state = state.copyWith(flagged: updated);
  }

  // ── Violation ─────────────────────────────────────────
  void recordViolation(String type) {
    final count = state.violationCount + 1;
    state = state.copyWith(violationCount: count);
    if (state.session != null) {
      _repo.recordViolation(state.session!.sessionId, type);
    }
    if (count >= (state.exam?.maxViolations ?? 5)) {
      autoSubmit();
    }
  }

  // ── Timer (wall-clock based) ────────────────────────
  void _startTimer() {
    _timerStartedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final wallElapsed = _timeElapsed + DateTime.now().difference(_timerStartedAt!).inSeconds;
      final remaining = _totalSeconds - wallElapsed;
      if (remaining <= 0) {
        _timer?.cancel();
        _autoSaveTimer?.cancel();
        state = state.copyWith(secondsLeft: 0);
        autoSubmit();
        return;
      }
      state = state.copyWith(secondsLeft: remaining);
    });
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: AppConstants.autoSaveIntervalSecs),
      (_) => _saveSession(),
    );
  }

  Future<void> _saveSession() async {
    if (state.session == null || state.seed == 0) return;
    await SecureStorage.saveExamSession({
      'examId':       state.exam?.id,
      'sessionId':    state.session!.sessionId,
      'seed':         state.seed,
      'answers':      state.answers.map((k, v) => MapEntry(k.toString(), v)),
      'flagged':      state.flagged.toList(),
      'currentIndex': state.currentIndex,
      'secondsLeft':  state.secondsLeft,
      'totalSeconds': _totalSeconds,
      'timeElapsed':  _timeElapsed + (_timerStartedAt != null ? DateTime.now().difference(_timerStartedAt!).inSeconds : 0),
      'savedAt':      DateTime.now().toIso8601String(),
    });
  }

  // ── Submit ────────────────────────────────────────────
  Future<ExamResultModel?> submit() async {
    if (state.session == null || state.submitting) return null;
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    state = state.copyWith(submitting: true, phase: SessionPhase.submitting);
    try {
      await _repo.bulkSaveAnswers(state.session!.sessionId, state.answers.cast<int, String?>());
      final result = await _repo.submitExam(state.session!.sessionId);
      await SecureStorage.clearExamSession();
      state = state.copyWith(submitting: false, phase: SessionPhase.done, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(submitting: false, phase: SessionPhase.running, error: e.toString());
      return null;
    }
  }

  Future<void> autoSubmit() async {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    await submit();
  }

  // ── Reset ─────────────────────────────────────────────
  void reset() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    state = const ExamSessionState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

final examSessionProvider = StateNotifierProvider.autoDispose<ExamSessionNotifier, ExamSessionState>(
  (_) => ExamSessionNotifier(),
);

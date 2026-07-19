import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/siswa/data/siswa_models.dart';
import '../../features/siswa/data/siswa_repository.dart';

// ── Repository singleton ──────────────────────────────
final siswaRepoProvider = Provider<SiswaRepository>((_) => SiswaRepository());

// ── Available Exams State ─────────────────────────────
class AvailableExamsState {
  final List<SiswaExamModel> items;
  final bool    loading;
  final String? error;

  const AvailableExamsState({
    this.items   = const [],
    this.loading = false,
    this.error,
  });

  int get activeCount    => items.where((e) => e.sessionStatus == 'in_progress' || e.sessionStatus == null).length;
  int get completedCount => items.where((e) => e.sessionStatus == 'submitted' || e.sessionStatus == 'timeout').length;

  AvailableExamsState copyWith({
    List<SiswaExamModel>? items,
    bool?    loading,
    String?  error,
  }) => AvailableExamsState(
    items:   items   ?? this.items,
    loading: loading ?? this.loading,
    error:   error,
  );
}

class AvailableExamsNotifier extends StateNotifier<AvailableExamsState> {
  AvailableExamsNotifier(this._repo) : super(const AvailableExamsState());

  final SiswaRepository _repo;

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await _repo.getAvailableExams();
      state = state.copyWith(items: results, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // Update session status lokal setelah submit
  void markSubmitted(int examId, int sessionId) {
    final updated = state.items.map((e) {
      if (e.id == examId) {
        return SiswaExamModel(
          id: e.id, title: e.title, subject: e.subject, className: e.className,
          durationMinutes: e.durationMinutes, passingGrade: e.passingGrade,
          totalQuestions: e.totalQuestions, maxViolations: e.maxViolations,
          sessionStatus: 'submitted', sessionId: sessionId, canStart: false,
          randomizeQuestions: e.randomizeQuestions, randomizeOptions: e.randomizeOptions,
        );
      }
      return e;
    }).toList();
    state = state.copyWith(items: updated);
  }
}

final availableExamsProvider = StateNotifierProvider<AvailableExamsNotifier, AvailableExamsState>((ref) {
  final repo = ref.watch(siswaRepoProvider);
  return AvailableExamsNotifier(repo)..fetch();
});

// ── Riwayat Ujian State ───────────────────────────────
class RiwayatState {
  final List<RiwayatItem> items;
  final bool    loading;
  final String? error;
  final String  filter; // all | pass | fail

  const RiwayatState({
    this.items   = const [],
    this.loading = false,
    this.error,
    this.filter  = 'all',
  });

  List<RiwayatItem> get filtered => switch (filter) {
    'pass' => items.where((r) => r.isPassed).toList(),
    'fail' => items.where((r) => !r.isPassed).toList(),
    _      => items,
  };

  double get averageScore => items.isEmpty ? 0
      : items.map((r) => r.score).reduce((a,b) => a+b) / items.length;

  double get bestScore => items.isEmpty ? 0
      : items.map((r) => r.score).reduce((a,b) => a>b ? a:b);

  int get passCount => items.where((r) => r.isPassed).length;

  RiwayatState copyWith({
    List<RiwayatItem>? items,
    bool?    loading,
    String?  error,
    String?  filter,
  }) => RiwayatState(
    items:   items   ?? this.items,
    loading: loading ?? this.loading,
    error:   error,
    filter:  filter  ?? this.filter,
  );
}

class RiwayatNotifier extends StateNotifier<RiwayatState> {
  RiwayatNotifier() : super(const RiwayatState());

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // Demo data — ganti dengan API call nyata
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(items: _demoRiwayat, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  // Add result after submit
  void addResult(ExamResultModel result, int sessionId, String examTitle, String subject) {
    final newItem = RiwayatItem(
      sessionId:    sessionId,
      examTitle:    examTitle,
      subject:      subject,
      submittedAt:  DateTime.now().toIso8601String().substring(0, 10),
      status:       'submitted',
      score:        result.score,
      passingGrade: result.passingGrade,
      isPassed:     result.isPassed,
      correct:      result.correct,
      wrong:        result.wrong,
      unanswered:   result.unanswered,
      total:        result.total,
    );
    state = state.copyWith(items: [newItem, ...state.items]);
  }
}

final riwayatProvider = StateNotifierProvider<RiwayatNotifier, RiwayatState>(
  (_) => RiwayatNotifier()..fetch(),
);

// Demo data
const _demoRiwayat = [
  RiwayatItem(sessionId:101, examTitle:'UH 1 — Aljabar Dasar', subject:'Matematika', submittedAt:'2026-05-10', status:'submitted', score:88, passingGrade:70, isPassed:true,  correct:8,  wrong:1, unanswered:1, total:10),
  RiwayatItem(sessionId:99,  examTitle:'UH Ekonomi Mikro',     subject:'Ekonomi',    submittedAt:'2026-05-08', status:'submitted', score:92, passingGrade:70, isPassed:true,  correct:36, wrong:2, unanswered:2, total:40),
  RiwayatItem(sessionId:95,  examTitle:'UTS Fisika Dasar',     subject:'Fisika',     submittedAt:'2026-04-28', status:'timeout',   score:64, passingGrade:75, isPassed:false, correct:16, wrong:6, unanswered:3, total:25),
  RiwayatItem(sessionId:90,  examTitle:'UH Kimia Organik',     subject:'Kimia',      submittedAt:'2026-04-20', status:'submitted', score:97, passingGrade:70, isPassed:true,  correct:29, wrong:1, unanswered:0, total:30),
];

// ── Exam Result Cache ─────────────────────────────────
// Cache hasil ujian agar tidak perlu re-fetch
class ResultCache extends StateNotifier<Map<int, ExamResultModel>> {
  ResultCache() : super({});

  void cache(int sessionId, ExamResultModel result) {
    state = Map.from(state)..[sessionId] = result;
  }

  ExamResultModel? get(int sessionId) => state[sessionId];

  void clear() => state = {};
}

final resultCacheProvider = StateNotifierProvider<ResultCache, Map<int, ExamResultModel>>(
  (_) => ResultCache(),
);

final resultProvider = FutureProvider.autoDispose.family<ExamResultModel, int>((ref, sessionId) async {
  // Check cache first
  final cached = ref.read(resultCacheProvider)[sessionId];
  if (cached != null) return cached;

  final repo   = ref.read(siswaRepoProvider);
  final result = await repo.getResult(sessionId);

  // Cache result
  ref.read(resultCacheProvider.notifier).cache(sessionId, result);
  return result;
});

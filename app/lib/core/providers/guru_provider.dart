import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/guru/data/guru_models.dart';
import '../../features/guru/data/guru_repository.dart';

// ── Repository singleton ──────────────────────────────
final guruRepoProvider = Provider<GuruRepository>((_) => GuruRepository());

// ── Dashboard ─────────────────────────────────────────
class DashboardState {
  final DashboardStats? stats;
  final List<ExamModel> activeExams;
  final List<ExamModel> recentExams;
  final List<ViolationModel> violations;
  final bool   loading;
  final String? error;

  const DashboardState({
    this.stats,
    this.activeExams  = const [],
    this.recentExams  = const [],
    this.violations   = const [],
    this.loading      = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardStats?       stats,
    List<ExamModel>?      activeExams,
    List<ExamModel>?      recentExams,
    List<ViolationModel>? violations,
    bool?    loading,
    String?  error,
  }) => DashboardState(
    stats:       stats       ?? this.stats,
    activeExams: activeExams ?? this.activeExams,
    recentExams: recentExams ?? this.recentExams,
    violations:  violations  ?? this.violations,
    loading:     loading     ?? this.loading,
    error:       error,
  );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._repo) : super(const DashboardState());

  final GuruRepository _repo;

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data   = await _repo.getDashboard();
      final stats  = DashboardStats.fromJson(data['stats'] as Map<String, dynamic>? ?? {});
      final active = ((data['activeExams'] ?? data['active_exams']) as List? ?? [])
          .map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
      final recent = ((data['recentExams'] ?? data['recent_exams']) as List? ?? [])
          .map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
      final viols  = ((data['recentViolations'] ?? data['recent_violations']) as List? ?? [])
          .map((e) => ViolationModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(
        stats:       stats,
        activeExams: active,
        recentExams: recent,
        violations:  viols,
        loading:     false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> activateExam(int id) async {
    await _repo.updateExam(id, {'status': 'active'});
    await fetch();
  }

  Future<void> pauseExam(int id, {String reason = ''}) async {
    await _repo.pauseExam(id, reason: reason);
    await fetch();
  }

  Future<void> endExam(int id) async {
    await _repo.endExam(id);
    await fetch();
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(guruRepoProvider);
  return DashboardNotifier(repo)..fetch();
});

// ── Exams ─────────────────────────────────────────────
class ExamListState {
  final List<ExamModel> items;
  final bool    loading;
  final String? error;
  final String? filterStatus;

  const ExamListState({
    this.items        = const [],
    this.loading      = false,
    this.error,
    this.filterStatus,
  });

  ExamListState copyWith({
    List<ExamModel>? items,
    bool?    loading,
    String?  error,
    String?  filterStatus,
  }) => ExamListState(
    items:        items        ?? this.items,
    loading:      loading      ?? this.loading,
    error:        error,
    filterStatus: filterStatus ?? this.filterStatus,
  );
}

class ExamListNotifier extends StateNotifier<ExamListState> {
  ExamListNotifier(this._repo) : super(const ExamListState());

  final GuruRepository _repo;

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final raw = await _repo.getExams(status: state.filterStatus);
      final items = ((raw['data'] as List?) ?? []).map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setFilter(String? status) {
    state = state.copyWith(filterStatus: status);
    fetch();
  }

  Future<void> activate(int id) async {
    await _repo.updateExam(id, {'status': 'active'});
    await fetch();
  }

  Future<void> pause(int id) async {
    await _repo.pauseExam(id);
    await fetch();
  }

  Future<void> end(int id) async {
    await _repo.endExam(id);
    await fetch();
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _repo.createExam(payload);
    await fetch();
  }
}

final examListProvider = StateNotifierProvider.autoDispose<ExamListNotifier, ExamListState>((ref) {
  final repo = ref.watch(guruRepoProvider);
  return ExamListNotifier(repo)..fetch();
});

// ── Classes ───────────────────────────────────────────
class KelasState {
  final List<ClassRoomModel> items;
  final bool    loading;
  final String? error;
  final ClassRoomModel? selected;

  const KelasState({
    this.items    = const [],
    this.loading  = false,
    this.error,
    this.selected,
  });

  KelasState copyWith({
    List<ClassRoomModel>? items,
    bool?    loading,
    String?  error,
    ClassRoomModel? selected,
  }) => KelasState(
    items:    items    ?? this.items,
    loading:  loading  ?? this.loading,
    error:    error,
    selected: selected ?? this.selected,
  );
}

class KelasNotifier extends StateNotifier<KelasState> {
  KelasNotifier(this._repo) : super(const KelasState());

  final GuruRepository _repo;

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await _repo.getClasses();
      state = state.copyWith(items: results, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void selectKelas(ClassRoomModel? k) {
    state = state.copyWith(selected: k);
  }
}

final kelasProvider = StateNotifierProvider.autoDispose<KelasNotifier, KelasState>((ref) {
  final repo = ref.watch(guruRepoProvider);
  return KelasNotifier(repo)..fetch();
});

// ── Violations ────────────────────────────────────────
final violationProvider = FutureProvider.autoDispose<List<ViolationModel>>((ref) {
  return ref.watch(guruRepoProvider).getViolations();
});

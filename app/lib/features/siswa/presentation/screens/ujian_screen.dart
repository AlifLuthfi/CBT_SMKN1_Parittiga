import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/security/lcg_randomizer.dart';
import '../../../../core/security/anti_cheat_service.dart';
import '../../../../core/security/exam_alarm_service.dart';
import '../../../../core/security/windows_anti_cheat.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/siswa_models.dart';
import '../../data/siswa_repository.dart';

final _ujianRepoProvider = Provider((_) => SiswaRepository());

class UjianScreen extends ConsumerStatefulWidget {
  final int examId;
  const UjianScreen({super.key, required this.examId});
  @override
  ConsumerState<UjianScreen> createState() => _UjianScreenState();
}

class _UjianScreenState extends ConsumerState<UjianScreen> with WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────
  SiswaExamModel?      _exam;
  ExamSessionData?     _session;
  List<ExamQuestion>   _questions     = [];
  Map<int, String>     _answers       = {};
  Set<int>             _flagged       = {};
  int                  _currentIndex  = 0;
  int                  _secondsLeft   = 0;
  int                  _totalSeconds  = 0;   // total exam duration
  int                  _timeElapsed   = 0;   // elapsed before current tick window
  DateTime?            _timerStartedAt;      // when current timer window started
  int                  _violCount     = 0;
  String?              _alarmPin;                        // NIS siswa - PIN untuk matikan alarm
  bool                 _alarmTriggered = false;           // alarm sedang berbunyi
  int                  _seed          = 0;
  Timer?               _timer;
  Timer?               _autoSaveTimer;
  Timer?               _bulkSyncTimer;
  Timer?               _fullscreenEnforcer;
  Timer?               _periodicCheckTimer;
  Timer?               _saveDebounce;
  bool                 _bulkSyncing = false;
  bool                 _loading       = true;
  bool                 _submitting    = false;
  String?              _error;
  String               _phase         = 'biodata'; // biodata | ujian | result

  // Biodata form
  final _namaCtrl  = TextEditingController();
  final _nisCtrl   = TextEditingController();
  final _kelasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _bulkSyncTimer?.cancel();
    _fullscreenEnforcer?.cancel();
    _periodicCheckTimer?.cancel();
    _saveDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ExamAlarmService.stopAlarm();
    AntiCheatService.exitLockTask();
    AntiCheatService.disableKeyboardBlock();
    WindowsAntiCheat.unlock();
    AntiCheatService.disableSecureFlag();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values); // reset
    _namaCtrl.dispose();
    _nisCtrl.dispose();
    _kelasCtrl.dispose();
    super.dispose();
  }

  // ── Multi-window / split-screen detection ──────────
  bool _wasInMultiWindow = false;

  Future<void> _checkMultiWindow() async {
    if (!mounted || _phase != 'ujian') return;
    final isMulti = await AntiCheatService.isInMultiWindow();
    if (isMulti && !_wasInMultiWindow) {
      _wasInMultiWindow = true;
      _recordViolation('split_screen');
    } else if (!isMulti && _wasInMultiWindow) {
      _wasInMultiWindow = false;
    }
  }

  Future<void> _checkScreenRecording() async {
    if (!mounted || _phase != 'ujian') return;
    final recording = await AntiCheatService.isScreenRecording();
    if (recording) {
      _recordViolation('screen_record');
    }
  }

  // ── Anti-cheat: detect app background ─────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_phase != 'ujian') return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Record elapsed so far before pause
      if (_timerStartedAt != null) {
        _timeElapsed += DateTime.now().difference(_timerStartedAt!).inSeconds;
        _timerStartedAt = null;
      }
      _timer?.cancel();
      _recordViolation('blur');
      _triggerAlarm();
    } else if (state == AppLifecycleState.resumed) {
      // Enforce fullscreen SEKARANG, bukan nunggu tick 500ms
      _enterImmersiveMode();
      AntiCheatService.enterLockTask();
      WindowsAntiCheat.lock();
      // Restart timer LOCAL dulu biar ga freeze — server sync sebagai koreksi
      if (_secondsLeft > 0) {
        _startTimer();
      }
      // Server sync background
      _syncTimerFromServer();
      _checkMultiWindow();
      _checkScreenRecording();
      if (_alarmTriggered) {
        _showAlarmUnlockDialog();
      }
    }
  }

  Future<void> _triggerAlarm() async {
    if (_alarmTriggered) return;
    _alarmTriggered = true;
    ExamAlarmService.startAlarm();
    if (mounted) _showAlarmUnlockDialog();
  }

  // ── Init exam ─────────────────────────────────────────
  Future<void> _initExam() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(_ujianRepoProvider);
      final exam = await repo.getExamDetail(widget.examId);

      // Cek sesi tersimpan (resume setelah restart)
      final saved = await SecureStorage.getExamSession();
      if (saved != null && saved['examId'] == widget.examId) {
        final savedAt  = DateTime.tryParse(saved['savedAt'] as String? ?? '');
        final elapsed  = savedAt != null ? DateTime.now().difference(savedAt).inSeconds : 0;
        final remaining= ((saved['secondsLeft'] as int? ?? 0) - elapsed);
        if (remaining > 30) {
          final user = await SecureStorage.getUser();
          _namaCtrl.text  = saved['student']?['nama'] as String? ?? user?['name'] as String? ?? '';
          _nisCtrl.text   = saved['student']?['nis']  as String? ?? user?['nis']  as String? ?? '';
          _kelasCtrl.text = saved['student']?['kelas'] as String? ?? '';
          _totalSeconds = saved['totalSeconds'] as int? ?? exam.durationMinutes * 60;
          setState(() {
            _exam        = exam;
            _answers     = (saved['answers'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k.toString()), v.toString()));
            _flagged     = Set<int>.from((saved['flagged'] as List? ?? []).map((e) => e as int));
            _currentIndex= saved['currentIndex'] as int? ?? 0;
            _secondsLeft = remaining;
            _timeElapsed = saved['timeElapsed'] as int? ?? (_totalSeconds - remaining);
            _seed        = saved['seed'] as int? ?? 0;
            _loading     = false;
          });
          // _randomizer not needed — LCG done server-side
          _showResumeSnackbar();
          // Validasi waktu dari server setelah restore (jangan start timer — masih biodata)
          _syncTimerFromServer(startTimers: false);
          return;
        }
      }

      // Prefill biodata dari sistem
      final user      = await SecureStorage.getUser();
      _namaCtrl.text  = user?['name'] as String? ?? '';
      _nisCtrl.text   = user?['nis']  as String? ?? '';
      _kelasCtrl.text = exam.className;

      setState(() { _exam = exam; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showResumeSnackbar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Sesi ujian ditemukan — ketuk Lanjutkan Ujian'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ));
    });
  }

  // ── Mulai ujian dari biodata ──────────────────────────
  Future<void> _startUjian() async {
    // Identitas sudah diisi otomatis dari sistem, tidak perlu validasi

    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(_ujianRepoProvider);

      // Generate seed lokal untuk verifikasi
      final localSeed = ExamRandomizer.generateSeed();
      final lcgVerify = ExamRandomizer(localSeed).verifySeed(5);

      final result = await repo.startExam(widget.examId, lcgVerify: lcgVerify);
      _session = result.session;

      // Gunakan seed dari server (authoritative)
      _seed       = _session!.seed;
      // LCG done server-side, raw questions already shuffled

      // Build ExamQuestion dari data server
      final rawQuestions = _session!.questions.map((q) => ExamQuestion.fromJson(q)).toList();

      // Soal dan opsi sudah diacak oleh backend per sesi / seed
      _questions = rawQuestions;

      // Restore jawaban jika resume
      if (result.isResumed) {
        _answers     = Map<int, String>.from(_session!.savedAnswers);
        _secondsLeft = _session!.remainingSeconds;
      } else {
        _answers     = {};
        _totalSeconds = _exam!.durationMinutes * 60;
        _secondsLeft  = _session!.remainingSeconds > 0 ? _session!.remainingSeconds : _totalSeconds;
      }

      _flagged       = {};
      _currentIndex  = 0;
      _violCount     = 0;
      _alarmPin      = _nisCtrl.text.isNotEmpty ? _nisCtrl.text : null;
      _alarmTriggered = false;

      // Wall-clock anchor
      _timeElapsed    = _totalSeconds - _secondsLeft;
      _timerStartedAt = null;

      await _saveSession();
      setState(() { _loading = false; _phase = 'ujian'; });

      // Sistem ujian — fullscreen paksa + lock task (kiosk)
      WakelockPlus.enable();
      AntiCheatService.enterLockTask();
      _enterImmersiveMode();
      WindowsAntiCheat.lock();
      AntiCheatService.enableSecureFlag();
      AntiCheatService.enableKeyboardBlock();
      // Multi-window listener
      AntiCheatService.onMultiWindowChanged((isMulti) {
        if (isMulti && _phase == 'ujian') _recordViolation('split_screen');
      });
      // Aggressive enforcer — burst 50ms first 2s, then 150ms untuk respon cepat
      int burstCount = 0;
      _fullscreenEnforcer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (_phase != 'ujian') return;
        _enterImmersiveMode();
        AntiCheatService.enterLockTask();
        WindowsAntiCheat.lock();
        burstCount++;
        if (burstCount >= 40) {
          // switch ke 150ms setelah ~2s burst
          _fullscreenEnforcer?.cancel();
          _fullscreenEnforcer = Timer.periodic(const Duration(milliseconds: 150), (_) {
            if (_phase != 'ujian') return;
            _enterImmersiveMode();
            AntiCheatService.enterLockTask();
          });
        }
      });
      _startTimer();
      _startAutoSave();
      // Periodic checks — simpan ref biar bisa dicancel di dispose
      _periodicCheckTimer?.cancel();
      _periodicCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkMultiWindow();
        _checkScreenRecording();
      });
      // Koreksi timer dari server setelah start (untuk resume case)
      if (result.isResumed) {
        _syncTimerFromServer();
      }

    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _startTimer() {
    _timerStartedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final wallElapsed = _timeElapsed + DateTime.now().difference(_timerStartedAt!).inSeconds;
      final remaining = _totalSeconds - wallElapsed;
      if (remaining <= 0) {
        _timer?.cancel();
        _autoSaveTimer?.cancel();
        setState(() => _secondsLeft = 0);
        _autoSubmit();
        return;
      }
      setState(() => _secondsLeft = remaining);
    });
  }

  Future<void> _syncTimerFromServer({bool startTimers = true}) async {
    if (_session == null) return;
    try {
      final repo = ref.read(_ujianRepoProvider);
      final state = await repo.getSessionState(_session!.sessionId);
      if (state != null) {
        setState(() {
          _secondsLeft = state.remainingSeconds;
          _timeElapsed = _totalSeconds - state.remainingSeconds;
          _timerStartedAt = null;
        });
        if (startTimers && _secondsLeft > 0) {
          // restart timer with corrected anchor
          _startTimer();
          _autoSaveTimer?.cancel();
          _bulkSyncTimer?.cancel();
          _startAutoSave();
        }
      }
    } catch (_) {
      // Server unreachable — local timer still running, fine
    }
    if (_secondsLeft <= 0) {
      _autoSubmit();
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveSession(),
    );
    // Periodic bulk sync to server every 60s
    _bulkSyncTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) async {
        if (_session == null || _answers.isEmpty || _bulkSyncing) return;
        _bulkSyncing = true;
        await ref.read(_ujianRepoProvider).bulkSaveAnswers(_session!.sessionId, _answers.cast<int, String?>());
        _bulkSyncing = false;
      },
    );
  }

  Future<void> _saveSession() async {
    if (_session == null || _seed == 0) return;
    final elapsed = _timeElapsed +
        (_timerStartedAt != null ? DateTime.now().difference(_timerStartedAt!).inSeconds : 0);
    await SecureStorage.saveExamSession({
      'examId':       widget.examId,
      'sessionId':    _session!.sessionId,
      'seed':         _seed,
      'student':      {'nama': _namaCtrl.text, 'nis': _nisCtrl.text, 'kelas': _kelasCtrl.text},
      'answers':      Map<String, String>.from(_answers.map((k, v) => MapEntry(k.toString(), v))),
      'flagged':      List<int>.from(_flagged),
      'currentIndex': _currentIndex,
      'secondsLeft':  _secondsLeft,
      'totalSeconds': _totalSeconds,
      'timeElapsed':  elapsed,
      'savedAt':      DateTime.now().toIso8601String(),
    });
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveSession);
  }

  void _selectAnswer(int questionId, String key) {
    setState(() => _answers[questionId] = key);
    _scheduleSave();
    if (_session != null) {
      ref.read(_ujianRepoProvider).saveAnswer(_session!.sessionId, questionId, key);
    }
  }

  void _toggleFlag(int questionId) {
    setState(() {
      if (_flagged.contains(questionId)) _flagged.remove(questionId);
      else _flagged.add(questionId);
    });
  }

  void _recordViolation(String type) {
    setState(() => _violCount++);
    final max = _exam?.maxViolations ?? 5;
    if (_session != null) {
      ref.read(_ujianRepoProvider).recordViolation(_session!.sessionId, type);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠ Pelanggaran terdeteksi! ($_violCount/$max)'),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
      ));
    }
    if (_violCount >= max) _autoSubmit();
  }

  Future<void> _autoSubmit() async {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _bulkSyncTimer?.cancel();
    _fullscreenEnforcer?.cancel();
    _periodicCheckTimer?.cancel();
    await ExamAlarmService.stopAlarm();
    await _doSubmit(auto: true);
  }

  Future<void> _doSubmit({bool auto = false}) async {
    if (_session == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ExamAlarmService.stopAlarm();
      AntiCheatService.exitLockTask();
      AntiCheatService.disableKeyboardBlock();
      // Bulk save semua jawaban sebelum submit
      await ref.read(_ujianRepoProvider).bulkSaveAnswers(_session!.sessionId, _answers.cast<int, String?>());
      final result = await ref.read(_ujianRepoProvider).submitExam(_session!.sessionId);
      await SecureStorage.clearExamSession();
      WindowsAntiCheat.unlock();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      WakelockPlus.disable();
      if (mounted) {
        context.pushReplacement('/siswa/result/${_session!.sessionId}', extra: result);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red));
      }
    }
  }

  String _formatTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${ss.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${ss.toString().padLeft(2,'0')}';
  }

  // ── ALARM UNLOCK DIALOG ────────────────────────────────
  bool _unlockDialogOpen = false;

  Future<void> _showAlarmUnlockDialog() async {
    if (_unlockDialogOpen || !mounted) return;
    _unlockDialogOpen = true;

    final pwCtrl = TextEditingController();
    var busy = false;
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void tryUnlock() {
            final pin = pwCtrl.text;
            if (pin.isEmpty || busy) return;
            busy = true;
            errorText = null;
            setDialogState(() {});
            // Async unlock
            Future.microtask(() async {
              if (pin == _alarmPin) {
                await ExamAlarmService.stopAlarm();
                if (ctx.mounted) {
                  setDialogState(() {});
                  Navigator.pop(ctx, true);
                }
              } else {
                _recordViolation('wrong_password');
                if (ctx.mounted) {
                  busy = false;
                  errorText = 'NIS salah! Alarm tetap berbunyi.';
                  setDialogState(() {});
                }
              }
            });
          }

          return AlertDialog(
            title: const Row(children: [
              Icon(Icons.alarm_on, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text('Alarm Keamanan'),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, size: 56, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Anda meninggalkan layar ujian!\nAlarm akan berbunyi terus sampai dimatikan.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text('Masukkan NIS Anda untuk mematikan alarm:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                controller: pwCtrl,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'NIS',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.go,
                enabled: !busy,
                onSubmitted: (_) => tryUnlock(),
              ),
              if (busy) const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx, false),
                child: const Text('Kembali ke Ujian'),
              ),
              ElevatedButton.icon(
                onPressed: busy ? null : tryUnlock,
                icon: const Icon(Icons.volume_up, size: 16),
                label: const Text('Matikan Alarm'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );

    _unlockDialogOpen = false;
    pwCtrl.dispose();

    if (!mounted) return;
    if (result != true && _phase == 'ujian') {
      final playing = await ExamAlarmService.isAlarmPlaying();
      if (playing && mounted && _phase == 'ujian') {
        _showAlarmUnlockDialog();
      }
    }
  }

  // ── PASSWORD EXIT DIALOG ──────────────────────────────
  bool _exitDialogOpen = false;

  Future<bool> _onWillPop() async {
    if (_phase != 'ujian' || _exitDialogOpen) return false;
    _exitDialogOpen = true;

    final pwCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.lock_outline, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Akses Terkunci'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Masukkan password admin/guru untuk keluar dari ujian:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: pwCtrl,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) {
              if (pwCtrl.text.isNotEmpty) Navigator.pop(ctx, true);
            },
          ),
          const SizedBox(height: 8),
          Text('Catatan: Keluar tanpa password akan dicatat sebagai pelanggaran',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (pwCtrl.text.isNotEmpty) Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Verifikasi & Keluar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    _exitDialogOpen = false;
    final password = pwCtrl.text;
    pwCtrl.dispose();

    if (confirmed == true && password.isNotEmpty) {
      await _verifyExitPassword(password);
    }

    return false; // never allow direct pop
  }

  Future<void> _verifyExitPassword(String password) async {
    try {
      final repo = ref.read(_ujianRepoProvider);
      final result = await repo.verifyExitPassword(
        _session!.sessionId,
        password,
      );
      if (result['valid'] == true) {
        // Password benar — stop alarm + auto-submit ujian
        await ExamAlarmService.stopAlarm();
        AntiCheatService.exitLockTask();
        AntiCheatService.disableKeyboardBlock();
        await SecureStorage.clearExamSession();
        WindowsAntiCheat.unlock();
        AntiCheatService.disableSecureFlag();
        WakelockPlus.disable();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        if (result['submitted'] == true && mounted) {
          final res = ExamResultModel.fromJson(result['result'] as Map<String, dynamic>);
          context.pushReplacement('/siswa/result/${_session!.sessionId}', extra: res);
        } else if (mounted) {
          context.go('/siswa');
        }
      } else {
        // Salah — catat violation
        _recordViolation('wrong_password');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password salah! Pelanggaran dicatat.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (_) {
      // Offline fallback — masih catat violation
      _recordViolation('wrong_password');
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: ErrorState(message: _error!, onRetry: _initExam));
    if (_phase == 'biodata') return _buildBiodata();
    if (_phase == 'ujian')   return _buildUjian();
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // ── BIODATA SCREEN ────────────────────────────────────
  Widget _buildBiodata() => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(13))),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha:.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.assignment, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_exam?.title ?? 'Ujian', style: AppTextStyles.h4.copyWith(color: Colors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('${_exam?.subject} · ${_exam?.className}', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
              ])),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Exam info
            Row(children: [
              _infoBox('Durasi', '${_exam?.durationMinutes ?? 0} mnt'),
              const SizedBox(width: 8),
              _infoBox('Soal', '${_exam?.totalQuestions ?? 0}'),
              const SizedBox(width: 8),
              _infoBox('KKM', '${_exam?.passingGrade.toInt() ?? 70}'),
            ]),
            const SizedBox(height: 18),
            Text('IDENTITAS PESERTA', style: AppTextStyles.label),
            const SizedBox(height: 8),
            _readOnlyField(Icons.person_outline, 'Nama Lengkap', _namaCtrl.text),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _readOnlyField(Icons.badge_outlined, 'NIS', _nisCtrl.text)),
              const SizedBox(width: 10),
              Expanded(child: _readOnlyField(Icons.class_outlined, 'Kelas', _kelasCtrl.text)),
            ]),
            const SizedBox(height: 16),
            // Peraturan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.amber.withValues(alpha:.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFF92400E)), const SizedBox(width: 6), Text('Peraturan Ujian', style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF92400E), fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                ...['Dilarang berpindah aplikasi selama ujian','Setiap pelanggaran akan dicatat','Ujian otomatis dikumpul saat waktu habis','Sesi tersimpan otomatis jika terjadi gangguan',
                    _exam?.randomizeQuestions == true ? 'Urutan soal diacak per siswa (LCG)' : 'Urutan soal tetap',
                ].map((r) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(children: [
                  Container(width: 4, height: 4, margin: const EdgeInsets.only(right: 8, top: 5), decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                  Expanded(child: Text(r, style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF78350F), fontSize: 11.5))),
                ]))),
              ]),
            ),
            const SizedBox(height: 18),
            AppButton(
              label:      _answers.isNotEmpty ? 'Lanjutkan Ujian' : 'Mulai Ujian',
              onPressed:  _startUjian,
              loading:    _loading,
              icon:       Icons.play_arrow,
            ),
          ])),
        ]),
      ),
    ]))),
  );

  Widget _readOnlyField(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.navy),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5, color: AppColors.ink3)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 14)),
      ])),
    ]),
  );

  Widget _infoBox(String label, String value) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text(value, style: AppTextStyles.mono.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
    ]),
  ));

  // ── UJIAN SCREEN ──────────────────────────────────────
  Widget _buildUjian() {
    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text('Tidak ada soal')));
    final q           = _questions[_currentIndex];
    final answered    = _answers[q.id];
    final isFlagged   = _flagged.contains(q.id);
    final total       = _questions.length;
    final isWarning   = _secondsLeft <= 300;
    final isDanger    = _secondsLeft <= 60;
    final timerColor  = isDanger ? AppColors.red : isWarning ? AppColors.amber : AppColors.navy;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _phase != 'ujian') return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          title: Text(_exam?.title ?? 'Ujian', style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDanger ? AppColors.redLight : isWarning ? AppColors.amberLight : AppColors.navyLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_outlined, size: 13, color: timerColor),
              const SizedBox(width: 4),
              Text(_formatTime(_secondsLeft > 0 ? _secondsLeft : 0), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15, fontWeight: FontWeight.w700, color: timerColor)),
            ]),
          ),
        ],
      ),
      body: Stack(children: [
        Column(children: [
        // Progress
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(14, 8, 14, 10), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Soal ${_currentIndex + 1} / $total', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600)),
            Text('${_answers.length} dijawab', style: AppTextStyles.bodySmall),
          ]),
          const SizedBox(height: 5),
          ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: (_currentIndex + 1) / total, backgroundColor: AppColors.border, color: AppColors.navy, minHeight: 4)),
        ])),

        // Question
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
              child: Text('Soal ${_currentIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            // difficulty removed
            if (_seed != 0) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Text('LCG', style: AppTextStyles.bodySmall.copyWith(fontSize: 9, fontFamily: 'JetBrainsMono'))),
            ],
          ]),
          const SizedBox(height: 12),
          Text(q.questionText, style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.7)),
          if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(AppConstants.resolveImageUrl(q.imageUrl)!, height: 180, width: double.infinity, fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                loadingBuilder: (_, child, progress) => progress == null ? child : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            ),
          ],
          const SizedBox(height: 16),

          if (q.options != null)
            ...q.options!.entries.map((entry) {
              final isSelected = answered == entry.key;
              return GestureDetector(
                onTap: () => _selectAnswer(q.id, entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        isSelected ? AppColors.navyLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: isSelected ? AppColors.navy : AppColors.border, width: isSelected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.navy : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: isSelected ? AppColors.navy : AppColors.border2, width: 1.5),
                      ),
                      child: Center(child: Text(entry.key, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.ink3))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value, style: AppTextStyles.body.copyWith(color: isSelected ? AppColors.navy : AppColors.ink2))),
                    if (isSelected) Icon(Icons.check_circle, size: 16, color: AppColors.navy),
                  ]),
                ),
              );
            }),
        ]))),

        // Bottom navigation
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
          child: Column(children: [
            // Question grid navigator
            SizedBox(height: 40, child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: total,
              itemBuilder: (_, i) {
                final qId       = _questions[i].id;
                final isAns     = _answers.containsKey(qId);
                final isCur     = i == _currentIndex;
                final isFlag    = _flagged.contains(qId);
                Color bg = AppColors.bg, bd = AppColors.border;
                Color tx = AppColors.ink3;
                if (isCur)       { bg = AppColors.navy; bd = AppColors.navy; tx = Colors.white; }
                else if (isFlag) { bg = AppColors.amberLight; bd = AppColors.amber; tx = const Color(0xFF92400E); }
                else if (isAns)  { bg = AppColors.navyLight; bd = AppColors.navy.withValues(alpha:.3); tx = AppColors.navy; }
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 34, margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7), border: Border.all(color: bd)),
                    child: Center(child: Text('${i+1}', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: tx))),
                  ),
                );
              },
            )),
            const SizedBox(height: 10),
            Row(children: [
              IconButton(
                onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(backgroundColor: AppColors.bg, foregroundColor: AppColors.ink2),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _toggleFlag(q.id),
                icon: Icon(isFlagged ? Icons.flag : Icons.flag_outlined, size: 14),
                label: Text(isFlagged ? 'Ditandai' : 'Tandai'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.amber,
                  side: BorderSide(color: AppColors.amber.withValues(alpha:.5)),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const Spacer(),
              _currentIndex < total - 1
                  ? ElevatedButton.icon(
                      onPressed: () => setState(() => _currentIndex++),
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('Berikutnya'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    )
                  : ElevatedButton.icon(
                      onPressed: _showSubmitDialog,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Selesai'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    ),
            ]),
          ]),
        ),
      ]),
        if (_submitting)
          Container(
            color: Colors.black38,
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text('Mengumpulkan...', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
      ]),
    ));
  }

  // unused — dipertahankan untuk referensi, hapus kalau mau
  // Widget _diffBadge(String diff) {
  //   final map = {'easy': (AppColors.green, AppColors.greenLight, 'Mudah'), 'medium': (AppColors.amber, AppColors.amberLight, 'Sedang'), 'hard': (AppColors.red, AppColors.redLight, 'Sulit')};
  //   final e = map[diff] ?? (AppColors.ink3, AppColors.bg, diff);
  //   return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  //     decoration: BoxDecoration(color: e.$2, borderRadius: BorderRadius.circular(20)),
  //     child: Text(e.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: e.$1)));
  // }

  void _showSubmitDialog() {
    final total     = _questions.length;
    final answered  = _answers.length;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Kumpulkan Ujian?'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _dialogRow('Dijawab',      '$answered',              AppColors.green),
        _dialogRow('Belum Dijawab','${total - answered}',   AppColors.amber),
        _dialogRow('Ditandai',     '${_flagged.length}',    AppColors.orange),
        _dialogRow('Sisa Waktu',   _formatTime(_secondsLeft), AppColors.navy),
        const SizedBox(height: 10),
        Text('Jawaban tidak dapat diubah setelah dikumpulkan.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Periksa Lagi')),
        ElevatedButton(
          onPressed: _submitting ? null : () { Navigator.pop(context); _doSubmit(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, minimumSize: const Size(0, 0), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Ya, Kumpulkan'),
        ),
      ],
    ));
  }

  Widget _dialogRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.body),
      Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700, color: color, fontSize: 15)),
    ]),
  );
}

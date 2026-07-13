<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exam;
use App\Models\ExamSession;
use App\Models\ExamSessionAnswer;
use App\Services\ExamRandomizationService;
use App\Services\GradingService;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class StudentExamController extends Controller
{
    public function __construct(
        private ExamRandomizationService $randomizer,
        private GradingService           $grading,
        private NotificationService      $notif
    ) {}

    /* ── List ujian yang tersedia ───────────────────────── */
    public function index(Request $request)
    {
        $student  = $request->user();
        $classIds = $student->enrolledClasses()->pluck('classes.id');

        $exams = Exam::whereIn('class_id', $classIds)
            ->where('status', 'active')
            ->with(['classRoom', 'teacher'])
            ->get()
            ->map(function (Exam $exam) use ($student) {
                $session = ExamSession::where('exam_id', $exam->id)
                    ->where('student_id', $student->id)->first();
                return array_merge($exam->toArray(), [
                    'session_status' => $session?->status,
                    'session_id'     => $session?->id,
                    'can_start'      => !$session || $session->status === 'in_progress',
                ]);
            });

        return response()->json(['data' => $exams]);
    }

    /* ── Detail ujian ────────────────────────────────────── */
    public function show(Request $request, Exam $exam)
    {
        $student  = $request->user();
        $enrolled = $student->enrolledClasses()
            ->where('classes.id', $exam->class_id)->wherePivot('status', 'active')->exists();

        if (!$enrolled)          return response()->json(['message' => 'Tidak terdaftar di kelas ini.'], 403);
        if ($exam->status !== 'active') {
            $msgs = ['draft'=>'Belum dijadwalkan.','scheduled'=>'Belum dimulai.','paused'=>'Dijeda guru.','ended'=>'Sudah berakhir.'];
            return response()->json(['message' => $msgs[$exam->status] ?? 'Tidak tersedia.'], 403);
        }

        return response()->json(['exam' => [
            'id'                      => $exam->id,
            'title'                   => $exam->title,
            'subject'                 => $exam->classRoom->subject,
            'class_name'              => $exam->classRoom->name,
            'duration_minutes'        => $exam->duration_minutes,
            'passing_grade'           => $exam->passing_grade,
            'total_questions'         => $exam->total_questions,
            'max_violations'          => $exam->max_violations,
            'start_time'              => $exam->start_time?->toIso8601String(),
            'end_time'                => $exam->end_time?->toIso8601String(),
            'randomize_questions'     => $exam->randomize_questions,
            'randomize_options'       => $exam->randomize_options,
            'show_result_immediately' => $exam->show_result_immediately,
        ]]);
    }

    /* ── Mulai / lanjutkan ujian ─────────────────────────── */
    public function startExam(Request $request, Exam $exam)
    {
        $student  = $request->user();
        $enrolled = $student->enrolledClasses()
            ->where('classes.id', $exam->class_id)->wherePivot('status', 'active')->exists();

        if (!$enrolled)          return response()->json(['message' => 'Tidak terdaftar.'], 403);
        if ($exam->status !== 'active') return response()->json(['message' => 'Ujian tidak aktif.'], 403);

        // Cek sesi aktif — lanjutkan dengan seed & urutan SAMA
        $existingSession = ExamSession::where('exam_id', $exam->id)
            ->where('student_id', $student->id)->where('status', 'in_progress')->first();

        $isResumed = false;

        if ($existingSession) {
            $isResumed = true;
            // Hitung sisa waktu terkini
            $elapsed   = now()->diffInSeconds($existingSession->started_at);
            $extSeconds= $existingSession->extensions()->sum('minutes') * 60;
            $total     = ($exam->duration_minutes * 60) + $extSeconds;
            $remaining = max(0, $total - $elapsed);
            $existingSession->update(['remaining_seconds' => (int) $remaining, 'last_activity_at' => now()]);
            $session   = $existingSession;
        } else {
            // Buat sesi baru — seed unik per siswa, soal diacak LCG
            $session = $this->randomizer->createSession($exam, $student->id);
        }

        // Verifikasi konsistensi seed jika frontend mengirim verify data
        if ($request->has('lcg_verify')) {
            $consistent = $this->randomizer->verifySeedConsistency(
                $session->seed,
                $request->lcg_verify
            );
            if (!$consistent) {
                \Log::warning('LCG seed mismatch', [
                    'session_id' => $session->id,
                    'seed'       => $session->seed,
                    'frontend'   => $request->lcg_verify,
                    'backend'    => $this->randomizer->verify($session->seed, count($request->lcg_verify)),
                ]);
            }
        }

        // Build soal yang sudah diacak (tanpa correct_answer)
        $questions = $this->randomizer->buildShuffledQuestions($exam, $session);

        // Jawaban yang sudah tersimpan (untuk resume)
        $savedAnswers = $isResumed
            ? $session->answers()->pluck('answer', 'question_id')
            : collect([]);

        return response()->json([
            'message'    => $isResumed ? 'Melanjutkan sesi.' : 'Ujian dimulai.',
            'is_resumed' => $isResumed,
            'session'    => [
                'session_id'        => $session->id,
                'exam_id'           => $exam->id,
                'seed'              => $session->seed,
                'status'            => $session->status,
                'remaining_seconds' => (int) $session->remaining_seconds,
                'started_at'        => $session->started_at,
                'questions'         => $questions,
                'saved_answers'     => $savedAnswers,
            ],
        ], $isResumed ? 200 : 201);
    }

    /* ── Simpan satu jawaban ─────────────────────────────── */
    public function saveAnswer(Request $request, ExamSession $session)
    {
        $this->authorizeSession($request, $session);
        if ($session->status !== 'in_progress') {
            return response()->json(['message' => 'Sesi sudah berakhir.'], 403);
        }

        // Cek waktu habis
        $elapsed   = now()->diffInSeconds($session->started_at);
        $total     = ($session->exam->duration_minutes * 60) + $session->extensions()->sum('minutes') * 60;
        $remaining = max(0, $total - $elapsed);

        if ($remaining <= 0) {
            $session->update(['status' => 'timeout', 'submitted_at' => now()]);
            $this->grading->gradeSession($session);
            return response()->json(['message' => 'Waktu habis. Ujian dikumpulkan.', 'auto_submitted' => true], 403);
        }

        $data = $request->validate([
            'question_id' => 'required|exists:questions,id',
            'answer'      => 'nullable|string|max:10',
        ]);

        ExamSessionAnswer::updateOrCreate(
            ['session_id' => $session->id, 'question_id' => $data['question_id']],
            ['answer'     => $data['answer']]
        );

        $session->update(['last_activity_at' => now(), 'remaining_seconds' => (int) $remaining]);

        return response()->json(['message' => 'Jawaban disimpan.', 'remaining_seconds' => (int) $remaining]);
    }

    /* ── Simpan banyak jawaban sekaligus ─────────────────── */
    public function bulkSaveAnswers(Request $request, ExamSession $session)
    {
        $this->authorizeSession($request, $session);
        if ($session->status !== 'in_progress') {
            return response()->json(['message' => 'Sesi sudah berakhir.'], 403);
        }

        $data = $request->validate([
            'answers'               => 'required|array',
            'answers.*.question_id' => 'required|exists:questions,id',
            'answers.*.answer'      => 'nullable|string|max:10',
        ]);

        foreach ($data['answers'] as $ans) {
            ExamSessionAnswer::updateOrCreate(
                ['session_id' => $session->id, 'question_id' => $ans['question_id']],
                ['answer'     => $ans['answer']]
            );
        }

        $session->update(['last_activity_at' => now()]);

        return response()->json(['message' => count($data['answers']) . ' jawaban disimpan.']);
    }

    /* ── Submit ujian ────────────────────────────────────── */
    public function submit(Request $request, ExamSession $session)
    {
        $this->authorizeSession($request, $session);
        if ($session->status !== 'in_progress') {
            return response()->json(['message' => 'Sesi sudah dikumpulkan.'], 422);
        }

        // Grade menggunakan LCG seed untuk decode jawaban
        $graded = $this->grading->gradeSession($session);
        $result = $this->grading->getSessionResult($graded);

        $this->notif->notifyStudentSubmit($graded);

        \App\Models\ActivityLog::create([
            'user_id'     => $request->user()->id,
            'action'      => 'student_submit',
            'description' => "{$request->user()->name} submit {$session->exam->title}",
        ]);

        return response()->json(['message' => 'Ujian berhasil dikumpulkan.', 'result' => $result]);
    }

    /* ── Hasil ujian ─────────────────────────────────────── */
    public function result(Request $request, ExamSession $session)
    {
        $this->authorizeSession($request, $session);
        if ($session->status === 'in_progress') {
            return response()->json(['message' => 'Ujian belum dikumpulkan.'], 422);
        }
        return response()->json(['result' => $this->grading->getSessionResult($session)]);
    }

    /* ── Ambil state sesi — fallback jika Flutter kehilangan data lokal ─── */
    public function getState(Request $request, ExamSession $session)
    {
        $this->authorizeSession($request, $session);

        if ($session->status !== 'in_progress') {
            return response()->json(['message' => 'Sesi tidak aktif.'], 422);
        }

        $elapsed    = now()->diffInSeconds($session->started_at);
        $extSeconds = $session->extensions()->sum('minutes') * 60;
        $total      = ($session->exam->duration_minutes * 60) + $extSeconds;
        $remaining  = max(0, $total - $elapsed);

        $questions    = $this->randomizer->buildShuffledQuestions($session->exam, $session);
        $savedAnswers = $session->answers()->pluck('answer', 'question_id');

        return response()->json([
            'session' => [
                'session_id'        => $session->id,
                'exam_id'           => $session->exam_id,
                'seed'              => $session->seed,
                'status'            => $session->status,
                'remaining_seconds' => (int) $remaining,
                'started_at'        => $session->started_at,
                'questions'         => $questions,
                'saved_answers'     => $savedAnswers,
            ],
        ]);
    }

    /* ── Riwayat ujian siswa ─────────────────────────────── */
    public function history(Request $request)
    {
        $student = $request->user();
        $sessions = ExamSession::where('student_id', $student->id)
            ->whereIn('status', ['submitted', 'timeout', 'force_submitted'])
            ->with('exam.classRoom')
            ->orderByDesc('submitted_at')
            ->get()
            ->map(function ($s) {
                $exam = $s->exam;
                return [
                    'id'             => $s->id,
                    'exam'           => $exam ? $exam->toArray() : null,
                    'submitted_at'   => $s->submitted_at,
                    'status'         => $s->status,
                    'score'          => $s->score,
                    'is_passed'      => $s->is_passed,
                    'correct'        => $s->answers()->where('is_correct', true)->count(),
                    'wrong'          => $s->answers()->where('is_correct', false)->whereNotNull('answer')->count(),
                    'unanswered'     => $s->answers()->whereNull('answer')->count(),
                    'total'          => $s->answers()->count(),
                ];
            });

        return response()->json(['data' => $sessions]);
    }

    private function authorizeSession(Request $request, ExamSession $session): void
    {
        if ($session->student_id !== $request->user()->id) abort(403, 'Akses ditolak.');
    }

    /* ── Verifikasi password untuk keluar dari ujian ───────── */
    public function verifyExit(Request $request)
    {
        $data = $request->validate([
            'password'   => 'required|string',
            'session_id' => 'nullable|exists:exam_sessions,id',
            'action'     => 'nullable|string|in:exit_exam',
        ]);

        $user   = $request->user();
        $action = $data['action'] ?? 'exit_exam';

        // Verifikasi password user itu sendiri (siswa)
        $valid = \Illuminate\Support\Facades\Hash::check($data['password'], $user->password);

        // Juga cek apakah ini password guru/admin yang valid
        if (!$valid) {
            $admin = \App\Models\User::where('role', 'admin')->first();
            if ($admin && \Illuminate\Support\Facades\Hash::check($data['password'], $admin->password)) {
                $valid = true;
            }
        }

        if (!$valid) {
            $guru = \App\Models\User::where('role', 'guru')->first();
            if ($guru && \Illuminate\Support\Facades\Hash::check($data['password'], $guru->password)) {
                $valid = true;
            }
        }

        if (!$valid) {
            // Catat violation percobaan password salah
            if ($data['session_id']) {
                \App\Models\Violation::updateOrCreate(
                    ['session_id' => $data['session_id'], 'violation_type' => 'wrong_password'],
                    ['count' => \DB::raw('count + 1'), 'student_id' => $user->id]
                );
            }

            return response()->json([
                'valid'     => false,
                'message'   => 'Password salah!',
                'remaining' => $data['session_id']
                    ? (5 - \App\Models\Violation::where('session_id', $data['session_id'])->where('violation_type', 'wrong_password')->sum('count'))
                    : 5,
            ], 422);
        }

        // Log aktivitas keluar
        \App\Models\ActivityLog::create([
            'user_id'     => $user->id,
            'action'      => 'exam_exit_verified',
            'description' => "{$user->name} keluar dari ujian (terverifikasi) — $action",
            'metadata'    => json_encode(['session_id' => $data['session_id'], 'action' => $action]),
        ]);

        return response()->json([
            'valid'   => true,
            'message' => 'Password valid. Keluar diizinkan.',
        ]);
    }
}

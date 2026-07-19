<?php
namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Exam;
use App\Models\ExamSession;
use App\Services\GradingService;

class SiswaWebController extends Controller
{
    public function exams()
    {
        /** @var \App\Models\User $student */
        $student = auth()->user();
        $classIds = $student->enrolledClasses()->pluck('classes.id');

        $exams = Exam::whereIn('class_id', $classIds)
            ->where('status', 'active')
            ->with(['classRoom', 'teacher'])
            ->get();

        // Eager load sessions in one query
        $sessionMap = ExamSession::whereIn('exam_id', $exams->pluck('id'))
            ->where('student_id', $student->id)
            ->get()
            ->keyBy('exam_id');

        $exams = $exams->map(function ($exam) use ($sessionMap) {
            $session = $sessionMap->get($exam->id);
            return (object) [
                    'id' => $exam->id,
                    'title' => $exam->title,
                    'subject' => $exam->classRoom?->subject,
                    'class_name' => $exam->classRoom?->name,
                    'duration' => $exam->duration_minutes,
                    'total_questions' => $exam->total_questions,
                    'passing_grade' => $exam->passing_grade,
                    'max_violations' => $exam->max_violations,
                    'start_time' => $exam->start_time,
                    'session_status' => $session?->status,
                    'session_id' => $session?->id,
                ];
            });

        return view('siswa.exams.index', compact('exams'));
    }

    public function startExam(Exam $exam)
    {
        /** @var \App\Models\User $student */
        $student = auth()->user();
        $enrolled = $student->enrolledClasses()
            ->where('classes.id', $exam->class_id)->wherePivot('status', 'active')->exists();

        if (!$enrolled) abort(403, 'Tidak terdaftar di kelas ini.');
        if ($exam->status !== 'active') abort(403, 'Ujian tidak aktif.');

        // Cek apakah sudah punya session final — tolak akses ulang
        $finalSession = ExamSession::where('exam_id', $exam->id)
            ->where('student_id', $student->id)
            ->whereIn('status', ['submitted', 'timeout', 'force_submitted'])
            ->exists();
        if ($finalSession) abort(403, 'Kamu sudah mengerjakan ujian ini.');

        $isResumed = false;

        // Get or create session
        $session = ExamSession::where('exam_id', $exam->id)
            ->where('student_id', $student->id)
            ->where('status', 'in_progress')
            ->first();

        if ($session) {
            // Resume: hitung sisa waktu terkini termasuk extension
            $session->loadMissing(['exam', 'extensions']);
            $elapsed   = now()->diffInSeconds($session->started_at);
            $extSeconds= $session->extensions->sum('minutes') * 60;
            $total     = ($exam->duration_minutes * 60) + $extSeconds;
            $remaining = max(0, $total - $elapsed);
            $session->update(['remaining_seconds' => (int) $remaining, 'last_activity_at' => now()]);
        } else {
            $randomizer = app(\App\Services\ExamRandomizationService::class);
            $session = $randomizer->createSession($exam, $student->id);
        }

        $randomizer = app(\App\Services\ExamRandomizationService::class);
        $questions = $randomizer->buildShuffledQuestions($exam, $session);

        $remainingSeconds = $session->remaining_seconds;
        $sessionId = $session->id;

        return view('siswa.exams.start', compact('exam', 'questions', 'remainingSeconds', 'sessionId'));
    }

    public function history()
    {
        /** @var \App\Models\User $student */
        $student = auth()->user();
        $sessions = ExamSession::where('student_id', $student->id)
            ->whereIn('status', ['submitted', 'timeout', 'force_submitted'])
            ->with(['exam.classRoom', 'answers'])
            ->orderByDesc('submitted_at')
            ->paginate(20)
            ->through(function ($s) {
                $exam = $s->exam;
                $totalQuestions = $exam?->total_questions ?? $s->answers->count();
                $correct = $s->answers->where('is_correct', true)->count();
                $wrong = $s->answers->where('is_correct', false)->whereNotNull('answer')->count();
                $unanswered = $totalQuestions - $correct - $wrong;

                return (object) [
                    'id' => $s->id,
                    'title' => $exam->title ?? '-',
                    'class' => $exam?->classRoom?->name ?? '-',
                    'submitted_at' => $s->submitted_at,
                    'status' => $s->status,
                    'score' => $s->score,
                    'is_passed' => $s->is_passed,
                    'correct' => $correct,
                    'wrong' => $wrong,
                    'unanswered' => $unanswered,
                    'total_questions' => $totalQuestions,
                    'passing_grade' => $exam->passing_grade ?? 0,
                ];
            });

        return view('siswa.history.index', compact('sessions'));
    }

    public function result(ExamSession $session)
    {
        /** @var \App\Models\User $student */
        $student = auth()->user();
        if ($session->student_id !== $student->id) abort(403);
        if ($session->status === 'in_progress') abort(403, 'Ujian belum dikumpulkan.');

        $result = app(GradingService::class)->getSessionResult($session);

        return view('siswa.exams.result', compact('session', 'result'));
    }
}

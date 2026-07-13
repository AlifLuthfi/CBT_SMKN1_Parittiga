<?php
namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Exam;
use App\Models\ExamSession;
use Illuminate\Http\Request;

class SiswaWebController extends Controller
{
    public function exams()
    {
        return view('siswa.exams.index');
    }

    public function startExam(Exam $exam)
    {
        $student = auth()->user();
        $enrolled = $student->enrolledClasses()
            ->where('classes.id', $exam->class_id)->wherePivot('status', 'active')->exists();

        if (!$enrolled) abort(403, 'Tidak terdaftar di kelas ini.');
        if ($exam->status !== 'active') abort(403, 'Ujian tidak aktif.');

        // Get or create session
        $session = ExamSession::where('exam_id', $exam->id)
            ->where('student_id', $student->id)
            ->where('status', 'in_progress')
            ->first();

        if (!$session) {
            // Call API's startExam logic via the service
            $randomizer = app(\App\Services\ExamRandomizationService::class);
            $session = $randomizer->createSession($exam, $student->id);
        }

        $questions = app(\App\Services\ExamRandomizationService::class)
            ->buildShuffledQuestions($exam, $session);

        $remainingSeconds = $session->remaining_seconds;
        $sessionId = $session->id;

        return view('siswa.exams.start', compact('exam', 'questions', 'remainingSeconds', 'sessionId'));
    }
}

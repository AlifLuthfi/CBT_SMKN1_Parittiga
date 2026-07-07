<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ExamSession;
use App\Models\Violation;
use App\Services\GradingService;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class ViolationController extends Controller
{
    public function __construct(private NotificationService $notif, private GradingService $grading) {}

    public function store(Request $request)
    {
        $data = $request->validate([
            'session_id'     => 'required|exists:exam_sessions,id',
            'violation_type' => 'required|in:tab_switch,fullscreen_exit,copy_paste,blur,devtools',
        ]);

        $session = ExamSession::findOrFail($data['session_id']);

        if ($session->student_id !== $request->user()->id) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        if ($session->status !== 'in_progress') {
            return response()->json(['message' => 'Sesi tidak aktif.'], 422);
        }

        // Update or create violation record
        $violation = Violation::updateOrCreate(
            ['session_id' => $session->id, 'violation_type' => $data['violation_type']],
            ['count'      => \DB::raw('count + 1'), 'student_id' => $request->user()->id]
        );

        // Recalculate total violations
        $total = Violation::where('session_id', $session->id)->sum('count');
        $max   = $session->exam->max_violations ?? 5;

        $this->notif->notifyViolation($violation->fresh());

        if ($total >= $max) {
            $session->update(['status' => 'force_submitted', 'submitted_at' => now(), 'force_submit' => true]);
            $this->grading->gradeSession($session);
            return response()->json([
                'message'      => 'Batas pelanggaran tercapai. Ujian dikumpulkan otomatis.',
                'force_submit' => true,
                'total'        => $total,
                'remaining'    => 0,
            ]);
        }

        return response()->json([
            'message'   => 'Pelanggaran dicatat.',
            'total'     => $total,
            'remaining' => $max - $total,
        ]);
    }

    public function index(Request $request)
    {
        $violations = Violation::whereHas('session.exam', fn($q) => $q->where('teacher_id', $request->user()->id))
            ->with(['student', 'session.exam'])
            ->when($request->session_id, fn($q, $v) => $q->where('session_id', $v))
            ->orderByDesc('updated_at')
            ->paginate($request->per_page ?? 20);

        return response()->json($violations);
    }

    public function handle(Request $request, Violation $violation)
    {
        $violation->update(['status' => 'handled']);
        return response()->json(['message' => 'Pelanggaran ditandai selesai.']);
    }
}

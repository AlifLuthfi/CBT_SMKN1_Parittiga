<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Exam;
use App\Models\ExamSession;
use App\Models\Question;
use App\Models\User;
use App\Models\Violation;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $teacher = $request->user();

        $stats = [
            'total_exams'     => Exam::where('teacher_id', $teacher->id)->count(),
            'total_questions' => Question::where('teacher_id', $teacher->id)->count(),
            'total_students'  => $this->countUniqueStudents($teacher->id),
            'average_score'   => $this->getAverageScore($teacher->id),
            'active_exams'    => Exam::where('teacher_id', $teacher->id)->where('status','active')->count(),
            'violations_today'=> Violation::whereHas('session.exam', fn($q) => $q->where('teacher_id',$teacher->id))
                                    ->whereDate('created_at', today())->count(),
        ];

        $activeExams = Exam::where('teacher_id', $teacher->id)
            ->where('status', 'active')
            ->with(['classRoom'])
            ->withCount(['sessions','sessions as submitted_count' => fn($q) => $q->whereIn('status',['submitted','timeout','force_submitted'])])
            ->get()
            ->map(fn($e) => array_merge($e->toArray(), ['violations_count' => $e->violations_count]));

        $questionDist = [
            'easy'   => Question::where('teacher_id',$teacher->id)->where('difficulty','easy')->count(),
            'medium' => Question::where('teacher_id',$teacher->id)->where('difficulty','medium')->count(),
            'hard'   => Question::where('teacher_id',$teacher->id)->where('difficulty','hard')->count(),
        ];

        $recentExams = Exam::where('teacher_id',$teacher->id)
            ->with(['classRoom'])
            ->withCount(['sessions','violations'])
            ->orderByDesc('created_at')->take(10)->get();

        $recentViolations = Violation::whereHas('session.exam',fn($q)=>$q->where('teacher_id',$teacher->id))
            ->with('student')
            ->orderByDesc('created_at')->take(5)->get()
            ->map(fn($v) => ['student_name'=>$v->student->name,'violation_type'=>$v->violation_type,'count'=>$v->count,'created_at'=>$v->created_at]);

        $topScores = ExamSession::whereHas('exam',fn($q)=>$q->where('teacher_id',$teacher->id))
            ->with(['student','exam'])
            ->whereIn('status',['submitted','timeout','force_submitted'])
            ->whereNotNull('score')
            ->orderByDesc('score')->take(5)->get()
            ->map(fn($s) => ['student_name'=>$s->student->name,'score'=>$s->score,'total_questions'=>$s->exam->total_questions,'duration_minutes'=>$s->exam->duration_minutes]);

        $activityLogs = ActivityLog::where('user_id',$teacher->id)
            ->orderByDesc('created_at')->take(6)->get();

        return response()->json(compact('stats','activeExams','questionDist','recentExams','recentViolations','topScores','activityLogs'));
    }

    private function countUniqueStudents(int $teacherId): int
    {
        return ExamSession::whereHas('exam', fn($q) => $q->where('teacher_id',$teacherId))
            ->distinct('student_id')->count('student_id');
    }

    private function getAverageScore(int $teacherId): float
    {
        return round(ExamSession::whereHas('exam', fn($q) => $q->where('teacher_id',$teacherId))
            ->whereNotNull('score')->avg('score') ?? 0, 2);
    }
}

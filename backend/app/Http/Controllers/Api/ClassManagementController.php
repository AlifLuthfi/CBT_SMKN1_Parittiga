<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ClassRoom;
use App\Models\User;
use Illuminate\Http\Request;

class ClassManagementController extends Controller
{
    /**
     * Guru: lihat daftar kelas miliknya (read-only)
     */
    public function index(Request $request)
    {
        $classes = ClassRoom::where('teacher_id', $request->user()->id)
            ->withCount([
                'students as student_count' => fn($q) => $q->where('class_student.status', 'active'),
                'exams as exam_count',
            ])
            ->orderByDesc('created_at')->get();
        return response()->json(['data'=>$classes]);
    }

    /**
     * Guru: lihat detail kelas
     */
    public function show(Request $request, ClassRoom $class)
    {
        abort_if($class->teacher_id !== $request->user()->id, 403, 'Akses ditolak.');
        return response()->json(['class'=>$class->load(['teacher','students'=>fn($q)=>$q->wherePivot('status','active'),'exams'])]);
    }

    /**
     * Guru: lihat daftar siswa dalam kelas beserta nilai
     */
    public function students(Request $request, ClassRoom $class)
    {
        abort_if($class->teacher_id !== $request->user()->id, 403, 'Akses ditolak.');

        $students = $class->students()
            ->withPivot('status','enrolled_at')
            ->when($request->status, fn($q,$v)=>$q->wherePivot('status',$v))
            ->get();

        // Ambil nilai ujian untuk setiap siswa di kelas ini (mapel sesuai kelas)
        $studentIds = $students->pluck('id');
        $gradeReports = \App\Models\StudentGradeReport::whereIn('student_id', $studentIds)
            ->where('class_id', $class->id)
            ->get()
            ->groupBy('student_id');

        $result = $students->map(function ($s) use ($gradeReports, $class) {
            $reports = $gradeReports->get($s->id, collect());
            return [
                'id'         => $s->id,
                'name'       => $s->name,
                'nis'        => $s->nis,
                'email'      => $s->email,
                'status'     => $s->pivot->status,
                'enrolled_at'=> $s->pivot->enrolled_at,
                'grades'     => $reports->map(fn($r) => [
                    'exam_title'    => $r->exam_title,
                    'exam_id'       => $r->exam_id,
                    'score'         => $r->score,
                    'grade'         => $r->grade,
                    'status'        => $r->status,
                ]),
                'average_score' => round($reports->avg('score'), 2) ?: null,
            ];
        });

        return response()->json(['data'=>$result]);
    }
}

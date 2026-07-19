<?php
namespace App\Services;

use App\Models\ClassRoom;
use App\Models\ExamSession;
use App\Models\StudentGradeReport;
use App\Models\User;

class GradeReportService
{
    public function recalculateForClass(int $classId, string $year, string $semester): void
    {
        $class    = ClassRoom::findOrFail($classId);
        $students = $class->students()->wherePivot('status','active')->get();

        foreach ($students as $student) {
            $this->recalculateForStudent($student->id, $classId, $year, $semester);
        }
    }

    public function recalculateForStudent(int $studentId, int $classId, string $year, string $semester): StudentGradeReport
    {
        $sessions = ExamSession::where('student_id', $studentId)
            ->whereHas('exam', fn($q) => $q->where('class_id', $classId)
                ->where('status','ended'))
            ->whereIn('status',['submitted','timeout','force_submitted'])
            ->whereNotNull('score')
            ->with('exam:id,passing_grade')
            ->get();

        $total    = $sessions->count();
        $avg      = $total > 0 ? round($sessions->avg('score'), 2) : 0;
        $highest  = $total > 0 ? $sessions->max('score') : 0;
        $lowest   = $total > 0 ? $sessions->min('score') : 0;

        $class    = ClassRoom::findOrFail($classId);
        $passed   = $sessions->filter(fn($s) => $s->score >= $s->exam->passing_grade)->count();
        $passRate = $total > 0 ? round($passed / $total * 100, 2) : 0;

        return StudentGradeReport::updateOrCreate(
            ['student_id'=>$studentId,'class_id'=>$classId,'academic_year'=>$year,'semester'=>$semester],
            [
                'average_score'        => $avg,
                'highest_score'        => $highest,
                'lowest_score'         => $lowest,
                'total_exams'          => $total,
                'passed_exams'         => $passed,
                'pass_rate'            => $passRate,
                'last_calculated_at'   => now(),
            ]
        );
    }

    public function getClassReport(int $classId, string $year, string $semester): array
    {
        $class    = ClassRoom::with(['teacher','students'])->findOrFail($classId);
        $reports  = StudentGradeReport::with('student')
            ->where('class_id', $classId)
            ->where('academic_year', $year)
            ->where('semester', $semester)
            ->orderByDesc('average_score')
            ->get();

        // Grade distribution
        $dist = ['A'=>0,'B'=>0,'C'=>0,'D'=>0,'E'=>0];
        foreach ($reports as $r) {
            $grade = $this->scoreToGrade($r->average_score);
            $dist[$grade]++;
        }

        // Exam trends — single GROUP BY query instead of N+1
        $trends = ExamSession::whereHas('exam', fn($q) => $q->where('class_id', $classId)->where('status', 'ended'))
            ->whereIn('status', ['submitted', 'timeout', 'force_submitted'])
            ->whereNotNull('score')
            ->selectRaw('exam_id, ROUND(AVG(score), 2) as average')
            ->groupBy('exam_id')
            ->pluck('average', 'exam_id');

        $exams = $class->exams()
            ->where('status', 'ended')
            ->orderBy('end_time')
            ->get();

        $trendList = $exams->map(fn($exam) => [
            'exam_title' => substr($exam->title, 0, 20),
            'average'    => round($trends[$exam->id] ?? 0, 2),
        ]);

        return [
            'class_name'        => $class->name,
            'subject'           => $class->subject,
            'teacher'           => $class->teacher->name,
            'academic_year'     => $year,
            'semester'          => $semester,
            'average'           => round($reports->avg('average_score'), 2),
            'pass_rate'         => round($reports->avg('pass_rate'), 2),
            'highest'           => ['score'=>$reports->max('highest_score'),'name'=>$reports->sortByDesc('highest_score')->first()?->student->name],
            'lowest'            => ['score'=>$reports->min('lowest_score'),'name'=>$reports->sortBy('lowest_score')->first()?->student->name],
            'exam_trends'       => $trendList,
            'grade_distribution'=> $dist,
            'rankings'          => $reports->values()->map(function($r, $i) {
                $trend = 'stable';
                return [
                    'rank'   => $i+1,
                    'name'   => $r->student->name,
                    'avg'    => $r->average_score,
                    'grade'  => $this->scoreToGrade($r->average_score),
                    'exams'  => $r->total_exams,
                    'passed' => $r->passed_exams,
                    'trend'  => $trend,
                ];
            }),
        ];
    }

    public function getStudentReport(int $studentId, int $classId, string $year, string $semester): array
    {
        $student = User::findOrFail($studentId);
        $report  = StudentGradeReport::where(['student_id'=>$studentId,'class_id'=>$classId,'academic_year'=>$year,'semester'=>$semester])->first();

        $sessions = ExamSession::where('student_id', $studentId)
            ->whereHas('exam', fn($q) => $q->where('class_id', $classId))
            ->whereIn('status',['submitted','timeout','force_submitted'])
            ->with('exam')
            ->orderBy('submitted_at')
            ->get();

        $history = $sessions->map(function($s, $i) use ($sessions) {
            $prev  = $i > 0 ? $sessions[$i-1]->score : null;
            $trend = $prev === null ? 'stable' : ($s->score > $prev+3 ? 'up' : ($s->score < $prev-3 ? 'down' : 'stable'));
            return [
                'exam_title'   => $s->exam->title,
                'score'        => $s->score,
                'is_passed'    => $s->is_passed,
                'submitted_at' => $s->submitted_at?->format('Y-m-d'),
                'trend'        => $trend,
            ];
        });

        return [
            'name'        => $student->name,
            'average'     => $report?->average_score ?? 0,
            'highest'     => ['score'=>$report?->highest_score ?? 0,'exam'=>$sessions->sortByDesc('score')->first()?->exam->title],
            'total_exams' => $report?->total_exams ?? 0,
            'passed'      => $report?->passed_exams ?? 0,
            'history'     => $history,
        ];
    }

    private function scoreToGrade(float $score): string
    {
        return match(true) {
            $score >= 85 => 'A',
            $score >= 75 => 'B',
            $score >= 65 => 'C',
            $score >= 55 => 'D',
            default      => 'E',
        };
    }
}

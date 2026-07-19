<?php
namespace App\Services;

use App\Models\Exam;
use App\Models\ExamSession;
use App\Models\ExamPause;
use App\Models\ExamTimeExtension;

class ExamSchedulerService
{
    public function __construct(private NotificationService $notif, private GradingService $grading) {}

    public function tick(): void
    {
        $this->activateDueExams();
        $this->notifyEndingSoon();
        $this->endOverdueExams();
        $this->submitTimedOutSessions();
    }

    public function activateDueExams(): void
    {
        Exam::where('status','scheduled')
            ->where('auto_activate',true)
            ->where('start_time','<=',now())
            ->each(function(Exam $exam) {
                $exam->update(['status'=>'active']);
                $this->notif->notifyExamStarted($exam->teacher_id, $exam->title);
                \App\Models\ActivityLog::create(['user_id'=>$exam->teacher_id,'action'=>'exam_started','description'=>"Ujian '{$exam->title}' diaktifkan otomatis."]);
            });
    }

    public function notifyEndingSoon(): void
    {
        Exam::where('status','active')
            ->whereNull('notified_ending_soon_at')
            ->whereNotNull('end_time')
            ->where('end_time','<=',now()->addMinutes(15))
            ->where('end_time','>',now())
            ->each(function(Exam $exam) {
                $mins = (int) now()->diffInMinutes($exam->end_time);
                $this->notif->notifyEndingSoon($exam->teacher_id, $exam->title, $mins);
                $exam->update(['notified_ending_soon_at'=>now()]);
            });
    }

    public function endOverdueExams(): void
    {
        Exam::where('status','active')
            ->where('auto_end',true)
            ->whereNotNull('end_time')
            ->where('end_time','<=',now())
            ->each(function(Exam $exam) {
                $this->endExam($exam);
            });
    }

    public function endExam(Exam $exam): void
    {
        $exam->update(['status'=>'ended']);
        // Auto-submit all in_progress sessions — batch update
        ExamSession::where('exam_id',$exam->id)->where('status','in_progress')
            ->update(['status'=>'timeout','submitted_at'=>now()]);
        // grade sessions yang baru di-timeout
        ExamSession::where('exam_id',$exam->id)->where('status','timeout')
            ->whereNotNull('submitted_at')
            ->each(function(ExamSession $session) {
                $this->grading->gradeSession($session);
            });
        $submitted = ExamSession::where('exam_id',$exam->id)->whereIn('status',['submitted','timeout','force_submitted'])->count();
        $total     = ExamSession::where('exam_id',$exam->id)->count();
        $this->notif->notifyExamEnded($exam->teacher_id, $exam->title, $submitted, $total);
        \App\Models\ActivityLog::create(['user_id'=>$exam->teacher_id,'action'=>'exam_ended','description'=>"Ujian '{$exam->title}' berakhir. $submitted/$total submit."]);
    }

    public function submitTimedOutSessions(): void
    {
        ExamSession::with(['exam', 'extensions'])
            ->where('status','in_progress')
            ->whereHas('exam',fn($q)=>$q->where('status','active'))
            ->each(function(ExamSession $session) {
                $remaining = $session->remaining_seconds;
                if ($remaining <= 0) {
                    $session->update(['status'=>'timeout','submitted_at'=>now()]);
                    $this->grading->gradeSession($session);
                } else if ($session->remaining_seconds !== $remaining) {
                    $session->update(['remaining_seconds'=>$remaining,'last_activity_at'=>now()]);
                }
            });
    }

    public function pauseExam(Exam $exam, int $pausedBy, string $reason = ''): void
    {
        $exam->update(['status'=>'paused']);
        ExamPause::create(['exam_id'=>$exam->id,'paused_by'=>$pausedBy,'reason'=>$reason,'paused_at'=>now(),'is_active'=>true]);
    }

    public function resumeExam(Exam $exam, int $resumedBy): void
    {
        $pause = $exam->activePause;
        if ($pause) {
            $pausedSeconds = now()->diffInSeconds($pause->paused_at);
            $pause->update(['resumed_at'=>now(),'is_active'=>false]);
            // Extend all in_progress sessions by paused time
            ExamSession::where('exam_id',$exam->id)->where('status','in_progress')
                ->update([
                    'started_at'       => \Illuminate\Support\Facades\DB::raw("started_at + INTERVAL $pausedSeconds SECOND"),
                    'last_activity_at' => now(),
                ]);
        }
        $exam->update(['status'=>'active']);
    }

    public function extendTime(int $sessionId, int $minutes, int $extendedBy, string $reason = ''): void
    {
        ExamTimeExtension::create(['session_id'=>$sessionId,'extended_by'=>$extendedBy,'minutes'=>$minutes,'reason'=>$reason]);
    }
}

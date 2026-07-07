<?php
namespace App\Services;

use App\Models\Notification;
use App\Models\ExamSession;
use App\Models\Violation;

class NotificationService
{
    public function notify(int $userId, string $title, string $message, string $type = 'info', array $data = []): Notification
    {
        return Notification::create(['user_id'=>$userId,'title'=>$title,'message'=>$message,'type'=>$type,'data'=>$data]);
    }

    public function notifyViolation(Violation $v): void
    {
        $teacherId = $v->session->exam->teacher_id;
        $student   = $v->student->name;
        $exam      = $v->session->exam->title;
        $this->notify($teacherId,"Pelanggaran: $student","$student melakukan {$v->violation_type} ({$v->count}x) pada $exam",'warning',['session_id'=>$v->session_id,'violation_type'=>$v->violation_type]);
    }

    public function notifyStudentSubmit(ExamSession $s): void
    {
        $teacherId = $s->exam->teacher_id;
        $student   = $s->student->name;
        $exam      = $s->exam->title;
        $this->notify($teacherId,"Submit: $student","$student telah mengumpulkan ujian $exam",'info',['session_id'=>$s->id,'score'=>$s->score]);
    }

    public function notifyExamStarted(int $teacherId, string $examTitle): void
    {
        $this->notify($teacherId,"Ujian Dimulai","$examTitle telah diaktifkan",'success');
    }

    public function notifyExamEnded(int $teacherId, string $examTitle, int $submitted, int $total): void
    {
        $this->notify($teacherId,"Ujian Selesai","$examTitle telah berakhir. $submitted/$total siswa submit.",'info');
    }

    public function notifyEndingSoon(int $teacherId, string $examTitle, int $minutesLeft): void
    {
        $this->notify($teacherId,"Ujian Akan Berakhir","$examTitle berakhir dalam $minutesLeft menit.",'warning');
    }

    public function getUnread(int $userId): array
    {
        $notifs = Notification::where('user_id',$userId)->orderByDesc('created_at')->take(20)->get();
        return ['unread_count'=>$notifs->whereNull('read_at')->count(),'data'=>$notifs];
    }

    public function markAllRead(int $userId): void
    {
        Notification::where('user_id',$userId)->whereNull('read_at')->update(['read_at'=>now()]);
    }
}

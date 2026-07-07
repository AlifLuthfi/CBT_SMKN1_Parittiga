<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class ExamSession extends Model
{
    protected $fillable = [
        'exam_id','student_id','seed','question_order','status','score','is_passed',
        'force_submit','remaining_seconds','started_at','submitted_at','last_activity_at',
        'last_bulk_sync_at','sync_count',
    ];
    protected $casts = [
        'question_order'=>'array','started_at'=>'datetime','submitted_at'=>'datetime',
        'last_activity_at'=>'datetime','last_bulk_sync_at'=>'datetime',
        'is_passed'=>'boolean','force_submit'=>'boolean',
        'score'=>'decimal:2',
    ];

    public function exam()      { return $this->belongsTo(Exam::class,'exam_id'); }
    public function student()   { return $this->belongsTo(User::class,'student_id'); }
    public function answers()   { return $this->hasMany(ExamSessionAnswer::class,'session_id'); }
    public function violations(){ return $this->hasMany(Violation::class,'session_id'); }
    public function extensions(){ return $this->hasMany(ExamTimeExtension::class,'session_id'); }

    public function getRemainingSecondsAttribute($v)
    {
        if ($this->status !== 'in_progress') return 0;
        if (!$this->started_at) return $this->exam->duration_minutes * 60;
        $elapsed = now()->diffInSeconds($this->started_at);
        $total   = ($this->exam->duration_minutes * 60) + $this->extensions()->sum('minutes') * 60;
        return max(0, $total - $elapsed);
    }
}

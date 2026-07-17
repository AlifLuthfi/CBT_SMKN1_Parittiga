<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Exam extends Model
{
    use SoftDeletes;
    protected $fillable = [
        'teacher_id','class_id','package_id','title','description','duration_minutes','total_questions',
        'randomize_questions','randomize_options','show_result_immediately',
        'passing_grade','status','start_time','end_time','auto_activate','auto_end',
        'max_violations','question_blueprint','notified_ending_soon_at',
    ];
    protected $casts = [
        'start_time'=>'datetime','end_time'=>'datetime','notified_ending_soon_at'=>'datetime',
        'question_blueprint'=>'array','randomize_questions'=>'boolean',
        'randomize_options'=>'boolean','show_result_immediately'=>'boolean',
        'passing_grade'=>'decimal:2',
    ];

    public function teacher()    { return $this->belongsTo(User::class,'teacher_id'); }
    public function classRoom()  { return $this->belongsTo(ClassRoom::class,'class_id'); }
    public function package()    { return $this->belongsTo(QuestionPackage::class,'package_id'); }
    public function questions()  { return $this->belongsToMany(Question::class,'exam_questions')->withPivot('display_order','is_active')->withTimestamps(); }
    public function sessions()   { return $this->hasMany(ExamSession::class,'exam_id'); }
    public function violations() { return $this->hasManyThrough(Violation::class, ExamSession::class, 'exam_id', 'session_id'); }
    public function pauses()     { return $this->hasMany(ExamPause::class,'exam_id'); }

    // ── Accessor ──
    // Catatan: accessor ini override nilai dari withCount().
    // Pake withCount('relation') + akses langsung attribute biar gak N+1
    // Kalo mau fallback value, tambah '?? $this->attributes["sessions_count"] ?? 0'
    // di body accessor. Buat sekarang hapus comment aja — gak dipanggil langsung.
    // public function getSessionsCountAttribute()    { return $this->sessions()->count(); }
    // public function getViolationsCountAttribute()  { return Violation::whereHas('session',fn($q)=>$q->where('exam_id',$this->id))->count(); }
    // public function getSubmittedCountAttribute()   { return $this->sessions()->whereIn('status',['submitted','timeout','force_submitted'])->count(); }
    public function getActivePauseAttribute()      { return $this->pauses()->where('is_active',true)->first(); }
}

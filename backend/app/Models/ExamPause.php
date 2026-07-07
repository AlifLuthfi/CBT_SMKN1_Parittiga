<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class ExamPause extends Model
{
    protected $fillable = ['exam_id','paused_by','reason','paused_at','resumed_at','is_active'];
    protected $casts    = ['paused_at'=>'datetime','resumed_at'=>'datetime','is_active'=>'boolean'];
    public function exam()     { return $this->belongsTo(Exam::class); }
    public function pausedBy() { return $this->belongsTo(User::class,'paused_by'); }
}

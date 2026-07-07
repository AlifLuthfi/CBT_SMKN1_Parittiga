<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Violation extends Model
{
    protected $fillable = ['session_id','student_id','violation_type','count','status'];
    public function session() { return $this->belongsTo(ExamSession::class,'session_id'); }
    public function student() { return $this->belongsTo(User::class,'student_id'); }
}

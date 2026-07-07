<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class StudentGradeReport extends Model
{
    protected $fillable = ['student_id','class_id','academic_year','semester','average_score','highest_score','lowest_score','total_exams','passed_exams','pass_rate','last_calculated_at'];
    protected $casts    = ['last_calculated_at'=>'datetime','average_score'=>'decimal:2','highest_score'=>'decimal:2','lowest_score'=>'decimal:2','pass_rate'=>'decimal:2'];
    public function student() { return $this->belongsTo(User::class,'student_id'); }
    public function classRoom(){ return $this->belongsTo(ClassRoom::class,'class_id'); }
}

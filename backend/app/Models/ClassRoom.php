<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ClassRoom extends Model
{
    use SoftDeletes;
    protected $table = 'classes';
    protected $fillable = ['teacher_id','name','subject','academic_year','semester','description'];

    public function teacher()  { return $this->belongsTo(User::class,'teacher_id'); }
    public function students() { return $this->belongsToMany(User::class,'class_student','class_id','student_id')->withPivot('status','enrolled_at')->withTimestamps(); }
    public function exams()    { return $this->hasMany(Exam::class,'class_id'); }
    public function gradeReports() { return $this->hasMany(StudentGradeReport::class,'class_id'); }

    public function getStudentCountAttribute() { return $this->students()->wherePivot('status','active')->count(); }
    public function getExamCountAttribute()    { return $this->exams()->count(); }
}

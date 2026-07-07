<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Question extends Model
{
    use SoftDeletes;
    protected $fillable = ['teacher_id','subject_id','category_id','question_text','image_path','question_type','options','correct_answer','explanation','difficulty','weight','is_active','tags'];
    protected $casts = ['options'=>'array','tags'=>'array','is_active'=>'boolean','weight'=>'decimal:2'];
    protected $appends = ['image_url'];

    public function getImageUrlAttribute()
    {
        return $this->image_path ? url('storage/' . $this->image_path) : null;
    }

    public function teacher()  { return $this->belongsTo(User::class,'teacher_id'); }
    public function subject()  { return $this->belongsTo(Subject::class,'subject_id'); }
    public function category() { return $this->belongsTo(QuestionCategory::class,'category_id'); }
    public function exams()    { return $this->belongsToMany(Exam::class,'exam_questions')->withPivot('display_order','is_active')->withTimestamps(); }
    public function answers()  { return $this->hasMany(ExamSessionAnswer::class,'question_id'); }
}

<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Question extends Model
{
    use SoftDeletes;
    protected $fillable = ['teacher_id','subject_id','question_text','image_path','question_type','options','correct_answer','explanation','is_active'];
    protected $casts = ['options'=>'array','is_active'=>'boolean'];
    protected $appends = ['image_url'];

    public function getImageUrlAttribute()
    {
        if (!$this->image_path) return null;
        if (str_starts_with($this->image_path, 'http://') || str_starts_with($this->image_path, 'https://')) {
            return $this->image_path;
        }
        return '/storage/' . $this->image_path;
    }

    public function teacher()  { return $this->belongsTo(User::class,'teacher_id'); }
    public function subject()  { return $this->belongsTo(Subject::class,'subject_id'); }

    public function exams()    { return $this->belongsToMany(Exam::class,'exam_questions')->withPivot('display_order','is_active')->withTimestamps(); }
    public function answers()  { return $this->hasMany(ExamSessionAnswer::class,'question_id'); }
}

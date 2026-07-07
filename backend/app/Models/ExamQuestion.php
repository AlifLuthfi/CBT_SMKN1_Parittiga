<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExamQuestion extends Model
{
    protected $fillable = ['exam_id','question_id','display_order','is_active'];
    protected $casts    = ['is_active'=>'boolean'];

    public function exam()     { return $this->belongsTo(Exam::class); }
    public function question() { return $this->belongsTo(Question::class); }
}

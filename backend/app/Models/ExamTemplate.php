<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class ExamTemplate extends Model
{
    protected $fillable = ['teacher_id','title','description','type','question_count','used_count','settings'];
    protected $casts    = ['settings'=>'array'];
    public function teacher() { return $this->belongsTo(User::class,'teacher_id'); }
}

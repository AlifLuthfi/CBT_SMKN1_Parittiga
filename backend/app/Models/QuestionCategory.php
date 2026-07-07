<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class QuestionCategory extends Model
{
    protected $fillable = ['teacher_id','name','color'];
    public function teacher()   { return $this->belongsTo(User::class,'teacher_id'); }
    public function questions() { return $this->hasMany(Question::class,'category_id'); }
}

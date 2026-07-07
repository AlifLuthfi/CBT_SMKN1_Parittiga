<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class QuestionPackage extends Model
{
    use SoftDeletes;

    protected $fillable = ['teacher_id', 'title', 'subject', 'class_id', 'description'];

    public function teacher()    { return $this->belongsTo(User::class, 'teacher_id'); }
    public function classRoom()  { return $this->belongsTo(ClassRoom::class, 'class_id'); }
    public function questions()  { return $this->belongsToMany(Question::class, 'question_package_items', 'package_id', 'question_id')
        ->withPivot('display_order')->withTimestamps()->orderBy('question_package_items.display_order'); }
}

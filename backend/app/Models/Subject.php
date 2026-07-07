<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Subject extends Model
{
    use SoftDeletes;

    protected $fillable = ['teacher_id', 'name'];

    public function teacher()  { return $this->belongsTo(User::class, 'teacher_id'); }
    public function questions() { return $this->hasMany(Question::class, 'subject_id'); }

    public function getQuestionsCountAttribute()
    {
        return $this->questions()->count();
    }
}

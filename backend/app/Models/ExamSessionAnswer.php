<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class ExamSessionAnswer extends Model
{
    protected $fillable = ['session_id','question_id','answer','is_correct','score'];
    protected $casts    = ['is_correct'=>'boolean','score'=>'decimal:2'];

    public function session()  { return $this->belongsTo(ExamSession::class,'session_id'); }
    public function question() { return $this->belongsTo(Question::class,'question_id'); }
}

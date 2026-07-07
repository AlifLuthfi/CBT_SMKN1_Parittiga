<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class QuestionImport extends Model
{
    protected $fillable = ['teacher_id','filename','total_rows','success_count','error_count','status','errors'];
    protected $casts    = ['errors'=>'array'];
    public function teacher() { return $this->belongsTo(User::class,'teacher_id'); }
    public function getProgressPercentAttribute(): int
    {
        if (!$this->total_rows) return 0;
        return (int)(($this->success_count + $this->error_count) / $this->total_rows * 100);
    }
}

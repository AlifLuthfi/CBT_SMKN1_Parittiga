<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class ExamTimeExtension extends Model
{
    protected $fillable = ['session_id','extended_by','minutes','reason'];
    public function session()    { return $this->belongsTo(ExamSession::class,'session_id'); }
    public function extendedBy() { return $this->belongsTo(User::class,'extended_by'); }
}

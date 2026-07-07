<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class TeacherProfile extends Model
{
    protected $fillable = ['user_id','signature','preferences'];
    protected $casts    = ['preferences'=>'array'];
    public function user() { return $this->belongsTo(User::class); }
    public function getDefaultPreferences(): array
    {
        return array_merge([
            'default_duration'       => 90,
            'default_passing_grade'  => 70,
            'default_max_violations' => 5,
            'randomize_by_default'   => true,
        ], $this->preferences ?? []);
    }
}

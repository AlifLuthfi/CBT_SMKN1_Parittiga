<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'name','email','password','role','status',
        'nip','nis','avatar','last_login_at',
    ];

    protected $hidden = ['password','remember_token'];

    protected function casts(): array
    {
        return [
            'last_login_at' => 'datetime',
            'password'      => 'hashed',
        ];
    }

    public function classRooms()      { return $this->hasMany(ClassRoom::class,'teacher_id'); }
    public function enrolledClasses() { return $this->belongsToMany(ClassRoom::class,'class_student','student_id','class_id')->withPivot('status','enrolled_at')->withTimestamps(); }
    public function questions()       { return $this->hasMany(Question::class,'teacher_id'); }
    public function exams()           { return $this->hasMany(Exam::class,'teacher_id'); }
    public function examSessions()    { return $this->hasMany(ExamSession::class,'student_id'); }
    public function violations()      { return $this->hasMany(Violation::class,'student_id'); }
    public function notifications()   { return $this->hasMany(Notification::class); }
    public function teacherProfile()  { return $this->hasOne(TeacherProfile::class); }
    public function activityLogs()    { return $this->hasMany(ActivityLog::class); }

    public function scopeGuru($q)   { return $q->where('role','guru'); }
    public function scopeSiswa($q)  { return $q->where('role','siswa'); }
    public function scopeAdmin($q)  { return $q->where('role','admin'); }
    public function scopeActive($q) { return $q->where('status','active'); }

    public function isGuru():  bool { return $this->role === 'guru'; }
    public function isSiswa(): bool { return $this->role === 'siswa'; }
    public function isAdmin(): bool { return $this->role === 'admin'; }
}

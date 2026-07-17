<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Exam;
use App\Models\ExamSession;
use App\Models\ClassRoom;
use App\Models\User;
use App\Models\Violation;
use App\Services\ExamSchedulerService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    public function __construct(private ExamSchedulerService $scheduler) {}

    public function dashboard()
    {
        return response()->json([
            'stats' => [
                'guru'         => User::guru()->count(),
                'siswa'        => User::siswa()->count(),
                'kelas'        => ClassRoom::count(),
                'ujian_aktif'  => Exam::where('status','active')->count(),
                'total_ujian'  => Exam::count(),
                'viol_today'   => Violation::whereDate('created_at', today())->count(),
            ],
            'guru'     => User::guru()->withCount(['exams','questions','classRooms'])->latest()->take(10)->get(),
            'exams'    => Exam::with(['teacher','classRoom'])->withCount('sessions')->latest()->take(10)->get(),
            'violations'=> Violation::with(['student','session.exam'])->whereDate('created_at',today())->orderByDesc('updated_at')->take(5)->get(),
            'activities'=> ActivityLog::with('user')->latest()->take(10)->get(),
        ]);
    }

    public function users(Request $request)
    {
        $users = User::with(['teacherProfile', 'classRooms', 'enrolledClasses'])
            ->when($request->role,   fn($q,$v) => $q->where('role',$v))
            ->when($request->status, fn($q,$v) => $q->where('status',$v))
            ->when($request->search, fn($q,$v) => $q->where(fn($q) => $q->where('name','like',"%$v%")->orWhere('email','like',"%$v%")))
            ->when($request->level, fn($q,$v) => $q->whereHas('enrolledClasses', fn($q) => $q->where('level', $v)))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 15);
        return response()->json($users);
    }

    public function createUser(Request $request)
    {
        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|min:8',
            'role'     => 'required|in:admin,guru,siswa',
            'nip'      => 'nullable|string|unique:users,nip',
            'nis'      => 'nullable|string|unique:users,nis',
        ]);
        $data['password'] = Hash::make($data['password']);
        $user = User::create($data);

        ActivityLog::create(['user_id'=>auth()->id(),'action'=>'user_created','description'=>"Akun {$user->role} baru: {$user->name}"]);

        return response()->json(['message'=>'Akun berhasil dibuat.','user'=>$user], 201);
    }

    public function updateUser(Request $request, User $user)
    {
        $data = $request->validate([
            'name'     => 'sometimes|string|max:255',
            'email'    => "sometimes|email|unique:users,email,{$user->id}",
            'status'   => 'sometimes|in:active,inactive',
            'role'     => 'sometimes|in:admin,guru,siswa',
            'password' => 'sometimes|string|min:8',
        ]);
        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }
        $user->update($data);
        return response()->json(['message'=>'Akun diperbarui.','user'=>$user->fresh()]);
    }

    public function gantiPassword(Request $request, User $user)
    {
        $data = $request->validate(['password'=>'required|min:8']);
        $user->update(['password'=>Hash::make($data['password'])]);
        ActivityLog::create(['user_id'=>auth()->id(),'action'=>'ganti_password','description'=>"Ganti password: {$user->name}"]);
        return response()->json(['message'=>"Password {$user->name} berhasil diganti."]);
    }

    public function toggleStatus(User $user)
    {
        if ($user->id === auth()->id()) {
            return response()->json(['message'=>'Tidak bisa mengubah status akun sendiri.'], 403);
        }
        $user->update(['status' => $user->status === 'active' ? 'inactive' : 'active']);
        return response()->json(['message'=>"Akun {$user->name} {$user->status}.",'user'=>$user]);
    }

    public function deleteUser(User $user)
    {
        if ($user->id === auth()->id()) {
            return response()->json(['message'=>'Tidak bisa menghapus akun sendiri.'], 403);
        }
        $user->delete();
        return response()->json(['message'=>"Akun {$user->name} dihapus."]);
    }

    public function classes()
    {
        return response()->json(['data' => ClassRoom::with(['teacher'])->withCount(['students','exams'])->orderBy('level')->orderBy('name')->get()]);
    }

    public function createClass(Request $request)
    {
        $data = $request->validate([
            'teacher_id'    => 'required|exists:users,id',
            'name'          => 'required|string|max:100',
            'subject'       => 'required|string|max:100',
            'academic_year' => 'nullable|string|max:20',
            'semester'      => 'nullable|string|max:20',
            'description'   => 'nullable|string',
        ]);

        $teacher = User::where('id', $data['teacher_id'])->where('role', 'guru')->firstOrFail();
        $class = ClassRoom::create(array_merge($data, ['teacher_id' => $teacher->id]));

        ActivityLog::create(['user_id'=>auth()->id(),'action'=>'class_created','description'=>"Kelas baru: {$class->name}"]);

        return response()->json(['message'=>'Kelas berhasil dibuat.','class'=>$class->load('teacher')], 201);
    }

    public function exams(Request $request)
    {
        $exams = Exam::with(['teacher','classRoom'])
            ->when($request->status, fn($q,$v) => $q->where('status',$v))
            ->withCount([
                'sessions',
                'sessions as submitted_count' => fn($q) => $q->whereIn('status', ['submitted','timeout','force_submitted']),
            ])
            ->latest()->paginate(20);
        return response()->json($exams);
    }

    public function activateExam(Exam $exam)
    {
        if (!in_array($exam->status, ['draft','scheduled'])) {
            return response()->json(['message'=>'Ujian sudah aktif atau selesai.'], 422);
        }
        $exam->update(['status'=>'active','start_time'=>$exam->start_time ?? now()]);

        ActivityLog::create([
            'user_id'=>auth()->id(),
            'action'=>'exam_activated',
            'description'=>"Ujian {$exam->title} diaktifkan oleh admin.",
        ]);

        return response()->json(['message'=>'Ujian diaktifkan.','exam'=>$exam->fresh()->load(['teacher','classRoom'])]);
    }

    public function endExam(Exam $exam)
    {
        $this->scheduler->endExam($exam);

        ActivityLog::create([
            'user_id'=>auth()->id(),
            'action'=>'exam_ended',
            'description'=>"Ujian {$exam->title} diakhiri oleh admin.",
        ]);

        return response()->json(['message'=>'Ujian diakhiri.']);
    }

    public function violations(Request $request)
    {
        $viols = Violation::with(['student','session.exam.classRoom'])
            ->when($request->class_id, fn($q, $v) => $q->whereHas('session.exam', fn($q) => $q->where('class_id', $v)))
            ->latest()->paginate(20);
        return response()->json($viols);
    }

    public function activityLogs()
    {
        return response()->json(['data' => ActivityLog::with('user')->latest()->take(50)->get()]);
    }

    public function updateClass(Request $request, ClassRoom $class)
    {
        $data = $request->validate([
            'name'          => 'sometimes|string|max:100',
            'subject'       => 'sometimes|string|max:100',
            'academic_year' => 'nullable|string|max:20',
            'semester'      => 'nullable|string|max:20',
            'description'   => 'nullable|string',
        ]);

        $class->update($data);

        ActivityLog::create(['user_id'=>auth()->id(),'action'=>'class_updated','description'=>"Kelas diperbarui: {$class->name}"]);

        return response()->json(['message'=>'Kelas berhasil diperbarui.','class'=>$class->fresh()->load('teacher')]);
    }

    public function deleteClass(ClassRoom $class)
    {
        $name = $class->name;
        $class->delete();

        ActivityLog::create(['user_id'=>auth()->id(),'action'=>'class_deleted','description'=>"Kelas dihapus: {$name}"]);

        return response()->json(['message'=>"Kelas {$name} berhasil dihapus."]);
    }

    public function updateStudentClass(Request $request, User $user)
    {
        if (!$user->isSiswa()) {
            return response()->json(['message'=>'Hanya siswa yang bisa diubah kelasnya.'], 422);
        }

        $data = $request->validate([
            'class_id' => 'required|exists:classes,id',
        ]);

        // Deactivate from current active class
        $user->enrolledClasses()
            ->wherePivot('status', 'active')
            ->update(['status' => 'inactive']);

        // Enroll to new class
        $user->enrolledClasses()->syncWithoutDetaching([
            $data['class_id'] => ['status'=>'active', 'enrolled_at'=>now(), 'enrolled_by'=>auth()->id()]
        ]);

        ActivityLog::create([
            'user_id'=>auth()->id(),
            'action'=>'student_class_updated',
            'description'=>"Kelas siswa {$user->name} diperbarui ke kelas ID {$data['class_id']}",
        ]);

        return response()->json([
            'message'=>'Kelas siswa berhasil diperbarui.',
            'user'=>$user->fresh()->load('enrolledClasses'),
        ]);
    }

    public function exportUsers()
    {
        $users = User::all(['name','email','role','status','created_at']);
        $csv   = "Nama,Email,Role,Status,Terdaftar\n";
        foreach ($users as $u) {
            $csv .= "\"{$u->name}\",\"{$u->email}\",{$u->role},{$u->status},{$u->created_at}\n";
        }
        return response($csv, 200, [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => 'attachment; filename="data-users.csv"',
        ]);
    }
}

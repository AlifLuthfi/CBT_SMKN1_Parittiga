<?php
namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ClassRoom;
use App\Models\Exam;
use App\Models\Violation;
use App\Models\ActivityLog;
use App\Models\ExamSession;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminWebController extends Controller
{
    // ── Users ──────────────────────────────────────────────
    public function users(Request $request)
    {
        $users = User::with(['enrolledClasses', 'classRooms'])
            ->when($request->role, fn($q, $v) => $q->where('role', $v))
            ->when($request->level, fn($q, $v) => $q->whereHas('enrolledClasses', fn($q) => $q->where('level', $v)))
            ->when($request->search, fn($q, $v) => $q->where('name', 'like', "%{$v}%"))
            ->orderBy('name')->paginate(20)->withQueryString();
        $classes = ClassRoom::orderBy('level')->orderBy('name')->get();

        // stats for cards
        $allUsers = User::selectRaw("role, status, COUNT(*) as total")->groupBy('role', 'status')->get();
        $stats = [
            'total'   => $allUsers->sum('total'),
            'admin'   => $allUsers->where('role','admin')->sum('total'),
            'guru'    => $allUsers->where('role','guru')->sum('total'),
            'siswa'   => $allUsers->where('role','siswa')->sum('total'),
            'active'  => $allUsers->where('status','active')->sum('total'),
            'inactive'=> $allUsers->where('status','inactive')->sum('total'),
            'adminActive'  => $allUsers->where('role','admin')->where('status','active')->sum('total'),
            'guruActive'   => $allUsers->where('role','guru')->where('status','active')->sum('total'),
            'siswaActive'  => $allUsers->where('role','siswa')->where('status','active')->sum('total'),
        ];

        return view('admin.users.index', compact('users', 'classes', 'stats'));
    }

    public function createUser(Request $request)
    {
        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|min:6',
            'role'     => 'required|in:admin,guru,siswa',
            'nip'      => 'nullable|string',
            'nis'      => 'nullable|string',
        ]);
        $data['password'] = Hash::make($data['password']);
        $user = User::create($data);

        if ($request->filled('class_id') && $user->isSiswa()) {
            $user->enrolledClasses()->attach($request->class_id, ['status' => 'active', 'enrolled_at' => now()]);
        }

        ActivityLog::create(['user_id' => auth()->id(), 'action' => 'create_user', 'description' => "Buat user {$user->name}"]);
        return back()->with('success', 'User berhasil dibuat.');
    }

    public function updateUser(Request $request, User $user)
    {
        $data = $request->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->id,
            'role'  => 'required|in:admin,guru,siswa',
            'nip'   => 'nullable|string',
        ]);
        // map nip → nis when role is siswa
        if ($request->role === 'siswa') {
            $data['nis'] = $data['nip'] ?? null;
            unset($data['nip']);
        }
        $user->update($data);

        if ($user->isSiswa()) {
            if ($request->filled('class_id')) {
                $user->enrolledClasses()->sync([$request->class_id => ['status' => 'active', 'enrolled_at' => now()]]);
            } else {
                $user->enrolledClasses()->detach();
            }
        } elseif ($user->isGuru()) {
            $classIds = $request->input('class_ids', []);
            if (!is_array($classIds)) $classIds = [];
            ClassRoom::whereIn('id', $classIds)->update(['teacher_id' => $user->id]);
            ClassRoom::where('teacher_id', $user->id)->whereNotIn('id', $classIds)->update(['teacher_id' => null]);
        }

        ActivityLog::create(['user_id' => auth()->id(), 'action' => 'update_user', 'description' => "Update user {$user->name}"]);
        return back()->with('success', 'User berhasil diupdate.');
    }

    public function gantiPassword(Request $request, User $user)
    {
        $validated = $request->validate(['password' => 'nullable|min:8']);
        $password = $validated['password'] ?? 'password';
        $user->update(['password' => Hash::make($password)]);
        return back()->with('success', "Password {$user->name} diganti.");
    }

    public function toggleStatus(User $user)
    {
        $user->update(['status' => $user->status === 'active' ? 'inactive' : 'active']);
        return back()->with('success', "Status {$user->name} diubah.");
    }

    public function deleteUser(User $user)
    {
        if ($user->isAdmin()) return back()->with('error', 'Tidak bisa hapus admin.');
        $user->delete();
        return back()->with('success', 'User dihapus.');
    }

    // ── Classes ────────────────────────────────────────────
    public function classes()
    {
        $classes = ClassRoom::with(['teacher', 'students'])->withCount('students')->orderBy('level')->orderBy('name')->paginate(20);
        $gurus = User::where('role', 'guru')->active()->get();
        return view('admin.classes.index', compact('classes', 'gurus'));
    }

    public function createClass(Request $request)
    {
        $data = $request->validate([
            'teacher_id'    => 'required|exists:users,id',
            'name'          => 'required|string|max:255',
            'subject'       => 'required|string|max:255',
            'level'         => 'required|in:10,11,12',
            'academic_year' => 'required|string',
            'semester'      => 'required|string',
            'description'   => 'nullable|string',
        ]);
        ClassRoom::create($data);
        return back()->with('success', 'Kelas berhasil dibuat.');
    }

    public function updateClass(Request $request, ClassRoom $class)
    {
        $data = $request->validate([
            'name'          => 'required|string|max:255',
            'subject'       => 'required|string|max:255',
            'level'         => 'required|in:10,11,12',
            'academic_year' => 'required|string',
            'semester'      => 'required|string',
            'description'   => 'nullable|string',
        ]);
        $class->update($data);
        return back()->with('success', 'Kelas berhasil diupdate.');
    }

    public function deleteClass(ClassRoom $class)
    {
        $class->delete();
        return back()->with('success', 'Kelas dihapus.');
    }

    // ── Exams ──────────────────────────────────────────────
    public function exams()
    {
        $exams = Exam::with(['teacher', 'classRoom'])->latest()->paginate(20);
        return view('admin.exams.index', compact('exams'));
    }

    public function activateExam(Exam $exam)
    {
        $exam->update(['status' => 'active']);
        ActivityLog::create(['user_id' => auth()->id(), 'action' => 'activate_exam', 'description' => "Aktivasi ujian {$exam->title}"]);
        return back()->with('success', 'Ujian diaktifkan.');
    }

    public function endExam(Exam $exam)
    {
        $exam->update(['status' => 'ended']);
        ExamSession::where('exam_id', $exam->id)->where('status', 'in_progress')->update(['status' => 'force_submitted', 'submitted_at' => now()]);
        return back()->with('success', 'Ujian diakhiri.');
    }

    public function deleteExam(Exam $exam)
    {
        $exam->delete();
        ActivityLog::create(['user_id' => auth()->id(), 'action' => 'delete_exam', 'description' => "Hapus ujian {$exam->title}"]);
        return back()->with('success', 'Ujian dihapus.');
    }

    // ── Violations ─────────────────────────────────────────
    public function violations(Request $request)
    {
        $violations = Violation::with(['session.exam.classRoom', 'student'])
            ->when($request->class_id, fn($q, $v) => $q->whereHas('session.exam', fn($q) => $q->where('class_id', $v)))
            ->latest()->paginate(30);
        $classes = ClassRoom::orderBy('level')->orderBy('name')->get();
        return view('admin.violations.index', compact('violations', 'classes'));
    }

    // ── Logs ───────────────────────────────────────────────
    public function logs()
    {
        $logs = ActivityLog::with('user')->latest()->paginate(50);
        return view('admin.logs.index', compact('logs'));
    }
}

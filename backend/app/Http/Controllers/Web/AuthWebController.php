<?php
namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ExamSession;
use App\Models\Exam;
use App\Models\Violation;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;

class AuthWebController extends Controller
{
    public function splash()
    {
        $nextUrl = auth()->check() ? '/dashboard' : '/login';
        return view('splash', compact('nextUrl'));
    }

    public function loginForm()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            /** @var \App\Models\User $user */
            $user = Auth::user();
            if ($user->status !== 'active') {
                Auth::logout();
                return back()->with('error', 'Akun Anda tidak aktif. Hubungi admin.');
            }
            $user->update(['last_login_at' => now()]);

            ActivityLog::create([
                'user_id'     => $user->id,
                'action'      => 'login',
                'description' => "{$user->name} login",
                'ip_address'  => $request->ip(),
                'user_agent'  => $request->userAgent(),
            ]);

            $request->session()->regenerate();
            return redirect()->intended('/dashboard');
        }

        return back()->withErrors(['email' => 'Email atau password salah.'])->onlyInput('email');
    }

    public function logout(Request $request)
    {
        $user = Auth::user();
        if ($user) {
            ActivityLog::create([
                'user_id'     => $user->id,
                'action'      => 'logout',
                'description' => "{$user->name} logout",
                'ip_address'  => $request->ip(),
            ]);
        }
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/login');
    }

    public function dashboard()
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $role = $user->role;

        if ($role === 'admin') {
            $data = Cache::remember('web_admin_dashboard', 300, fn() => [
                'totalUsers'   => User::count(),
                'activeExams'  => Exam::where('status', 'active')->count(),
                'totalSiswa'   => User::where('role', 'siswa')->count(),
                'totalGuru'    => User::where('role', 'guru')->count(),
                'openViolations' => Violation::where('status', 'open')->count(),
                'submissionsToday' => ExamSession::whereDate('submitted_at', today())->count(),
            ]);
            $exams = Exam::with(['teacher', 'classRoom'])->latest()->paginate(20);

            return view('dashboard.admin', array_merge($data, compact('exams')));
        }

        if ($role === 'guru') {
            $cacheKey = "web_guru_dashboard_{$user->id}";
            $data = Cache::remember($cacheKey, 300, fn() => [
                'totalQuestions' => $user->questions()->count(),
                'totalExams'     => $user->exams()->count(),
                'activeExams'    => $user->exams()->where('status', 'active')->count(),
                'totalClasses'   => $user->classRooms()->count(),
                'totalSubjects'  => \App\Models\Subject::where('teacher_id', $user->id)->count(),
                'totalStudents'  => \App\Models\ClassRoom::where('teacher_id', $user->id)->withCount('students')->get()->sum('students_count'),
                'examSessions'   => ExamSession::whereIn('exam_id', $user->exams()->pluck('id'))->count(),
            ]);
            $recentExams = $user->exams()->with('classRoom')->latest()->take(5)->get();

            return view('dashboard.guru', array_merge($data, compact('recentExams')));
        }

        // Siswa
        $classIds = $user->enrolledClasses()->pluck('classes.id');
        $availableExams = Exam::whereIn('class_id', $classIds)->where('status', 'active')->count();
        $history = ExamSession::where('student_id', $user->id)
            ->whereIn('status', ['submitted', 'timeout', 'force_submitted'])
            ->with('exam')
            ->latest('submitted_at')
            ->take(5)
            ->get();
        $totalDone  = ExamSession::where('student_id', $user->id)->whereIn('status', ['submitted', 'timeout', 'force_submitted'])->count();
        $totalPassed = ExamSession::where('student_id', $user->id)->where('is_passed', true)->count();
        $avgScore   = ExamSession::where('student_id', $user->id)->whereNotNull('score')->avg('score');

        return view('dashboard.siswa', compact(
            'availableExams', 'history', 'totalDone', 'totalPassed', 'avgScore'
        ));
    }
}

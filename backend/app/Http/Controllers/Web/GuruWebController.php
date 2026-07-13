<?php
namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Question;
use App\Models\QuestionCategory;
use App\Models\Subject;
use App\Models\QuestionPackage;
use App\Models\Exam;
use App\Models\ClassRoom;
use App\Models\ExamSession;
use App\Models\StudentGradeReport;
use App\Models\ActivityLog;
use App\Models\QuestionImport;
use App\Services\QuestionImportService;
use Illuminate\Http\Request;

class GuruWebController extends Controller
{
    // ── Questions ──────────────────────────────────────────
    public function questions()
    {
        $user = auth()->user();
        $questions = Question::where('teacher_id', $user->id)
            ->with(['subject', 'category'])
            ->latest()
            ->paginate(20);
        $categories = QuestionCategory::where('teacher_id', $user->id)->get();
        $subjects   = Subject::where('teacher_id', $user->id)->get();
        return view('guru.questions.index', compact('questions', 'categories', 'subjects'));
    }

    public function storeQuestion(Request $request)
    {
        $data = $request->validate([
            'subject_id'     => 'nullable|exists:subjects,id',
            'category_id'    => 'nullable|exists:question_categories,id',
            'question_text'  => 'required|string',
            'options'        => 'required|array',
            'correct_answer' => 'required|string|max:10',
            'explanation'    => 'nullable|string',
            'difficulty'     => 'required|in:easy,medium,hard',
            'weight'         => 'nullable|numeric|min:0|max:999.99',
            'image'          => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);
        $data['teacher_id']    = auth()->id();
        $data['question_type'] = 'multiple_choice';
        $data['weight'] = $data['weight'] ?? 1;

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('questions', 'public');
        }

        Question::create($data);
        return back()->with('success', 'Soal berhasil ditambahkan.');
    }

    public function updateQuestion(Request $request, Question $question)
    {
        if ($question->teacher_id !== auth()->id()) abort(403);
        $data = $request->validate([
            'subject_id'     => 'nullable|exists:subjects,id',
            'category_id'    => 'nullable|exists:question_categories,id',
            'question_text'  => 'required|string',
            'options'        => 'required|array',
            'correct_answer' => 'required|string|max:10',
            'explanation'    => 'nullable|string',
            'difficulty'     => 'required|in:easy,medium,hard',
            'weight'         => 'nullable|numeric|min:0|max:999.99',
            'image'          => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            'remove_image'   => 'nullable|boolean',
        ]);
        $data['question_type'] = 'multiple_choice';

        if ($request->boolean('remove_image')) {
            if ($question->image_path) {
                \Storage::disk('public')->delete($question->image_path);
            }
            $data['image_path'] = null;
        } elseif ($request->hasFile('image')) {
            if ($question->image_path) {
                \Storage::disk('public')->delete($question->image_path);
            }
            $data['image_path'] = $request->file('image')->store('questions', 'public');
        }

        $question->update($data);
        return back()->with('success', 'Soal berhasil diupdate.');
    }

    public function deleteQuestion(Question $question)
    {
        if ($question->teacher_id !== auth()->id()) abort(403);
        $question->delete();
        return back()->with('success', 'Soal dihapus.');
    }

    // ── Subjects ───────────────────────────────────────────
    public function subjects()
    {
        $user = auth()->user();
        $subjects = Subject::where('teacher_id', $user->id)->withCount('questions')->get();
        return view('guru.subjects.index', compact('subjects'));
    }

    public function storeSubject(Request $request)
    {
        $data = $request->validate(['name' => 'required|string|max:255']);
        $data['teacher_id'] = auth()->id();
        Subject::create($data);
        return back()->with('success', 'Mata pelajaran ditambahkan.');
    }

    public function updateSubject(Request $request, Subject $subject)
    {
        if ($subject->teacher_id !== auth()->id()) abort(403);
        $subject->update($request->validate(['name' => 'required|string|max:255']));
        return back()->with('success', 'Mata pelajaran diupdate.');
    }

    public function deleteSubject(Subject $subject)
    {
        if ($subject->teacher_id !== auth()->id()) abort(403);
        if ($subject->questions()->count() > 0) return back()->with('error', 'Masih ada soal terkait.');
        $subject->delete();
        return back()->with('success', 'Mata pelajaran dihapus.');
    }

    // ── Packages ───────────────────────────────────────────
    public function packages()
    {
        $user = auth()->user();
        $packages = QuestionPackage::where('teacher_id', $user->id)
            ->with(['classRoom', 'questions'])
            ->withCount('questions')
            ->latest()
            ->paginate(20);
        $classes  = ClassRoom::where('teacher_id', $user->id)->get();
        return view('guru.packages.index', compact('packages', 'classes'));
    }

    public function storePackage(Request $request)
    {
        $data = $request->validate([
            'title'       => 'required|string|max:255',
            'subject'     => 'required|string|max:255',
            'class_id'    => 'required|exists:classes,id',
            'description' => 'nullable|string',
        ]);
        $data['teacher_id'] = auth()->id();
        $package = QuestionPackage::create($data);

        if ($request->filled('question_ids')) {
            $ids = explode(',', $request->question_ids);
            $order = 0;
            foreach ($ids as $id) {
                if (trim($id)) $package->questions()->attach(trim($id), ['display_order' => $order++]);
            }
        }
        return back()->with('success', 'Paket soal dibuat.');
    }

    public function deletePackage(QuestionPackage $package)
    {
        if ($package->teacher_id !== auth()->id()) abort(403);
        $package->delete();
        return back()->with('success', 'Paket soal dihapus.');
    }

    // ── Exams ──────────────────────────────────────────────
    public function exams()
    {
        $user = auth()->user();
        $exams = Exam::where('teacher_id', $user->id)
            ->with(['classRoom', 'package'])
            ->withCount('questions')
            ->latest()
            ->paginate(20);
        $classes  = ClassRoom::where('teacher_id', $user->id)->get();
        $packages = QuestionPackage::where('teacher_id', $user->id)->get();
        $subjects = Subject::where('teacher_id', $user->id)->get();
        return view('guru.exams.index', compact('exams', 'classes', 'packages', 'subjects'));
    }

    public function storeExam(Request $request)
    {
        $data = $request->validate([
            'title'               => 'required|string|max:255',
            'description'         => 'nullable|string',
            'class_id'            => 'required|exists:classes,id',
            'duration_minutes'    => 'required|integer|min:1',
            'passing_grade'       => 'required|numeric|min:0|max:100',
            'total_questions'     => 'required|integer|min:1',
            'randomize_questions' => 'boolean',
            'randomize_options'   => 'boolean',
            'show_result_immediately' => 'boolean',
            'allow_review'        => 'boolean',
            'max_violations'      => 'integer|min:1',
            'package_id'          => 'nullable|exists:question_packages,id',
        ]);
        $data['teacher_id'] = auth()->id();
        $data['randomize_questions'] = $request->boolean('randomize_questions');
        $data['randomize_options']   = $request->boolean('randomize_options');
        $data['show_result_immediately'] = $request->boolean('show_result_immediately');
        $data['allow_review']        = $request->boolean('allow_review');
        $data['max_violations']      = $request->max_violations ?? 5;
        Exam::create($data);
        return back()->with('success', 'Ujian berhasil dibuat.');
    }

    public function updateExam(Request $request, Exam $exam)
    {
        if ($exam->teacher_id !== auth()->id()) abort(403);
        $data = $request->validate([
            'title'               => 'required|string|max:255',
            'description'         => 'nullable|string',
            'duration_minutes'    => 'required|integer|min:1',
            'passing_grade'       => 'required|numeric|min:0|max:100',
            'total_questions'     => 'required|integer|min:1',
            'randomize_questions' => 'boolean',
            'randomize_options'   => 'boolean',
            'show_result_immediately' => 'boolean',
            'allow_review'        => 'boolean',
            'max_violations'      => 'integer|min:1',
        ]);
        $data['randomize_questions'] = $request->boolean('randomize_questions');
        $data['randomize_options']   = $request->boolean('randomize_options');
        $data['show_result_immediately'] = $request->boolean('show_result_immediately');
        $data['allow_review']        = $request->boolean('allow_review');
        $exam->update($data);
        return back()->with('success', 'Ujian berhasil diupdate.');
    }

    public function deleteExam(Exam $exam)
    {
        if ($exam->teacher_id !== auth()->id()) abort(403);
        $exam->delete();
        return back()->with('success', 'Ujian dihapus.');
    }

    public function scheduleExam(Request $request, Exam $exam)
    {
        if ($exam->teacher_id !== auth()->id()) abort(403);
        $data = $request->validate([
            'start_time' => 'required|date',
            'end_time'   => 'required|date|after:start_time',
        ]);
        $data['status'] = 'scheduled';
        $exam->update($data);
        return back()->with('success', 'Ujian dijadwalkan.');
    }

    public function addQuestionsToExam(Request $request, Exam $exam)
    {
        if ($exam->teacher_id !== auth()->id()) abort(403);
        $ids = explode(',', $request->question_ids);
        $order = $exam->questions()->count();
        foreach ($ids as $id) {
            if (trim($id) && !$exam->questions()->where('question_id', trim($id))->exists()) {
                $exam->questions()->attach(trim($id), ['display_order' => $order++, 'is_active' => true]);
            }
        }
        return back()->with('success', 'Soal ditambahkan ke ujian.');
    }

    // ── Classes ────────────────────────────────────────────
    public function classes()
    {
        $user = auth()->user();
        $classes = ClassRoom::where('teacher_id', $user->id)
            ->withCount('students')
            ->with('students')
            ->orderBy('level')
            ->get();
        return view('guru.classes.index', compact('classes'));
    }

    // ── Grade Reports ──────────────────────────────────────
    public function gradeReports()
    {
        $user = auth()->user();
        $classIds = ClassRoom::where('teacher_id', $user->id)->pluck('id');
        $reports = StudentGradeReport::whereIn('class_id', $classIds)
            ->with(['student', 'classRoom'])
            ->latest()
            ->paginate(20);
        $classes = ClassRoom::where('teacher_id', $user->id)->get();
        return view('guru.grade-reports.index', compact('reports', 'classes'));
    }

    public function classGradeReport(ClassRoom $class)
    {
        if ($class->teacher_id !== auth()->id()) abort(403);
        $exams = Exam::where('class_id', $class->id)->with(['sessions'])->get();
        $students = $class->students()->with(['examSessions' => function ($q) use ($class) {
            $q->whereIn('exam_id', Exam::where('class_id', $class->id)->pluck('id'));
        }])->get();
        return view('guru.grade-reports.class', compact('class', 'exams', 'students'));
    }

    // ── Import Soal ───────────────────────────────────────
    public function importForm()
    {
        $categories = QuestionCategory::where('teacher_id', auth()->id())->get();
        $subjects   = Subject::where('teacher_id', auth()->id())->get();
        return view('guru.questions.import', compact('categories', 'subjects'));
    }

    public function importPreview(Request $request, QuestionImportService $service)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt,xlsx,xls|max:10240',
        ]);

        $result = $service->preview(
            $request->file('file'),
            $request->user()->id
        );

        return response()->json($result);
    }

    public function importExecute(Request $request, QuestionImportService $service)
    {
        $request->validate([
            'file'        => 'required|file|mimes:csv,txt,xlsx,xls|max:10240',
            'subject_id'  => 'nullable|exists:subjects,id',
        ]);

        $result = $service->import(
            $request->file('file'),
            $request->user()->id,
            $request->category_id,
            $request->subject_id
        );

        return response()->json([
            'message'      => "Import selesai. {$result->success_count} soal berhasil, {$result->error_count} error.",
            'import'       => $result,
            'has_errors'   => $result->error_count > 0,
            'error_detail' => $result->errors ?? [],
        ]);
    }

    public function importHistory()
    {
        $imports = QuestionImport::where('teacher_id', auth()->id())
            ->orderByDesc('created_at')
            ->take(20)
            ->get()
            ->map(fn($i) => [
                'id'            => $i->id,
                'filename'      => $i->filename,
                'status'        => $i->status,
                'total_rows'    => $i->total_rows,
                'success_count' => $i->success_count,
                'error_count'   => $i->error_count,
                'has_errors'    => $i->error_count > 0,
                'error_detail'  => $i->errors ?? [],
                'created_at'    => $i->created_at->toIso8601String(),
            ]);

        return response()->json(['data' => $imports]);
    }
}

<?php
namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Question;
use App\Models\Subject;
use App\Models\Exam;
use App\Models\ClassRoom;
use App\Models\QuestionImport;
use App\Models\StudentGradeReport;
use App\Services\QuestionImportService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class GuruWebController extends Controller
{
    // ── Questions ──────────────────────────────────────────
    public function questions()
    {
        $user = Auth::user();
        $questions = Question::where('teacher_id', $user->id)
            ->with('subject')
            ->latest()
            ->paginate(20);
        $allSubjects = Subject::where('teacher_id', $user->id)->get();
        return view('guru.questions.index', compact('questions', 'allSubjects'));
    }

    public function storeQuestion(Request $request)
    {
        $request->merge([
            'subject_id' => $request->filled('subject_id') ? $request->subject_id : null,
        ]);
        $data = $request->validate([
            'subject_id'     => 'nullable|exists:subjects,id',
            'question_text'  => 'required|string',
            'options'        => 'required|array',
            'correct_answer' => 'required|string|max:10',
            'explanation'    => 'nullable|string',
            'image'          => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);
        $data['teacher_id']    = Auth::id();
        $data['question_type'] = 'multiple_choice';

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('questions', 'public');
        }

        Question::create($data);
        return back()->with('success', 'Soal berhasil ditambahkan.');
    }

    public function updateQuestion(Request $request, Question $question)
    {
        if ($question->teacher_id !== Auth::id()) abort(403);
        $request->merge([
            'subject_id' => $request->filled('subject_id') ? $request->subject_id : null,
        ]);
        $data = $request->validate([
            'subject_id'     => 'nullable|exists:subjects,id',
            'question_text'  => 'required|string',
            'options'        => 'required|array',
            'correct_answer' => 'required|string|max:10',
            'explanation'    => 'nullable|string',
            'image'          => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            'remove_image'   => 'nullable|boolean',
        ]);
        $data['question_type'] = 'multiple_choice';

        if ($request->boolean('remove_image')) {
            if ($question->image_path) {
                Storage::disk('public')->delete($question->image_path);
            }
            $data['image_path'] = null;
        } elseif ($request->hasFile('image')) {
            if ($question->image_path) {
                Storage::disk('public')->delete($question->image_path);
            }
            $data['image_path'] = $request->file('image')->store('questions', 'public');
        }

        $question->update($data);
        return back()->with('success', 'Soal berhasil diupdate.');
    }

    public function deleteQuestion(Question $question)
    {
        if ($question->teacher_id !== Auth::id()) abort(403);
        $question->delete();
        return back()->with('success', 'Soal dihapus.');
    }

    // ── Subject-specific Questions ─────────────────────────
    public function subjectQuestions(Subject $subject)
    {
        if ($subject->teacher_id !== Auth::id()) abort(403);
        $questions = Question::where('teacher_id', Auth::id())
            ->where('subject_id', $subject->id)
            ->with('subject')
            ->latest()
            ->paginate(20);
        $allSubjects = Subject::where('teacher_id', Auth::id())->get();
        return view('guru.questions.index', compact('questions', 'subject', 'allSubjects'));
    }

    // ── Subjects ───────────────────────────────────────────
    public function subjects()
    {
        $user = Auth::user();
        $subjects = Subject::where('teacher_id', $user->id)->withCount('questions')->get();
        return view('guru.subjects.index', compact('subjects'));
    }

    public function storeSubject(Request $request)
    {
        $data = $request->validate(['name' => 'required|string|max:255']);
        $data['teacher_id'] = Auth::id();
        Subject::create($data);
        return redirect()->route('guru.subjects')->with('success', 'Mata pelajaran ditambahkan.');
    }

    public function updateSubject(Request $request, Subject $subject)
    {
        if ($subject->teacher_id !== Auth::id()) abort(403);
        $subject->update($request->validate(['name' => 'required|string|max:255']));
        return redirect()->route('guru.subjects')->with('success', 'Mata pelajaran diupdate.');
    }

    public function deleteSubject(Subject $subject)
    {
        if ($subject->teacher_id !== Auth::id()) abort(403);
        if ($subject->questions()->count() > 0) return back()->with('error', 'Masih ada soal terkait.');
        $subject->delete();
        return redirect()->route('guru.subjects')->with('success', 'Mata pelajaran dihapus.');
    }

    // ── Exams ──────────────────────────────────────────────
    public function exams()
    {
        $user = Auth::user();
        $exams = Exam::where('teacher_id', $user->id)
            ->with(['classRoom'])
            ->withCount('questions')
            ->latest()
            ->paginate(20);
        $classes  = ClassRoom::where('teacher_id', $user->id)->orderBy('level')->orderBy('name')->get();
        $subjects = Subject::where('teacher_id', $user->id)->get();
        return view('guru.exams.index', compact('exams', 'classes', 'subjects'));
    }

    public function storeExam(Request $request)
    {
        $data = $request->validate([
            'title'               => 'required|string|max:255',
            'description'         => 'nullable|string',
            'subject_id'          => 'required|exists:subjects,id',
            'class_id'            => 'required|exists:classes,id',
            'duration_minutes'    => 'required|integer|min:1',
            'passing_grade'       => 'required|numeric|min:0|max:100',
            'total_questions'     => 'nullable|integer|min:1',
            'max_violations'      => 'nullable|integer|min:1',
            'start_date'          => 'nullable|string',
            'start_time'          => 'nullable|string',
        ]);
        $data['teacher_id'] = Auth::id();
        // Ambil question IDs dari subject
        $questionIds = \App\Models\Question::where('teacher_id', Auth::id())
            ->where('subject_id', $data['subject_id'])
            ->pluck('id')
            ->toArray();
        $data['total_questions'] = count($questionIds);
        // Gabung start_date + start_time jadi start_time datetime
        if (!empty($request->start_date) && !empty($request->start_time)) {
            $data['start_time'] = $request->start_date . ' ' . $request->start_time . ':00';
            // Auto-hitung end_time = start_time + duration
            $data['end_time'] = date('Y-m-d H:i:s', strtotime($data['start_time'] . ' + ' . $data['duration_minutes'] . ' minutes'));
        } else {
            $data['start_time'] = null;
            $data['end_time'] = null;
        }
        unset($data['start_date']);
        // LCG: acak soal & opsi otomatis, tidak tampilkan hasil
        $data['randomize_questions']     = true;
        $data['randomize_options']       = true;
        $data['show_result_immediately'] = false;
        $data['max_violations']          = $request->max_violations ?? 5;
        $exam = Exam::create($data);
        // Link questions ke exam via pivot
        if ($questionIds) {
            $order = 1;
            foreach ($questionIds as $qId) {
                \App\Models\ExamQuestion::create(['exam_id' => $exam->id, 'question_id' => $qId, 'display_order' => $order++]);
            }
        }
        return back()->with('success', 'Ujian berhasil dibuat.');
    }

    public function updateExam(Request $request, Exam $exam)
    {
        if ($exam->teacher_id !== Auth::id()) abort(403);
        $data = $request->validate([
            'title'               => 'required|string|max:255',
            'description'         => 'nullable|string',
            'duration_minutes'    => 'required|integer|min:1',
            'passing_grade'       => 'required|numeric|min:0|max:100',
            'total_questions'     => 'nullable|integer|min:1',
            'max_violations'      => 'nullable|integer|min:1',
            'start_date'          => 'nullable|string',
            'start_time'          => 'nullable|string',
        ]);
        // Gabung start_date + start_time jadi start_time datetime
        if (!empty($request->start_date) && !empty($request->start_time)) {
            $data['start_time'] = $request->start_date . ' ' . $request->start_time . ':00';
            // Auto-hitung end_time = start_time + duration
            $data['end_time'] = date('Y-m-d H:i:s', strtotime($data['start_time'] . ' + ' . $data['duration_minutes'] . ' minutes'));
        } else {
            $data['start_time'] = null;
            $data['end_time'] = null;
        }
        unset($data['start_date']);
        $data['randomize_questions']     = true;
        $data['randomize_options']       = true;
        $data['show_result_immediately'] = false;
        $exam->update($data);
        return back()->with('success', 'Ujian berhasil diupdate.');
    }

    public function deleteExam(Exam $exam)
    {
        if ($exam->teacher_id !== Auth::id()) abort(403);
        $exam->delete();
        return back()->with('success', 'Ujian dihapus.');
    }

    public function scheduleExam(Request $request, Exam $exam)
    {
        if ($exam->teacher_id !== Auth::id()) abort(403);
        $data = $request->validate([
            'start_date' => 'required|string',
            'start_time' => 'required|string',
            'end_time'   => 'required|string',
        ]);
        $data['start_time'] = $request->start_date . ' ' . $request->start_time . ':00';
        $data['end_time']   = $request->start_date . ' ' . $request->end_time . ':00';
        // Validasi: end_time tidak boleh kurang dari start_time + duration
        $minEnd = date('Y-m-d H:i:s', strtotime($data['start_time'] . ' + ' . $exam->duration_minutes . ' minutes'));
        if ($data['end_time'] < $minEnd) {
            $data['end_time'] = $minEnd;
        }
        $data['status']     = 'scheduled';
        unset($data['start_date']);
        $exam->update($data);
        return back()->with('success', 'Ujian dijadwalkan.');
    }

    public function addQuestionsToExam(Request $request, Exam $exam)
    {
        if ($exam->teacher_id !== Auth::id()) abort(403);
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
        $user = Auth::user();
        $classes = ClassRoom::where('teacher_id', $user->id)
            ->withCount('students')
            ->with('students')
            ->orderBy('level')->orderBy('name')
            ->get();
        return view('guru.classes.index', compact('classes'));
    }

    // ── Grade Reports ──────────────────────────────────────
    public function gradeReports()
    {
        $user = Auth::user();
        $classIds = ClassRoom::where('teacher_id', $user->id)->pluck('id');
        $reports = StudentGradeReport::whereIn('class_id', $classIds)
            ->with(['student', 'classRoom'])
            ->latest()
            ->paginate(20);
        $classes = ClassRoom::where('teacher_id', $user->id)
            ->with('students')
            ->withCount(['students', 'exams'])
            ->orderBy('level')->orderBy('name')
            ->get();
        return view('guru.grade-reports.index', compact('reports', 'classes'));
    }

    public function classGradeReport(ClassRoom $class)
    {
        if ($class->teacher_id !== Auth::id()) abort(403);
        $exams = Exam::where('class_id', $class->id)->with(['sessions'])->get();
        $students = $class->students()->with(['examSessions' => function ($q) use ($class) {
            $q->whereIn('exam_id', Exam::where('class_id', $class->id)->pluck('id'));
        }])->get();
        return view('guru.grade-reports.class', compact('class', 'exams', 'students'));
    }

    // ── Import Soal ───────────────────────────────────────
    public function importForm(Request $request)
    {
        $subjects = Subject::where('teacher_id', Auth::id())->get();
        $subjectId = $request->query('subject_id');
        $subject = $subjectId ? Subject::find($subjectId) : null;
        return view('guru.questions.import', compact('subjects', 'subject'));
    }

    public function downloadTemplate(QuestionImportService $service)
    {
        $path = $service->generateTemplate();
        return response()->download($path, 'template-import-soal.xlsx')->deleteFileAfterSend(true);
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
            'subject_id'  => 'required|exists:subjects,id',
        ]);

        $result = $service->import(
            $request->file('file'),
            $request->user()->id,
            subjectId: $request->subject_id
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
        $imports = QuestionImport::where('teacher_id', Auth::id())
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

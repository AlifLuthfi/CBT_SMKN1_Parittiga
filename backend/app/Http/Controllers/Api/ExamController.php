<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exam;
use App\Models\ExamQuestion;
use App\Services\ExamSchedulerService;
use Illuminate\Http\Request;

class ExamController extends Controller
{
    public function __construct(private ExamSchedulerService $scheduler) {}

    public function index(Request $request)
    {
        $exams = Exam::where('teacher_id', $request->user()->id)
            ->with(['classRoom'])
            ->withCount(['sessions','violations'])
            ->when($request->status,   fn($q,$v) => $q->where('status',$v))
            ->when($request->class_id, fn($q,$v) => $q->where('class_id',$v))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 15);

        return response()->json($exams);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title'                    => 'required|string|max:255',
            'description'              => 'nullable|string',
            'class_id'                 => 'required|exists:classes,id',
            'subject_id'               => 'required|exists:subjects,id',
            'duration_minutes'         => 'required|integer|min:5|max:300',
            'passing_grade'            => 'required|numeric|min:0|max:100',
            'start_time'               => 'nullable|date',
            'end_time'                 => 'nullable|date|after:start_time',
            'auto_activate'            => 'boolean',
            'auto_end'                 => 'boolean',
        ]);

        // LCG otomatis — acak urutan soal & opsi, hasil hanya lihat salah
        $data['randomize_questions']     = true;
        $data['randomize_options']       = true;
        $data['show_result_immediately'] = false;

        $data['teacher_id'] = $request->user()->id;

        // Ambil semua soal dari subject yang dipilih, milik teacher ini
        $questionIds = \App\Models\Question::where('teacher_id', $request->user()->id)
            ->where('subject_id', $data['subject_id'])
            ->pluck('id')
            ->toArray();
        $data['total_questions'] = count($questionIds);

        $exam = Exam::create($data);

        if ($questionIds) {
            $order = 1;
            foreach ($questionIds as $qId) {
                \App\Models\ExamQuestion::create(['exam_id'=>$exam->id,'question_id'=>$qId,'display_order'=>$order++]);
            }
        }

        return response()->json(['message'=>'Ujian dibuat.','exam'=>$exam->load(['classRoom'])], 201);
    }

    public function show(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        return response()->json(['exam'=>$exam->load(['classRoom','questions','sessions.student'])]);
    }

    public function update(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        $data = $request->validate([
            'title'               => 'sometimes|string|max:255',
            'description'         => 'nullable|string',
            'class_id'            => 'sometimes|exists:classes,id',
            'subject_id'          => 'sometimes|exists:subjects,id',
            'duration_minutes'    => 'sometimes|integer|min:5|max:300',
            'passing_grade'       => 'sometimes|numeric|min:0|max:100',
            'status'              => 'sometimes|in:draft,scheduled,active,paused,ended',
            'start_time'          => 'nullable|date',
            'end_time'            => 'nullable|date',
            'auto_activate'       => 'boolean',
            'auto_end'            => 'boolean',
            'randomize_questions' => 'boolean',
            'randomize_options'   => 'boolean',
        ]);
        $exam->update($data);
        return response()->json(['message'=>'Ujian diperbarui.','exam'=>$exam->fresh()->load('classRoom')]);
    }

    public function destroy(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        if ($exam->status === 'active') {
            return response()->json(['message'=>'Ujian aktif tidak dapat dihapus.'], 422);
        }
        $exam->delete();
        return response()->json(['message'=>'Ujian dihapus.']);
    }

    public function schedule(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        $data = $request->validate([
            'start_time'    => 'required|date',
            'end_time'      => 'required|date|after:start_time',
            'auto_activate' => 'boolean',
        ]);
        $exam->update(array_merge($data, ['status'=>'scheduled']));
        return response()->json(['message'=>'Jadwal disimpan.','exam'=>$exam->fresh()]);
    }

    public function pause(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        if ($exam->status !== 'active') {
            return response()->json(['message'=>'Ujian tidak sedang aktif.'], 422);
        }
        $this->scheduler->pauseExam($exam, $request->user()->id, $request->reason ?? '');
        return response()->json(['message'=>'Ujian dijeda.']);
    }

    public function resume(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        if ($exam->status !== 'paused') {
            return response()->json(['message'=>'Ujian tidak dalam status dijeda.'], 422);
        }
        $this->scheduler->resumeExam($exam, $request->user()->id);
        return response()->json(['message'=>'Ujian dilanjutkan.']);
    }

    public function end(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        $this->scheduler->endExam($exam);
        return response()->json(['message'=>'Ujian diakhiri.']);
    }

    public function extendTime(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        $data = $request->validate([
            'student_id' => 'required|exists:users,id',
            'minutes'    => 'required|integer|min:1|max:60',
            'reason'     => 'nullable|string',
        ]);
        $session = \App\Models\ExamSession::where('exam_id',$exam->id)->where('student_id',$data['student_id'])->firstOrFail();
        $this->scheduler->extendTime($session->id, $data['minutes'], $request->user()->id, $data['reason'] ?? '');
        return response()->json(['message'=>"Waktu diperpanjang {$data['minutes']} menit."]);
    }

    public function addQuestions(Request $request, Exam $exam)
    {
        $this->authorizeExam($request, $exam);
        $data = $request->validate(['question_ids'=>'required|array','question_ids.*'=>'exists:questions,id']);
        $added = 0;
        $order = $exam->questions()->count();
        foreach ($data['question_ids'] as $qId) {
            \App\Models\ExamQuestion::firstOrCreate(['exam_id'=>$exam->id,'question_id'=>$qId],['display_order'=>++$order]);
            $added++;
        }
        $exam->update(['total_questions'=>$exam->questions()->count()]);
        return response()->json(['message'=>"$added soal ditambahkan."]);
    }

    public function itemAnalysis(Request $request, Exam $exam, \App\Services\ItemAnalysisService $service)
    {
        $this->authorizeExam($request, $exam);
        return response()->json($service->analyze($exam));
    }

    public function itemAnalysisSummary(Request $request, Exam $exam, \App\Services\ItemAnalysisService $service)
    {
        $this->authorizeExam($request, $exam);
        return response()->json($service->summary($exam));
    }

    public function exportItemAnalysis(Request $request, Exam $exam, \App\Services\ItemAnalysisService $service)
    {
        $this->authorizeExam($request, $exam);
        $csv = $service->exportCsv($exam);
        $filename = 'analisis-butir-' . \Illuminate\Support\Str::slug($exam->title) . '-' . now()->format('Ymd') . '.csv';
        return response($csv, 200, [
            'Content-Type'        => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ]);
    }

    private function authorizeExam(Request $request, Exam $exam): void
    {
        if ($exam->teacher_id !== $request->user()->id && !$request->user()->isAdmin()) {
            abort(403,'Akses ditolak.');
        }
    }
}

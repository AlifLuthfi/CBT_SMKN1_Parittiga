<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Question;

use Illuminate\Http\Request;

class QuestionController extends Controller
{
    public function index(Request $request)
    {
        $q = Question::where('teacher_id', $request->user()->id)
            ->with('subject')
            ->when($request->subject_id,  fn($q,$v) => $q->where('subject_id',$v))
            ->when($request->search,      fn($q,$v) => $q->where('question_text','like',"%$v%"))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 15);

        return response()->json($q);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'question_text'  => 'required|string|max:5000',
            // question_type dihapus dari input — selalu multiple_choice
            'options'        => 'required|array|min:2',
            'options.A'      => 'required|string|max:500',
            'options.B'      => 'required|string|max:500',
            'options.C'      => 'required|string|max:500',
            'options.D'      => 'required|string|max:500',
            'options.E'      => 'nullable|string|max:500',
            'correct_answer' => 'required|string|max:10',
            'explanation'    => 'nullable|string|max:2000',
            'subject_id'     => 'required|exists:subjects,id',
            'image'          => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            'image_url'      => 'nullable|string|max:1024',
        ]);

        $data['teacher_id']    = $request->user()->id;
        $data['question_type'] = 'multiple_choice';

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('questions', 'public');
        } elseif ($request->filled('image_url')) {
            $data['image_path'] = $request->input('image_url');
        }

        $question = Question::create($data);

        return response()->json([
            'message'  => 'Soal berhasil disimpan.',
            'question' => $question,
        ], 201);
    }

    public function show(Request $request, Question $question)
    {
        $this->authorizeQuestion($request, $question);
        return response()->json(['question' => $question]);
    }

    public function update(Request $request, Question $question)
    {
        $this->authorizeQuestion($request, $question);
        $data = $request->validate([
            'question_text'  => 'sometimes|string|max:5000',
            // question_type tidak bisa diubah — selalu multiple_choice
            'options'        => 'sometimes|array|min:2',
            'options.A'      => 'required_with:options|string|max:500',
            'options.B'      => 'required_with:options|string|max:500',
            'options.C'      => 'required_with:options|string|max:500',
            'options.D'      => 'required_with:options|string|max:500',
            'options.E'      => 'nullable|string|max:500',
            'correct_answer' => 'sometimes|string|max:10',
            'explanation'    => 'nullable|string|max:2000',
            'subject_id'     => 'sometimes|exists:subjects,id',
            'image'          => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            'remove_image'   => 'nullable|boolean',
        ]);

        if ($request->boolean('remove_image')) {
            if ($question->image_path) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($question->image_path);
            }
            $data['image_path'] = null;
        } elseif ($request->hasFile('image')) {
            if ($question->image_path) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($question->image_path);
            }
            $data['image_path'] = $request->file('image')->store('questions', 'public');
        }

        $question->update($data);
        return response()->json([
            'message'  => 'Soal diperbarui.',
            'question' => $question,
        ]);
    }

    public function destroy(Request $request, Question $question)
    {
        $this->authorizeQuestion($request, $question);
        
        if ($question->image_path) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($question->image_path);
        }
        
        $question->delete();
        return response()->json(['message' => 'Soal dihapus.']);
    }

    public function bulkStore(Request $request)
    {
        $request->validate([
            'questions'                => 'required|array|max:100',
            'questions.*.question_text'=> 'required|string|max:5000',
            // question_type dihapus dari bulk input
            'questions.*.options'      => 'required|array|min:2',
            'questions.*.options.A'    => 'required|string|max:500',
            'questions.*.options.B'    => 'required|string|max:500',
            'questions.*.options.C'    => 'required|string|max:500',
            'questions.*.options.D'    => 'required|string|max:500',
            'questions.*.options.E'    => 'nullable|string|max:500',
            'questions.*.correct_answer'=> 'required|string|max:10',
            'questions.*.subject_id'   => 'required|exists:subjects,id',
        ]);

        $created = 0;
        foreach ($request->questions as $q) {
            $q['teacher_id']    = $request->user()->id;
            $q['question_type'] = 'multiple_choice';
            Question::create($q);
            $created++;
        }

        return response()->json([
            'message' => "$created soal berhasil disimpan.",
            'created' => $created,
        ], 201);
    }

    private function authorizeQuestion(Request $request, Question $question): void
    {
        if ($question->teacher_id !== $request->user()->id && !$request->user()->isAdmin()) {
            abort(403, 'Akses ditolak.');
        }
    }
}

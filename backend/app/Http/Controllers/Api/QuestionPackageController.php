<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\QuestionPackage;
use App\Models\ClassRoom;
use Illuminate\Http\Request;

class QuestionPackageController extends Controller
{
    public function index(Request $request)
    {
        $packages = QuestionPackage::where('teacher_id', $request->user()->id)
            ->with(['classRoom:id,name,subject'])
            ->withCount('questions as questions_count')
            ->orderByDesc('created_at')
            ->get();
        return response()->json(['data' => $packages]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title'       => 'required|string|max:255',
            'subject'     => 'required|string|max:100',
            'class_id'    => 'required|exists:classes,id',
            'description' => 'nullable|string',
            'question_ids' => 'required|array|min:1',
            'question_ids.*' => 'exists:questions,id',
        ]);

        $data['teacher_id'] = $request->user()->id;
        $package = QuestionPackage::create($data);

        $syncData = [];
        $order = 1;
        foreach ($data['question_ids'] as $qId) {
            $syncData[$qId] = ['display_order' => $order++];
        }
        $package->questions()->sync($syncData);

        return response()->json(['message' => 'Paket soal dibuat.', 'package' => $package->load(['classRoom', 'questions'])], 201);
    }

    public function show(Request $request, QuestionPackage $package)
    {
        if ($package->teacher_id !== $request->user()->id) abort(403);
        return response()->json(['package' => $package->load(['classRoom', 'questions'])]);
    }

    public function update(Request $request, QuestionPackage $package)
    {
        if ($package->teacher_id !== $request->user()->id) abort(403);

        $data = $request->validate([
            'title'       => 'sometimes|string|max:255',
            'subject'     => 'sometimes|string|max:100',
            'class_id'    => 'sometimes|exists:classes,id',
            'description' => 'nullable|string',
            'question_ids' => 'sometimes|array|min:1',
            'question_ids.*' => 'exists:questions,id',
        ]);

        $package->update($data);

        if (isset($data['question_ids'])) {
            $syncData = [];
            $order = 1;
            foreach ($data['question_ids'] as $qId) {
                $syncData[$qId] = ['display_order' => $order++];
            }
            $package->questions()->sync($syncData);
        }

        return response()->json(['message' => 'Paket soal diperbarui.', 'package' => $package->fresh()->load(['classRoom', 'questions'])]);
    }

    public function destroy(Request $request, QuestionPackage $package)
    {
        if ($package->teacher_id !== $request->user()->id) abort(403);
        $package->delete();
        return response()->json(['message' => 'Paket soal dihapus.']);
    }
}

<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subject;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    public function index(Request $request)
    {
        $subjects = Subject::where('teacher_id', $request->user()->id)
            ->withCount('questions')
            ->orderByDesc('created_at')
            ->get();
        return response()->json(['data' => $subjects]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100',
        ]);
        $data['teacher_id'] = $request->user()->id;
        $subject = Subject::create($data);
        return response()->json(['message' => 'Mata pelajaran ditambahkan.', 'subject' => $subject], 201);
    }

    public function update(Request $request, Subject $subject)
    {
        if ($subject->teacher_id !== $request->user()->id) abort(403);
        $data = $request->validate(['name' => 'required|string|max:100']);
        $subject->update($data);
        return response()->json(['message' => 'Mata pelajaran diperbarui.', 'subject' => $subject]);
    }

    public function destroy(Request $request, Subject $subject)
    {
        if ($subject->teacher_id !== $request->user()->id) abort(403);
        $subject->delete();
        return response()->json(['message' => 'Mata pelajaran dihapus.']);
    }
}

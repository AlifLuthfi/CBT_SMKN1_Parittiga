<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\QuestionImport;
use App\Services\QuestionImportService;
use Illuminate\Http\Request;

class QuestionImportController extends Controller
{
    public function __construct(private QuestionImportService $service) {}

    /**
     * Download template CSV/XLSX (CSV format).
     */
    public function template()
    {
        $csv = $this->service->generateTemplate();
        return response($csv, 200, [
            'Content-Type'        => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="template-import-soal.csv"',
        ]);
    }

    /**
     * Preview file import — parse & validasi tanpa simpan ke DB.
     * Flutter bisa tampilkan preview sebelum guru konfirmasi import.
     */
    public function preview(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt,xlsx,xls|max:10240',
        ]);

        $result = $this->service->preview(
            $request->file('file'),
            $request->user()->id
        );

        return response()->json([
            'message' => 'Preview berhasil. Periksa data sebelum import.',
            'preview' => $result,
        ]);
    }

    /**
     * Upload & import file soal (CSV atau XLSX).
     */
    public function store(Request $request)
    {
        $request->validate([
            'file'        => 'required|file|mimes:csv,txt,xlsx,xls|max:10240',
            'subject_id'  => 'nullable|exists:subjects,id',
        ]);

        $result = $this->service->import(
            $request->file('file'),
            $request->user()->id,
            subjectId: $request->subject_id
        );

        $status = $result->error_count === 0 ? 200 : 207; // 207 Multi-Status jika ada sebagian error

        return response()->json([
            'message'      => "Import selesai. {$result->success_count} soal berhasil, {$result->error_count} error.",
            'import'       => $result,
            'has_errors'   => $result->error_count > 0,
            'error_detail' => $result->errors ?? [],
        ], $status);
    }

    /**
     * Riwayat import guru.
     */
    public function index(Request $request)
    {
        $imports = QuestionImport::where('teacher_id', $request->user()->id)
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

    /**
     * Detail satu import (termasuk semua error).
     */
    public function show(Request $request, QuestionImport $questionImport)
    {
        if ($questionImport->teacher_id !== $request->user()->id) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        return response()->json(['import' => $questionImport]);
    }
}

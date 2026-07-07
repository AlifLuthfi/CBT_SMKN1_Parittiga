<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\GradeReportService;
use Illuminate\Http\Request;

class GradeReportController extends Controller
{
    public function __construct(private GradeReportService $service) {}

    public function classReport(Request $request, int $classId)
    {
        $year     = $request->year     ?? '2024/2025';
        $semester = $request->semester ?? 'Ganjil';
        $this->service->recalculateForClass($classId, $year, $semester);
        return response()->json($this->service->getClassReport($classId, $year, $semester));
    }

    public function studentReport(Request $request, int $studentId)
    {
        $classId  = $request->validate(['class_id' => 'required|exists:classes,id'])['class_id'];
        $year     = $request->year     ?? '2024/2025';
        $semester = $request->semester ?? 'Ganjil';
        $this->service->recalculateForStudent($studentId, $classId, $year, $semester);
        return response()->json($this->service->getStudentReport($studentId, $classId, $year, $semester));
    }
}

<?php

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClassManagementController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ExamController;
use App\Http\Controllers\Api\GradeReportController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\QuestionController;
use App\Http\Controllers\Api\QuestionImportController;
use App\Http\Controllers\Api\StudentExamController;
use App\Http\Controllers\Api\ViolationController;
use App\Http\Controllers\Api\LCGVerifyController;
use App\Http\Controllers\Api\QuestionPackageController;
use App\Http\Controllers\Api\SubjectController;
use Illuminate\Support\Facades\Route;

// ── PUBLIC ──────────────────────────────────────────────────────────────────
Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:login');
Route::post('/lcg/verify', [LCGVerifyController::class, 'verify']);
Route::post('/lcg/check-consistency', [LCGVerifyController::class, 'checkConsistency']);

// ── PROTECTED ────────────────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::get ('/auth/me',         [AuthController::class, 'me']);
    Route::post('/auth/logout',     [AuthController::class, 'logout']);
    Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);
    Route::patch('/auth/password',  [AuthController::class, 'gantiPassword']);

    // Notifikasi (semua role)
    Route::get  ('/notifications',                [NotificationController::class, 'index']);
    Route::patch('/notifications/read-all',       [NotificationController::class, 'markAllRead']);
    Route::patch('/notifications/{notification}', [NotificationController::class, 'markRead']);

    // ── GURU & ADMIN ─────────────────────────────────────────────────────────
    Route::middleware('role:guru,admin')->prefix('guru')->group(function () {

        // Dashboard
        Route::get('/dashboard', [DashboardController::class, 'index']);

        // ── Import soal ──────────────────────────────────────────────────────
        // Preview (parse tanpa simpan) — HARUS sebelum POST /question-imports
        Route::post('/question-imports/preview',  [QuestionImportController::class, 'preview']);
        Route::get ('/question-imports/template', [QuestionImportController::class, 'template']);
        Route::get ('/question-imports',          [QuestionImportController::class, 'index']);
        Route::post('/question-imports',          [QuestionImportController::class, 'store']);
        Route::get ('/question-imports/{questionImport}', [QuestionImportController::class, 'show']);

        // ── Mata Pelajaran ──────────────────────────────────────────────────
        Route::get   ('/subjects',             [SubjectController::class, 'index']);
        Route::post  ('/subjects',             [SubjectController::class, 'store']);
        Route::put   ('/subjects/{subject}',   [SubjectController::class, 'update']);
        Route::delete('/subjects/{subject}',   [SubjectController::class, 'destroy']);

        // ── Bank soal ────────────────────────────────────────────────────────
        Route::get   ('/questions',            [QuestionController::class, 'index']);
        Route::post  ('/questions',            [QuestionController::class, 'store']);
        Route::post  ('/questions/bulk',       [QuestionController::class, 'bulkStore']);
        Route::get   ('/questions/{question}', [QuestionController::class, 'show']);
        Route::put   ('/questions/{question}', [QuestionController::class, 'update']);
        Route::delete('/questions/{question}', [QuestionController::class, 'destroy']);

        // ── Ujian ────────────────────────────────────────────────────────────
        Route::get   ('/exams',              [ExamController::class, 'index']);
        Route::post  ('/exams',              [ExamController::class, 'store']);
        Route::get   ('/exams/{exam}',       [ExamController::class, 'show']);
        Route::put   ('/exams/{exam}',       [ExamController::class, 'update']);
        Route::delete('/exams/{exam}',       [ExamController::class, 'destroy']);
        Route::patch ('/exams/{exam}/schedule',     [ExamController::class, 'schedule']);
        // Aktivasi dipindah ke admin — lihat grup admin di bawah
        // Route::patch ('/exams/{exam}/activate', [ExamController::class, 'activate']);
        Route::patch ('/exams/{exam}/pause',        [ExamController::class, 'pause']);
        Route::patch ('/exams/{exam}/resume',       [ExamController::class, 'resume']);
        Route::patch ('/exams/{exam}/end',          [ExamController::class, 'end']);
        Route::post  ('/exams/{exam}/extend-time',  [ExamController::class, 'extendTime']);
        Route::post  ('/exams/{exam}/questions',    [ExamController::class, 'addQuestions']);

        // Analisis butir soal
        Route::get('/exams/{exam}/item-analysis',         [ExamController::class, 'itemAnalysis']);
        Route::get('/exams/{exam}/item-analysis/summary', [ExamController::class, 'itemAnalysisSummary']);
        Route::get('/exams/{exam}/item-analysis/export',  [ExamController::class, 'exportItemAnalysis']);

        // ── Manajemen kelas (READ ONLY untuk guru) ──────────────────────────
        Route::get   ('/classes',                  [ClassManagementController::class, 'index']);
        Route::get   ('/classes/{class}',          [ClassManagementController::class, 'show']);
        Route::get   ('/classes/{class}/students', [ClassManagementController::class, 'students']);

        // ── Laporan nilai ────────────────────────────────────────────────────
        Route::get('/classes/{classId}/grade-report',   [GradeReportController::class, 'classReport']);
        Route::get('/students/{studentId}/grade-report',[GradeReportController::class, 'studentReport']);

        // ── Paket soal ────────────────────────────────────────────────────────
        Route::get   ('/packages',                  [QuestionPackageController::class, 'index']);
        Route::post  ('/packages',                  [QuestionPackageController::class, 'store']);
        Route::get   ('/packages/{package}',        [QuestionPackageController::class, 'show']);
        Route::put   ('/packages/{package}',        [QuestionPackageController::class, 'update']);
        Route::delete('/packages/{package}',        [QuestionPackageController::class, 'destroy']);

        // ── Pelanggaran ──────────────────────────────────────────────────────
        Route::get  ('/violations',             [ViolationController::class, 'index']);
        Route::patch('/violations/{violation}', [ViolationController::class, 'handle']);
    });

    // ── SISWA ─────────────────────────────────────────────────────────────────
    Route::middleware('role:siswa')->prefix('siswa')->group(function () {

        // Daftar & detail ujian
        Route::get ('/exams',            [StudentExamController::class, 'index']);
        Route::get ('/exams/{exam}',     [StudentExamController::class, 'show']);
        Route::post('/exams/{exam}/start',[StudentExamController::class, 'startExam']);

        // Manajemen sesi
        // ⭐ Bulk sync jawaban (cara utama — setiap 30 detik dari Flutter)
        Route::post('/sessions/{session}/answers',  [StudentExamController::class, 'bulkSaveAnswers']);
        // ⭐ Fallback: ambil state dari DB jika local_state Flutter hilang
        Route::get ('/sessions/{session}/state',    [StudentExamController::class, 'getState']);
        // Submit ujian (bisa sertakan semua jawaban final di body)
        Route::post('/sessions/{session}/submit',   [StudentExamController::class, 'submit']);
        // Hasil ujian setelah submit
        Route::get ('/sessions/{session}/result',   [StudentExamController::class, 'result']);
        // Riwayat ujian
        Route::get ('/history',                     [StudentExamController::class, 'history']);

        // Single save (deprecated — backward compat, diteruskan ke bulk)
        Route::patch('/sessions/{session}/answer',  [StudentExamController::class, 'saveAnswer']);

        // Verifikasi password untuk keluar
        Route::post('/verify-exit', [StudentExamController::class, 'verifyExit']);

        // Laporkan pelanggaran
        Route::post('/violations', [ViolationController::class, 'store']);
    });

    // ── ADMIN ─────────────────────────────────────────────────────────────────
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get   ('/dashboard',                  [AdminController::class, 'dashboard']);
        Route::get   ('/users',                      [AdminController::class, 'users']);
        Route::post  ('/users',                      [AdminController::class, 'createUser']);
        Route::put   ('/users/{user}',               [AdminController::class, 'updateUser']);
        Route::patch ('/users/{user}/ganti-password',[AdminController::class, 'gantiPassword']);
        Route::patch ('/users/{user}/toggle-status', [AdminController::class, 'toggleStatus']);
        Route::delete('/users/{user}',               [AdminController::class, 'deleteUser']);
        Route::get   ('/classes',                    [AdminController::class, 'classes']);
        Route::post  ('/classes',                    [AdminController::class, 'createClass']);
        Route::put   ('/classes/{class}',            [AdminController::class, 'updateClass']);
        Route::delete('/classes/{class}',            [AdminController::class, 'deleteClass']);
        Route::put   ('/users/{user}/class',         [AdminController::class, 'updateStudentClass']);
        Route::get   ('/exams',                      [AdminController::class, 'exams']);
        Route::patch ('/exams/{exam}/activate',      [AdminController::class, 'activateExam']);
        Route::patch ('/exams/{exam}/end',           [AdminController::class, 'endExam']);
        Route::get   ('/violations',                 [AdminController::class, 'violations']);
        Route::get   ('/activity-logs',              [AdminController::class, 'activityLogs']);
        Route::get   ('/export/users',               [AdminController::class, 'exportUsers']);
    });
});

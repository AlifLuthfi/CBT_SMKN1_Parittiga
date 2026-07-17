<?php

use App\Http\Controllers\Web\AuthWebController;
use App\Http\Controllers\Web\AdminWebController;
use App\Http\Controllers\Web\GuruWebController;
use App\Http\Controllers\Web\SiswaWebController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
| Halaman web untuk sistem ujian online (responsive Tailwind CSS)
| Semua route yang di-suffix dengan "/web" untuk hindari bentrok API
*/

// ── Public (no auth required) ──
Route::get('/', function () {
    return redirect('/splash');
});
Route::get('/splash', [AuthWebController::class, 'splash'])->name('splash');

// ── Guest ──
Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthWebController::class, 'loginForm'])->name('login');
    Route::post('/login', [AuthWebController::class, 'login']);
});

// ── Authenticated ──
Route::middleware('auth')->group(function () {

    Route::post('/logout', [AuthWebController::class, 'logout'])->name('logout');

    // Dashboard (role-aware)
    Route::get('/dashboard', [AuthWebController::class, 'dashboard'])->name('dashboard');

    // ── Admin ──
    Route::middleware('can:admin')->prefix('admin')->name('admin.')->group(function () {
        $c = AdminWebController::class;
        Route::get('/users',           [$c, 'users'])->name('users');
        Route::post('/users',          [$c, 'createUser'])->name('users.store');
        Route::put('/users/{user}/update',  [$c, 'updateUser'])->name('users.update');
        Route::patch('/users/{user}/toggle-status', [$c, 'toggleStatus'])->name('users.toggle-status');
        Route::patch('/users/{user}/ganti-password', [$c, 'gantiPassword'])->name('users.ganti-password');
        Route::delete('/users/{user}', [$c, 'deleteUser'])->name('users.delete');

        Route::get('/classes',         [$c, 'classes'])->name('classes');
        Route::post('/classes',        [$c, 'createClass'])->name('classes.store');
        Route::put('/classes/{class}/update',  [$c, 'updateClass'])->name('classes.update');
        Route::delete('/classes/{class}',      [$c, 'deleteClass'])->name('classes.delete');

        Route::get('/exams',           [$c, 'exams'])->name('exams');
        Route::patch('/exams/{exam}/activate',  [$c, 'activateExam'])->name('exams.activate');
        Route::patch('/exams/{exam}/end',       [$c, 'endExam'])->name('exams.end');
        Route::delete('/exams/{exam}',          [$c, 'deleteExam'])->name('exams.delete');

        Route::get('/violations',      [$c, 'violations'])->name('violations');
        Route::get('/logs',            [$c, 'logs'])->name('logs');
    });

    // ── Guru ──
    Route::middleware('can:guru')->prefix('guru')->name('guru.')->group(function () {
        $c = GuruWebController::class;

        // Questions
        Route::get('/questions',                  [$c, 'questions'])->name('questions');
        Route::post('/questions',                 [$c, 'storeQuestion'])->name('questions.store');
        Route::put('/questions/{question}/update', [$c, 'updateQuestion'])->name('questions.update');
        Route::delete('/questions/{question}',     [$c, 'deleteQuestion'])->name('questions.delete');

        // Subject-specific questions
        Route::get('/subjects/{subject}/questions', [$c, 'subjectQuestions'])->name('subjects.questions');

        // Import Soal (web JSON endpoints + view)
        Route::get('/questions/import',           [$c, 'importForm'])->name('questions.import');
        Route::get('/questions/import/template',  [$c, 'downloadTemplate'])->name('questions.import.template');
        Route::post('/questions/import/preview',  [$c, 'importPreview'])->name('questions.import.preview');
        Route::post('/questions/import/execute',  [$c, 'importExecute'])->name('questions.import.execute');
        Route::get('/questions/import/history',   [$c, 'importHistory'])->name('questions.import.history');

        // Subjects
        Route::get('/subjects',          [$c, 'subjects'])->name('subjects');
        Route::post('/subjects',         [$c, 'storeSubject'])->name('subjects.store');
        Route::put('/subjects/{subject}/update',   [$c, 'updateSubject'])->name('subjects.update');
        Route::delete('/subjects/{subject}',       [$c, 'deleteSubject'])->name('subjects.delete');

        // Exams
        Route::get('/exams',             [$c, 'exams'])->name('exams');
        Route::post('/exams',            [$c, 'storeExam'])->name('exams.store');
        Route::put('/exams/{exam}/update',        [$c, 'updateExam'])->name('exams.update');
        Route::delete('/exams/{exam}',            [$c, 'deleteExam'])->name('exams.delete');
        Route::patch('/exams/{exam}/schedule',    [$c, 'scheduleExam'])->name('exams.schedule');
        Route::post('/exams/{exam}/questions',    [$c, 'addQuestionsToExam'])->name('exams.questions');

        // Classes
        Route::get('/classes',           [$c, 'classes'])->name('classes');

        // Grade Reports
        Route::get('/grade-reports',     [$c, 'gradeReports'])->name('grade-reports');
        Route::get('/grade-reports/{class}',  [$c, 'classGradeReport'])->name('grade-reports.class');
    });

    // ── Siswa ──
    Route::middleware('can:siswa')->prefix('siswa')->name('siswa.')->group(function () {
        $c = SiswaWebController::class;
        Route::get('/exams',           [$c, 'exams'])->name('exams');
        Route::get('/exams/{exam}/start', [$c, 'startExam'])->name('exams.start');
        Route::get('/history',         [$c, 'history'])->name('history');
        Route::get('/result/{session}', [$c, 'result'])->name('exams.result');
    });
});

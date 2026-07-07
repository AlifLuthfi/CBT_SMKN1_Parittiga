<?php
use Illuminate\Support\Facades\Route;
Route::get('/', fn() => response()->json([
    'app'    => 'ExamCore API',
    'version'=> '1.0.0',
    'status' => 'running',
]));

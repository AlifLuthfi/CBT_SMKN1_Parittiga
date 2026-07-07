<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exams', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('class_id')->constrained('classes')->onDelete('cascade');
            $table->string('title');
            $table->text('description')->nullable();
            $table->integer('duration_minutes')->default(90);
            $table->integer('total_questions')->default(0);
            $table->boolean('randomize_questions')->default(true);
            $table->boolean('randomize_options')->default(false);
            $table->boolean('show_result_immediately')->default(true);
            $table->boolean('allow_review')->default(true);
            $table->decimal('passing_grade', 5, 2)->default(70.00);
            $table->enum('status', ['draft', 'scheduled', 'active', 'paused', 'ended'])->default('draft');
            $table->timestamp('start_time')->nullable();
            $table->timestamp('end_time')->nullable();
            $table->boolean('auto_activate')->default(false);
            $table->boolean('auto_end')->default(true);
            $table->integer('max_violations')->default(5);
            $table->json('question_blueprint')->nullable();
            $table->timestamp('notified_ending_soon_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('exam_questions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('exam_id')->constrained('exams')->onDelete('cascade');
            $table->foreignId('question_id')->constrained('questions')->onDelete('cascade');
            $table->integer('display_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->unique(['exam_id', 'question_id']);
            $table->timestamps();
        });

        Schema::create('exam_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('exam_id')->constrained('exams')->onDelete('cascade');
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->unsignedBigInteger('seed')->default(0);
            $table->json('question_order')->nullable();
            $table->enum('status', ['in_progress', 'submitted', 'timeout', 'force_submitted'])->default('in_progress');
            $table->decimal('score', 5, 2)->nullable();
            $table->boolean('is_passed')->nullable();
            $table->boolean('force_submit')->default(false);
            $table->integer('remaining_seconds')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('last_activity_at')->nullable();
            $table->unique(['exam_id', 'student_id']);
            $table->timestamps();
        });

        Schema::create('exam_session_answers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_id')->constrained('exam_sessions')->onDelete('cascade');
            $table->foreignId('question_id')->constrained('questions')->onDelete('cascade');
            $table->string('answer')->nullable();
            $table->boolean('is_correct')->nullable();
            $table->decimal('score', 5, 2)->nullable();
            $table->unique(['session_id', 'question_id']);
            $table->timestamps();
        });

        Schema::create('exam_pauses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('exam_id')->constrained('exams')->onDelete('cascade');
            $table->foreignId('paused_by')->constrained('users')->onDelete('cascade');
            $table->text('reason')->nullable();
            $table->timestamp('paused_at');
            $table->timestamp('resumed_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('exam_time_extensions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_id')->constrained('exam_sessions')->onDelete('cascade');
            $table->foreignId('extended_by')->constrained('users')->onDelete('cascade');
            $table->integer('minutes');
            $table->text('reason')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exam_time_extensions');
        Schema::dropIfExists('exam_pauses');
        Schema::dropIfExists('exam_session_answers');
        Schema::dropIfExists('exam_sessions');
        Schema::dropIfExists('exam_questions');
        Schema::dropIfExists('exams');
    }
};

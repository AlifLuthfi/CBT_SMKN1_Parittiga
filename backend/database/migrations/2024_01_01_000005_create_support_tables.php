<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('violations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_id')->constrained('exam_sessions')->onDelete('cascade');
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->enum('violation_type', ['tab_switch', 'fullscreen_exit', 'copy_paste', 'blur', 'devtools'])->default('tab_switch');
            $table->integer('count')->default(1);
            $table->enum('status', ['open', 'handled'])->default('open');
            $table->timestamps();
        });

        Schema::create('activity_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null');
            $table->string('action');
            $table->text('description')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('title');
            $table->text('message');
            $table->string('type')->default('info');
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        Schema::create('student_grade_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('class_id')->constrained('classes')->onDelete('cascade');
            $table->string('academic_year');
            $table->string('semester');
            $table->decimal('average_score', 5, 2)->default(0);
            $table->decimal('highest_score', 5, 2)->default(0);
            $table->decimal('lowest_score', 5, 2)->default(0);
            $table->integer('total_exams')->default(0);
            $table->integer('passed_exams')->default(0);
            $table->decimal('pass_rate', 5, 2)->default(0);
            $table->timestamp('last_calculated_at')->nullable();
            $table->unique(
                ['student_id', 'class_id', 'academic_year', 'semester'],
                'sgr_unique'
            );
            $table->timestamps();
        });

        Schema::create('question_imports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('users')->onDelete('cascade');
            $table->string('filename');
            $table->integer('total_rows')->default(0);
            $table->integer('success_count')->default(0);
            $table->integer('error_count')->default(0);
            $table->enum('status', ['pending', 'processing', 'completed', 'failed'])->default('pending');
            $table->json('errors')->nullable();
            $table->timestamps();
        });

        Schema::create('exam_templates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('users')->onDelete('cascade');
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('type', ['template', 'backup', 'archive'])->default('template');
            $table->integer('question_count')->default(0);
            $table->integer('used_count')->default(0);
            $table->json('settings')->nullable();
            $table->timestamps();
        });

        Schema::create('teacher_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->onDelete('cascade');
            $table->string('signature')->nullable();
            $table->json('preferences')->nullable();
            $table->timestamps();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('teacher_profiles');
        Schema::dropIfExists('exam_templates');
        Schema::dropIfExists('question_imports');
        Schema::dropIfExists('student_grade_reports');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('activity_logs');
        Schema::dropIfExists('violations');
    }
};

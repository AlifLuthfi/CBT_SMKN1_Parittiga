<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Questions — filter by teacher + active status
        Schema::table('questions', function (Blueprint $table) {
            $table->index(['teacher_id', 'is_active'], 'idx_questions_teacher_active');
        });

        // Exam sessions — filter by student + status (hot path)
        Schema::table('exam_sessions', function (Blueprint $table) {
            $table->index(['student_id', 'status'], 'idx_sessions_student_status');
            // Grade report aggregation — exam avg/min/max
            $table->index(['exam_id', 'status', 'score'], 'idx_sessions_exam_status_score');
        });

        // Notifications — unread count per user
        Schema::table('notifications', function (Blueprint $table) {
            $table->index(['user_id', 'read_at'], 'idx_notifications_user_read');
        });

        // Violations — lookup by session + time
        Schema::table('violations', function (Blueprint $table) {
            $table->index(['session_id', 'created_at'], 'idx_violations_session_created');
        });

        // Activity logs — time-based pruning & sorting
        Schema::table('activity_logs', function (Blueprint $table) {
            $table->index(['created_at'], 'idx_activity_logs_created');
        });
    }

    public function down(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->dropIndex('idx_questions_teacher_active');
        });
        Schema::table('exam_sessions', function (Blueprint $table) {
            $table->dropIndex('idx_sessions_student_status');
            $table->dropIndex('idx_sessions_exam_status_score');
        });
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex('idx_notifications_user_read');
        });
        Schema::table('violations', function (Blueprint $table) {
            $table->dropIndex('idx_violations_session_created');
        });
        Schema::table('activity_logs', function (Blueprint $table) {
            $table->dropIndex('idx_activity_logs_created');
        });
    }
};

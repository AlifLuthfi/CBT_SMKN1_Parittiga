<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Tambah kolom tags pada questions (untuk label/topik bebas)
        Schema::table('questions', function (Blueprint $table) {
            $table->json('tags')->nullable()->after('difficulty')
                ->comment('Label bebas, contoh: ["Bab 3","UTS","Trigonometri"]');
        });

        // Tambah last_bulk_sync_at pada exam_sessions (tracking sync terakhir dari Flutter)
        Schema::table('exam_sessions', function (Blueprint $table) {
            $table->timestamp('last_bulk_sync_at')->nullable()->after('last_activity_at')
                ->comment('Waktu terakhir bulk sync jawaban dari klien Flutter');
            $table->integer('sync_count')->default(0)->after('last_bulk_sync_at')
                ->comment('Jumlah kali bulk sync dilakukan');
        });
    }

    public function down(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->dropColumn('tags');
        });

        Schema::table('exam_sessions', function (Blueprint $table) {
            $table->dropColumn(['last_bulk_sync_at', 'sync_count']);
        });
    }
};

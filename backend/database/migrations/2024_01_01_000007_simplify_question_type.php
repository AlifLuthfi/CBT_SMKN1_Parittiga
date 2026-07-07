<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Pastikan semua soal lama diset ke multiple_choice
        DB::table('questions')->update(['question_type' => 'multiple_choice']);

        // Ubah enum menjadi hanya multiple_choice
        DB::statement("ALTER TABLE questions MODIFY question_type ENUM('multiple_choice') NOT NULL DEFAULT 'multiple_choice'");
    }

    public function down(): void
    {
        // Kembalikan enum ke 3 nilai
        DB::statement("ALTER TABLE questions MODIFY question_type ENUM('multiple_choice','true_false','essay') NOT NULL DEFAULT 'multiple_choice'");
    }
};

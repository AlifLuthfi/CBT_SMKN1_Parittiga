<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Hapus foreign key dulu
        Schema::table('questions', function (Blueprint $table) {
            $table->dropForeign(['category_id']);
            $table->dropColumn('category_id');
        });

        Schema::dropIfExists('question_categories');
    }

    public function down(): void
    {
        Schema::create('question_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('users')->onDelete('cascade');
            $table->string('name');
            $table->string('color')->default('#3b82f6');
            $table->timestamps();
        });

        Schema::table('questions', function (Blueprint $table) {
            $table->foreignId('category_id')->nullable()->constrained('question_categories')->onDelete('set null');
        });
    }
};

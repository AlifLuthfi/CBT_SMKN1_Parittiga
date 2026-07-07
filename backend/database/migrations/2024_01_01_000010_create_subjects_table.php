<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subjects', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('users')->onDelete('cascade');
            $table->string('name');
            $table->string('class_id')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::table('questions', function (Blueprint $table) {
            $table->foreignId('subject_id')->nullable()->constrained('subjects')->onDelete('cascade')->after('category_id');
        });
    }

    public function down(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->dropForeign(['subject_id']);
            $table->dropColumn('subject_id');
        });
        Schema::dropIfExists('subjects');
    }
};

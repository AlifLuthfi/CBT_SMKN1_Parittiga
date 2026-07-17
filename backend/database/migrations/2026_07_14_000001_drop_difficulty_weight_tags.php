<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->dropColumn(['difficulty', 'weight', 'tags']);
        });
    }

    public function down(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->enum('difficulty', ['easy', 'medium', 'hard'])->default('medium')->after('explanation');
            $table->decimal('weight', 5, 2)->default(1.00)->after('difficulty');
            $table->json('tags')->nullable()->after('weight');
        });
    }
};

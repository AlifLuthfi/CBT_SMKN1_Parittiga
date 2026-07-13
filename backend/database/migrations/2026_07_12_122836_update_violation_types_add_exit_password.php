<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // MySQL: alter ENUM to add new violation types
        DB::statement("ALTER TABLE violations MODIFY COLUMN violation_type ENUM(
            'tab_switch','fullscreen_exit','copy_paste','blur','devtools',
            'mouse_leave','window_resize','wrong_password','split_screen',
            'screen_record','screenshot','multi_touch'
        ) NOT NULL DEFAULT 'tab_switch'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE violations MODIFY COLUMN violation_type ENUM(
            'tab_switch','fullscreen_exit','copy_paste','blur','devtools'
        ) NOT NULL DEFAULT 'tab_switch'");
    }
};

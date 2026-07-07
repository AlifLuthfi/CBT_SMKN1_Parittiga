<?php
namespace App\Console\Commands;

use App\Services\ExamSchedulerService;
use Illuminate\Console\Command;

class RunExamScheduler extends Command
{
    protected $signature   = 'exam:scheduler';
    protected $description = 'Run exam scheduler: auto-activate, auto-end, submit timed-out sessions';

    public function handle(ExamSchedulerService $scheduler): void
    {
        $scheduler->tick();
        $this->info('Scheduler ran at ' . now()->toDateTimeString());
    }
}

<?php
namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class SetStudentPasswords extends Command
{
    protected $signature = 'siswa:set-passwords {--prefix=} {--dry-run}';
    protected $description = 'Set unique password for each student account (default: password = NIS)';

    public function handle()
    {
        $prefix = $this->option('prefix');
        $dryRun = $this->option('dry-run');
        $students = User::where('role', 'siswa')->get();
        $updated = 0;

        foreach ($students as $s) {
            $nis = $s->nis;
            if (!$nis) {
                $this->warn("Siswa {$s->id} ({$s->email}) has no NIS, skipping.");
                continue;
            }
            $password = $prefix ? "{$prefix}{$nis}" : "{$nis}";
            if ($dryRun) {
                $this->line("[DRY] {$s->email} ({$s->name}) → password: {$password}");
            } else {
                $s->password = Hash::make($password);
                $s->save();
                $this->info("✓ {$s->email} ({$s->name}) → password: {$password}");
            }
            $updated++;
        }

        $this->line("Done. {$updated} student(s) " . ($dryRun ? 'would be updated.' : 'updated.'));
        return Command::SUCCESS;
    }
}

<?php
namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use App\Services\ExamRandomizationService;
use App\Services\GradingService;
use App\Services\GradeReportService;
use App\Services\ItemAnalysisService;
use App\Services\NotificationService;
use App\Services\QuestionImportService;
use App\Services\ExamSchedulerService;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(ExamRandomizationService::class);
        $this->app->singleton(GradingService::class);
        $this->app->singleton(GradeReportService::class);
        $this->app->singleton(ItemAnalysisService::class);
        $this->app->singleton(NotificationService::class);
        $this->app->singleton(QuestionImportService::class);
        $this->app->singleton(ExamSchedulerService::class, function($app) {
            return new ExamSchedulerService(
                $app->make(NotificationService::class),
                $app->make(GradingService::class)
            );
        });
    }

    public function boot(): void
    {
        // Authorization gates untuk role-based web routes
        Gate::define('admin', fn($user) => $user->role === 'admin');
        Gate::define('guru',  fn($user) => $user->role === 'guru');
        Gate::define('siswa', fn($user) => $user->role === 'siswa');

        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by(
                $request->user()?->id ?: $request->ip()
            );
        });

        RateLimiter::for('login', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip())
                ->response(fn() => response()->json([
                    'message' => 'Terlalu banyak percobaan login. Coba lagi dalam 1 menit.'
                ], 429));
        });
    }
}

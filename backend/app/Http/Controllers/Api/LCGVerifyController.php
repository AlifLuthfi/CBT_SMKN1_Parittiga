<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ExamRandomizationService;
use Illuminate\Http\Request;

/**
 * LCGVerifyController — endpoint untuk cross-check LCG
 * antara frontend (JS) dan backend (PHP).
 * Digunakan untuk debugging dan memastikan konsistensi.
 */
class LCGVerifyController extends Controller
{
    public function __construct(private ExamRandomizationService $randomizer) {}

    /**
     * POST /api/lcg/verify
     * Body: { seed: int, steps: int }
     * Returns: { seed, steps, output: int[] }
     */
    public function verify(Request $request)
    {
        $data  = $request->validate([
            'seed'  => 'required|integer|min:1',
            'steps' => 'nullable|integer|min:1|max:20',
        ]);
        $steps = $data['steps'] ?? 5;
        $out   = $this->randomizer->verify($data['seed'], $steps);

        return response()->json([
            'seed'   => $data['seed'],
            'steps'  => $steps,
            'output' => $out,
        ]);
    }

    /**
     * POST /api/lcg/check-consistency
     * Body: { seed: int, frontend_output: int[] }
     * Returns: { consistent: bool, backend_output: int[] }
     */
    public function checkConsistency(Request $request)
    {
        $data = $request->validate([
            'seed'            => 'required|integer|min:1',
            'frontend_output' => 'required|array|min:1|max:20',
            'frontend_output.*' => 'required|integer',
        ]);

        $backendOut  = $this->randomizer->verify($data['seed'], count($data['frontend_output']));
        $consistent  = $backendOut === $data['frontend_output'];

        return response()->json([
            'consistent'      => $consistent,
            'seed'            => $data['seed'],
            'backend_output'  => $backendOut,
            'frontend_output' => $data['frontend_output'],
        ]);
    }
}

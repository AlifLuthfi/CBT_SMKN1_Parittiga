<?php
namespace App\Services;

use App\Models\Exam;
use App\Models\ExamSession;
use App\Models\ExamSessionAnswer;

class ItemAnalysisService
{
    /**
     * Analisis butir soal lengkap untuk satu ujian.
     * Menghitung: P (difficulty), D (discrimination), r_pbis, distractor effectiveness, omit rate.
     */
    public function analyze(Exam $exam): array
    {
        $sessions = ExamSession::where('exam_id', $exam->id)
            ->whereIn('status', ['submitted', 'timeout', 'force_submitted'])
            ->with('answers')
            ->get();

        if ($sessions->count() < 5) {
            return [
                'error'   => true,
                'message' => 'Minimal 5 siswa harus submit untuk analisis butir soal.',
            ];
        }

        $questions = $exam->questions()->wherePivot('is_active', true)->get();
        $n         = $sessions->count();
        $sessionIds = $sessions->pluck('id');

        // Skor total semua siswa (untuk r_pbis)
        $allScores  = $sessions->pluck('score')->map(fn($s) => (float)$s);
        $meanTotal  = $allScores->avg();
        $stdTotal   = $this->stdDev($allScores->toArray());

        // Kelompok atas 27% dan bawah 27% (untuk D-index)
        $groupSize = max(1, (int)($n * 0.27));
        $upperIds  = $sessions->sortByDesc('score')->take($groupSize)->pluck('id');
        $lowerIds  = $sessions->sortBy('score')->take($groupSize)->pluck('id');

        // Batch load semua jawaban — hindari N+1
        $qAnswersByQ = ExamSessionAnswer::whereIn('session_id', $sessionIds)
            ->get()
            ->groupBy('question_id');

        $items     = [];
        $pValues   = [];
        $variances = [];

        foreach ($questions as $q) {
            $qAnswers     = $qAnswersByQ->get($q->id, collect());
            $totalAnswered = $qAnswers->count();
            $correctTotal  = $qAnswers->where('is_correct', true)->count();
            $omitCount     = $n - $totalAnswered;

            // ── P-value (Difficulty Index) ──────────────────────────────────
            $p = $totalAnswered > 0 ? $correctTotal / $totalAnswered : 0;

            // ── D-index (Discrimination Index) — hitung dari koleksi, bukan DB ──
            $upperCorrect = $qAnswers->whereIn('session_id', $upperIds)->where('is_correct', true)->count();
            $lowerCorrect = $qAnswers->whereIn('session_id', $lowerIds)->where('is_correct', true)->count();
            $d = $groupSize > 0 ? ($upperCorrect - $lowerCorrect) / $groupSize : 0;

            // ── Point Biserial Correlation (r_pbis) ────────────────────────
            // r_pbis = (M_correct - M_total) / SD_total * sqrt(p * q)
            $rpbis = 0;
            if ($correctTotal > 0 && $stdTotal > 0 && $p > 0 && $p < 1) {
                $correctSessionIds = $qAnswers->where('is_correct', true)->pluck('session_id');
                $meanCorrect = $sessions->whereIn('id', $correctSessionIds->toArray())
                    ->avg('score') ?? 0;
                $q_val = 1 - $p;
                $rpbis = (($meanCorrect - $meanTotal) / $stdTotal) * sqrt($p * $q_val);
            }

            // ── Distractor Effectiveness ─────────────────────────────────────
            // Semua soal adalah pilihan ganda, selalu hitung distribusi opsi
            $distractors = [];
            if ($q->options) {
                foreach (array_keys($q->options) as $key) {
                    $cnt       = $qAnswers->where('answer', $key)->count();
                    $isCorrect = $key === $q->correct_answer;

                    // Pengecoh efektif jika dipilih ≥5% siswa yang menjawab
                    $effectiveness = null;
                    if (!$isCorrect && $totalAnswered > 0) {
                        $pct = $cnt / $totalAnswered;
                        $effectiveness = match(true) {
                            $pct >= 0.05 => 'effective',     // dipilih ≥5%
                            $pct >= 0.02 => 'weak',          // dipilih 2-4%
                            default      => 'not_effective',  // dipilih <2%
                        };
                    }

                    $distractors[$key] = [
                        'count'         => $cnt,
                        'percentage'    => $totalAnswered > 0 ? round($cnt / $totalAnswered * 100, 1) : 0,
                        'is_correct'    => $isCorrect,
                        'effectiveness' => $effectiveness,
                    ];
                }
            }

            // ── Kategori & Rekomendasi ──────────────────────────────────────
            $diffCat = match(true) {
                $p >= 0.76 => 'very_easy',
                $p >= 0.51 => 'easy',
                $p >= 0.26 => 'ideal',
                $p >= 0.11 => 'hard',
                default    => 'very_hard',
            };

            $discCat = match(true) {
                $d >= 0.40 => 'good',
                $d >= 0.30 => 'acceptable',
                $d >= 0.20 => 'poor',
                default    => 'very_poor',
            };

            $rpbisCat = match(true) {
                $rpbis >= 0.40 => 'excellent',
                $rpbis >= 0.30 => 'good',
                $rpbis >= 0.20 => 'acceptable',
                $rpbis >= 0.10 => 'poor',
                default        => 'very_poor',
            };

            $recommendation = $this->recommend($p, $d, $rpbis);

            $pValues[]   = $p;
            $variances[] = $p * (1 - $p);

            $items[] = [
                'question_id'              => $q->id,
                'question_text'            => $q->question_text,
                'question_type'            => $q->question_type,
                'difficulty_index'         => round($p, 3),
                'difficulty_category'      => $diffCat,
                'discrimination_index'     => round($d, 3),
                'discrimination_category'  => $discCat,
                'point_biserial'           => round($rpbis, 3),
                'point_biserial_category'  => $rpbisCat,
                'omit_count'               => $omitCount,
                'omit_rate'                => $n > 0 ? round($omitCount / $n * 100, 1) : 0,
                'recommendation'           => $recommendation,
                'options_distribution'     => $distractors,
                'correct_option'           => $q->correct_answer,
                'total_answered'           => $totalAnswered,
                'correct_count'            => $correctTotal,
            ];
        }

        $scores = $allScores->sort()->values();

        // ── KR-20 Reliability ───────────────────────────────────────────────
        $kr20 = $this->calculateKR20($n, $pValues, $variances, $sessions);

        // ── Summary per rekomendasi ─────────────────────────────────────────
        $summary = [
            'total'         => count($items),
            'keep'          => count(array_filter($items, fn($i) => $i['recommendation'] === 'keep')),
            'review'        => count(array_filter($items, fn($i) => $i['recommendation'] === 'review')),
            'revise'        => count(array_filter($items, fn($i) => $i['recommendation'] === 'revise')),
            'remove'        => count(array_filter($items, fn($i) => $i['recommendation'] === 'remove')),
        ];

        // ── Distribusi tingkat kesulitan ────────────────────────────────────
        $diffDist = [
            'very_easy' => count(array_filter($items, fn($i) => $i['difficulty_category'] === 'very_easy')),
            'easy'      => count(array_filter($items, fn($i) => $i['difficulty_category'] === 'easy')),
            'ideal'     => count(array_filter($items, fn($i) => $i['difficulty_category'] === 'ideal')),
            'hard'      => count(array_filter($items, fn($i) => $i['difficulty_category'] === 'hard')),
            'very_hard' => count(array_filter($items, fn($i) => $i['difficulty_category'] === 'very_hard')),
        ];

        return [
            'error'                  => false,
            'exam_id'                => $exam->id,
            'exam_title'             => $exam->title,
            'total_students'         => $n,
            'kr20'                   => round($kr20, 3),
            'kr20_category'          => $this->kr20Category($kr20),
            'mean_score'             => round($scores->avg(), 2),
            'std_dev'                => round($stdTotal, 2),
            'min_score'              => round($scores->first(), 2),
            'max_score'              => round($scores->last(), 2),
            'summary'                => $summary,
            'difficulty_distribution'=> $diffDist,
            'items'                  => $items,
            'generated_at'           => now()->toIso8601String(),
        ];
    }

    /**
     * Versi ringkas tanpa detail per soal — untuk header dashboard Flutter.
     */
    public function summary(Exam $exam): array
    {
        $result = $this->analyze($exam);
        if ($result['error']) return $result;

        return array_diff_key($result, array_flip(['items']));
    }

    /**
     * Export hasil analisis ke format CSV string.
     */
    public function exportCsv(Exam $exam): string
    {
        $result = $this->analyze($exam);

        if ($result['error']) {
            return "error\n" . $result['message'];
        }

        $lines = [
            "Ujian,{$result['exam_title']}",
            "Jumlah Siswa,{$result['total_students']}",
            "KR-20 Reliability,{$result['kr20']} ({$result['kr20_category']})",
            "Rata-rata Nilai,{$result['mean_score']}",
            "Std Dev,{$result['std_dev']}",
            "Tanggal Analisis,{$result['generated_at']}",
            '',
            'No,ID Soal,Teks Soal (50 karakter),Tipe,Tingkat,P-Index,Kategori P,D-Index,Kategori D,r_pbis,Kategori r_pbis,Omit Rate (%),Rekomendasi',
        ];

        foreach ($result['items'] as $i => $item) {
            $text = '"' . str_replace('"', '""', mb_substr($item['question_text'], 0, 50)) . '"';
            $lines[] = implode(',', [
                $i + 1,
                $item['question_id'],
                $text,
                $item['question_type'],
                $item['difficulty_level'],
                $item['difficulty_index'],
                $item['difficulty_category'],
                $item['discrimination_index'],
                $item['discrimination_category'],
                $item['point_biserial'],
                $item['point_biserial_category'],
                $item['omit_rate'],
                $item['recommendation'],
            ]);
        }

        return implode("\n", $lines);
    }

    // ─── Helper Privat ───────────────────────────────────────────────────────

    private function recommend(float $p, float $d, float $rpbis): string
    {
        // Soal ideal: tingkat kesulitan sedang, diskriminasi & r_pbis baik
        if ($p >= 0.26 && $p <= 0.75 && $d >= 0.30 && $rpbis >= 0.20) return 'keep';
        if ($p >= 0.26 && $p <= 0.75 && ($d >= 0.20 || $rpbis >= 0.15)) return 'review';
        if ($d >= 0.10 || $rpbis >= 0.10) return 'revise';
        return 'remove';
    }

    private function kr20Category(float $kr20): string
    {
        return match(true) {
            $kr20 >= 0.90 => 'sangat_tinggi',
            $kr20 >= 0.80 => 'tinggi',
            $kr20 >= 0.70 => 'cukup',
            $kr20 >= 0.60 => 'rendah',
            default        => 'sangat_rendah',
        };
    }

    private function stdDev(array $values): float
    {
        $n = count($values);
        if ($n < 2) return 0;
        $mean = array_sum($values) / $n;
        $variance = array_sum(array_map(fn($v) => pow($v - $mean, 2), $values)) / $n;
        return sqrt($variance);
    }

    private function calculateKR20(int $n, array $pValues, array $variances, \Illuminate\Support\Collection $sessions): float
    {
        $k = count($pValues);
        if ($k < 2) return 0;

        $sumPQ  = array_sum($variances);
        $scores = $sessions->pluck('score')->map(fn($s) => (float)$s)->toArray();
        $vt     = $this->stdDev($scores) ** 2;

        if ($vt == 0) return 0;

        return ($k / ($k - 1)) * (1 - ($sumPQ / $vt));
    }
}

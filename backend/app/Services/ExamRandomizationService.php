<?php
namespace App\Services;

use App\Models\Exam;
use App\Models\ExamSession;
use App\Models\Question;

/**
 * ExamRandomizationService — LCG Engine (PHP)
 * Algoritma: X(n+1) = (A * X(n) + C) mod M
 * Constants:  A=1664525, C=1013904223, M=2^32
 * IDENTIK dengan lcg.js frontend.
 */
class ExamRandomizationService
{
    private const A = 1664525;
    private const C = 1013904223;
    private const M = 4294967296; // 2^32

    private int $state        = 1;
    private int $initialState = 1;

    /* ── LCG Core ──────────────────────────────────────── */

    public function seed(int $seed): void
    {
        $this->state        = $seed & 0xFFFFFFFF;
        $this->initialState = $this->state;
    }

    public function next(): int
    {
        if (PHP_INT_SIZE >= 8) {
            $this->state = (self::A * $this->state + self::C) % self::M;
        } else {
            $this->state = (int) gmp_intval(
                gmp_mod(gmp_add(gmp_mul(self::A, $this->state), self::C), self::M)
            );
        }
        return $this->state;
    }

    public function reset(): void { $this->state = $this->initialState; }

    /**
     * Fisher-Yates shuffle — identik dengan JS
     */
    public function shuffle(array $array): array
    {
        $n = count($array);
        for ($i = $n - 1; $i > 0; $i--) {
            $j = $this->next() % ($i + 1);
            [$array[$i], $array[$j]] = [$array[$j], $array[$i]];
        }
        return $array;
    }

    /**
     * Verifikasi N langkah pertama — cross-check dengan JS
     */
    public function verify(int $seed, int $steps = 5): array
    {
        $this->seed($seed);
        $out = [];
        for ($i = 0; $i < $steps; $i++) $out[] = $this->next();
        return $out;
    }

    /* ── Question Order ────────────────────────────────── */

    public function generateQuestionOrder(Exam $exam, int $seed): array
    {
        $ids = $exam->questions()
            ->wherePivot('is_active', true)
            ->orderBy('exam_questions.display_order')
            ->pluck('questions.id')
            ->toArray();

        if (!$exam->randomize_questions) return $ids;
        $this->seed($seed);
        return $this->shuffle($ids);
    }

    /* ── Option Shuffle ────────────────────────────────── */

    /**
     * Acak opsi satu soal.
     * Seed soal = (globalSeed + questionId) & 0xFFFFFFFF  ← sama dengan JS
     */
    public function shuffleOptions(Question $question, int $globalSeed): array
    {
        $options = $question->options ?? [];
        if (empty($options)) {
            return ['options' => $options, 'correct_answer' => $question->correct_answer, 'key_map' => []];
        }

        $seedQ = ($globalSeed + $question->id) & 0xFFFFFFFF;
        $this->seed($seedQ);

        $origKeys   = array_keys($options);
        $origValues = array_values($options);
        $shuffVals  = $this->shuffle($origValues);

        $newOptions = [];
        $keyMap     = [];

        // Map nilai yg sudah diacak kembali ke key asli — pakai loop, hindari array_search
        // yg salah kalau ada 2 opsi bernilai sama.
        $valToOrigKey = [];
        foreach ($origKeys as $i => $k) {
            $valToOrigKey[$origValues[$i]] = $k;
        }
        foreach ($origKeys as $i => $oldKey) {
            $newKey              = $origKeys[$i];
            $newOptions[$newKey] = $shuffVals[$i];
            $oldKeyForVal        = $valToOrigKey[$shuffVals[$i]] ?? $oldKey;
            $keyMap[$oldKeyForVal] = $newKey;
        }

        $newCorrect = $keyMap[$question->correct_answer] ?? $question->correct_answer;

        return ['options' => $newOptions, 'correct_answer' => $newCorrect, 'key_map' => $keyMap];
    }

    /* ── Build Questions for Student ───────────────────── */

    /**
     * Susun soal yang sudah diacak untuk dikirim ke siswa.
     * correct_answer TIDAK disertakan selama ujian berlangsung.
     */
    public function buildShuffledQuestions(Exam $exam, ExamSession $session): array
    {
        $order = $session->question_order ?? [];
        $seed  = $session->seed;

        $byId   = Question::whereIn('id', $order)->get()->keyBy('id');
        $result = [];

        foreach ($order as $qId) {
            $q = $byId->get($qId);
            if (!$q) continue;

            $shuffled = ($exam->randomize_options && $q->question_type === 'multiple_choice')
                ? $this->shuffleOptions($q, $seed)
                : ['options' => $q->options, 'correct_answer' => $q->correct_answer];

            $result[] = [
                'id'            => $q->id,
                'question_text' => $q->question_text,
                'question_type' => $q->question_type,
                'options'       => $shuffled['options'],
                'image_url'     => $q->image_url,
            ];
        }

        return $result;
    }

    /* ── Grading with LCG ──────────────────────────────── */

    /**
     * Grade jawaban siswa dengan memperhitungkan opsi yang diacak.
     * userAnswer adalah kunci SETELAH diacak (A/B/C/D dari tampilan siswa).
     */
    public function gradeAnswer(Question $question, ?string $userAnswer, int $globalSeed, bool $optionsShuffled = true): bool
    {
        if ($userAnswer === null || $userAnswer === '') return false;

        if (!$optionsShuffled || $question->question_type !== 'multiple_choice') {
            return strtoupper(trim($userAnswer)) === strtoupper(trim($question->correct_answer ?? ''));
        }

        $shuffled        = $this->shuffleOptions($question, $globalSeed);
        $shuffledCorrect = $shuffled['correct_answer'];

        return strtoupper(trim($userAnswer)) === strtoupper(trim($shuffledCorrect));
    }

    /* ── Session Management ────────────────────────────── */

    public function createSession(Exam $exam, int $studentId): ExamSession
    {
        $existing = ExamSession::where('exam_id', $exam->id)
            ->where('student_id', $studentId)->where('status', 'in_progress')->first();
        if ($existing) return $existing;

        $submitted = ExamSession::where('exam_id', $exam->id)
            ->where('student_id', $studentId)
            ->whereIn('status', ['submitted','timeout','force_submitted'])->exists();
        if ($submitted) abort(403, 'Anda sudah mengerjakan ujian ini.');

        $seed          = $this->generateUniqueSeed($exam->id, $studentId);
        $questionOrder = $this->generateQuestionOrder($exam, $seed);

        return ExamSession::create([
            'exam_id'          => $exam->id,
            'student_id'       => $studentId,
            'seed'             => $seed,
            'question_order'   => $questionOrder,
            'status'           => 'in_progress',
            'started_at'       => now(),
            'last_activity_at' => now(),
            'remaining_seconds'=> $exam->duration_minutes * 60,
        ]);
    }

    public function generateUniqueSeed(int $examId, int $studentId): int
    {
        $entropy = unpack('N', random_bytes(4))[1];
        $seed    = ($entropy ^ ($examId * 2654435761) ^ ($studentId * 1664525)) & 0xFFFFFFFF;
        return $seed ?: 1;
    }

    public function verifySeedConsistency(int $seed, array $frontendVerify): bool
    {
        return $this->verify($seed, count($frontendVerify)) === $frontendVerify;
    }
}

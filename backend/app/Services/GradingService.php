<?php
namespace App\Services;

use App\Models\Exam;
use App\Models\ExamSession;
use App\Models\ExamSessionAnswer;
use App\Models\Question;

class GradingService
{
    public function __construct(private ExamRandomizationService $randomizer) {}

    /**
     * Grade sesi ujian — menggunakan LCG seed untuk decode jawaban
     */
    public function gradeSession(ExamSession $session): ExamSession
    {
        $exam    = $session->exam;
        $seed    = $session->seed;
        $answers = $session->answers()->with('question')->get();

        $totalWeight  = 0;
        $earnedWeight = 0;

        foreach ($answers as $answer) {
            $q = $answer->question;
            if (!$q) continue;

            $totalWeight += $q->weight;

            // Grade dengan mempertimbangkan opsi yang diacak LCG
            $isCorrect = ($q->question_type === 'essay')
                ? false
                : $this->randomizer->gradeAnswer(
                    $q,
                    $answer->answer,
                    $seed,
                    $exam->randomize_options ?? true
                );

            $score = $isCorrect ? $q->weight : 0;
            $answer->update(['is_correct' => $isCorrect, 'score' => $score]);
            if ($isCorrect) $earnedWeight += $q->weight;
        }

        $score    = $totalWeight > 0 ? round(($earnedWeight / $totalWeight) * 100, 2) : 0;
        $isPassed = $score >= $exam->passing_grade;

        $session->update([
            'score'        => $score,
            'is_passed'    => $isPassed,
            'status'       => 'submitted',
            'submitted_at' => now(),
        ]);

        return $session->fresh();
    }

    /**
     * Hasil lengkap sesi — opsi tampil dengan urutan ASLI
     * agar pembahasan mudah dipahami
     */
    public function getSessionResult(ExamSession $session): array
    {
        $exam    = $session->exam;
        $answers = $session->answers()->with('question')->get();
        $seed    = $session->seed;

        $correct    = $answers->where('is_correct', true)->count();
        $wrong      = $answers->where('is_correct', false)->whereNotNull('answer')->count();
        $unanswered = $answers->whereNull('answer')->count();

        $durationTaken = ($session->started_at && $session->submitted_at)
            ? min($session->started_at->diffInSeconds($session->submitted_at), $exam->duration_minutes * 60)
            : 0;

        $answersDetail = $answers->map(function ($a) use ($exam, $seed) {
            $q = $a->question;

            // Rekonstruksi opsi diacak untuk ditampilkan di pembahasan
            $shuffledData   = null;
            $shuffledCorrect= $q->correct_answer;

            if ($exam->randomize_options && $q->question_type === 'multiple_choice') {
                $shuffledData    = $this->randomizer->shuffleOptions($q, $seed);
                $shuffledCorrect = $shuffledData['correct_answer'];
            }

            return [
                'question_id'     => $q->id,
                'question_text'   => $q->question_text,
                'question_type'   => $q->question_type,
                'difficulty'      => $q->difficulty,
                // Opsi dalam urutan yang dilihat siswa (sudah diacak)
                'options'         => $shuffledData['options'] ?? $q->options,
                // Kunci benar dalam urutan yang dilihat siswa
                'correct_answer'  => $exam->show_result_immediately ? $shuffledCorrect : null,
                // Kunci benar dalam urutan ASLI (untuk referensi internal)
                'original_correct'=> $exam->show_result_immediately ? $q->correct_answer : null,
                'explanation'     => $exam->show_result_immediately ? $q->explanation : null,
                'user_answer'     => $a->answer,
                'is_correct'      => $a->is_correct,
                'score'           => $a->score,
                'status'          => $a->answer === null ? 'unanswered' : ($a->is_correct ? 'correct' : 'wrong'),
            ];
        });

        return [
            'session'        => $session,
            'class_name'     => $exam->classRoom?->name ?? '',
            'score'          => $session->score,
            'is_passed'      => $session->is_passed,
            'passing_grade'  => $exam->passing_grade,
            'correct'        => $correct,
            'wrong'          => $wrong,
            'unanswered'     => $unanswered,
            'total'          => $answers->count(),
            'duration_taken' => $durationTaken,
            'answers'        => $answersDetail,
        ];
    }

    public function recalculateSessionScore(ExamSession $session): void
    {
        $answers     = $session->answers()->with('question')->get();
        $totalWeight = $answers->sum(fn($a) => $a->question->weight ?? 0);
        $earned      = $answers->sum('score');
        $score       = $totalWeight > 0 ? round(($earned / $totalWeight) * 100, 2) : 0;
        $session->update(['score' => $score, 'is_passed' => $score >= $session->exam->passing_grade]);
    }
}

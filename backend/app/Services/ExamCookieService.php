<?php
namespace App\Services;

use App\Models\Exam;
use App\Models\ExamSession;

/**
 * ExamCookieService
 *
 * Membangun dan memverifikasi local_state payload yang dikirim ke klien Flutter.
 * Flutter menyimpan payload ini di SharedPreferences (mobile) atau localStorage (web).
 *
 * Format payload:
 * {
 *   "session_id": 123,
 *   "exam_id": 456,
 *   "seed": 789012,
 *   "lcg": { "a": ..., "c": ..., "m": ... },
 *   "question_order": [5, 1, 3, ...],
 *   "answers": {},
 *   "remaining_seconds": 5400,
 *   "expires_at": "2024-01-01T12:00:00Z",
 *   "signature": "hmac_sha256_hex"
 * }
 */
class ExamCookieService
{
    /**
     * Bangun payload local_state lengkap untuk klien Flutter.
     */
    public function buildLocalStatePayload(ExamSession $session, Exam $exam): array
    {
        $expiresAt = now()->addSeconds($session->remaining_seconds)->addMinutes(30);

        $payload = [
            'session_id'        => $session->id,
            'exam_id'           => $exam->id,
            'seed'              => $session->seed,
            // Konstanta LCG agar Flutter bisa mereproduksi pengacakan tanpa minta server
            'lcg'               => [
                'a' => 1664525,
                'c' => 1013904223,
                'm' => 4294967296,
                'algorithm' => 'fisher-yates-lcg',
            ],
            'question_order'    => $session->question_order ?? [],
            'answers'           => (object)[], // kosong saat mulai, Flutter yang mengisi
            'remaining_seconds' => $session->remaining_seconds,
            'started_at'        => $session->started_at?->toIso8601String(),
            'expires_at'        => $expiresAt->toIso8601String(),
            'randomize_options' => (bool)$exam->randomize_options,
            'max_violations'    => $exam->max_violations,
        ];

        // Tanda tangan HMAC untuk mencegah manipulasi di sisi klien
        $payload['signature'] = $this->signPayload($payload);

        return $payload;
    }

    /**
     * Buat HMAC signature dari payload (tanpa field 'signature' dan 'answers').
     * Flutter mengirim signature ini kembali, server verifikasi sebelum submit.
     */
    public function signPayload(array $payload): string
    {
        // Kecualikan 'signature' dan 'answers' dari signing (answers berubah terus)
        $toSign = array_diff_key($payload, array_flip(['signature', 'answers']));
        ksort($toSign);

        return hash_hmac('sha256', json_encode($toSign), config('app.key'));
    }

    /**
     * Verifikasi signature payload dari klien Flutter.
     * Gunakan sebelum memproses submit untuk mencegah data palsu.
     */
    public function verifySignature(array $payload): bool
    {
        if (empty($payload['signature'])) {
            return false;
        }

        $clientSig = $payload['signature'];
        $expected  = $this->signPayload($payload);

        return hash_equals($expected, $clientSig);
    }

    /**
     * Bangun payload ringkas untuk resume session (ketika Flutter sudah punya state).
     * Hanya kirim info minimal untuk update timer.
     */
    public function buildResumePayload(ExamSession $session): array
    {
        return [
            'session_id'        => $session->id,
            'remaining_seconds' => $session->remaining_seconds,
            'last_synced_at'    => $session->last_bulk_sync_at?->toIso8601String(),
            'sync_count'        => $session->sync_count,
        ];
    }
}

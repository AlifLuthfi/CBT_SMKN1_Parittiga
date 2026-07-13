<?php

namespace App\Services;

/**
 * LcgService — Linear Congruential Generator (LCG)
 *
 * X(n+1) = (A * X(n) + C) mod M
 *
 * Constants: A=1664525, C=1013904223, M=2^32
 * Identik dengan implementasi lcg.js di frontend.
 */
class LcgService
{
    private const A = 1664525;
    private const C = 1013904223;
    private const M = 4294967296; // 2^32

    private int $state;
    private int $initialState;

    public function __construct(int $seed = 1)
    {
        $this->seed($seed);
    }

    /**
     * Seed generator. Pastikan dalam range 32-bit unsigned.
     */
    public function seed(int $seed): void
    {
        $this->state        = $seed & 0xFFFFFFFF;
        $this->initialState = $this->state;
    }

    /**
     * Generate nilai LCG berikutnya.
     */
    public function next(): int
    {
        if (PHP_INT_SIZE >= 8) {
            // PHP 64-bit — hitung langsung
            $this->state = (self::A * $this->state + self::C) % self::M;
        } else {
            // PHP 32-bit — pakai GMP
            $this->state = (int) gmp_intval(
                gmp_mod(gmp_add(gmp_mul(self::A, $this->state), self::C), self::M)
            );
        }

        return $this->state;
    }

    /**
     * Reset ke state awal.
     */
    public function reset(): void
    {
        $this->state = $this->initialState;
    }

    /**
     * Ambil state saat ini (untuk debugging).
     */
    public function getState(): int
    {
        return $this->state;
    }

    /**
     * Hasilkan N langkah pertama — untuk verifikasi cross-platform.
     */
    public function generate(int $steps): array
    {
        $out = [];
        for ($i = 0; $i < $steps; $i++) {
            $out[] = $this->next();
        }

        return $out;
    }

    /**
     * Fisher-Yates shuffle menggunakan LCG.
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
     * Verifikasi konsistensi antara frontend (JS) dan backend (PHP).
     * Bandingkan output LCG dari seed tertentu.
     */
    public function verifyConsistency(int $seed, array $frontendOutput): bool
    {
        return $this->generateWithSeed($seed, count($frontendOutput)) === $frontendOutput;
    }

    /**
     * Generate N langkah dari seed tertentu (tanpa mengganggu state instance).
     */
    public function generateWithSeed(int $seed, int $steps): array
    {
        $saved    = $this->state;
        $savedInit = $this->initialState;

        $this->seed($seed);
        $out = $this->generate($steps);

        $this->state        = $saved;
        $this->initialState = $savedInit;

        return $out;
    }

    /**
     * Generate seed unik kombinasi examId + studentId + random.
     */
    public function generateUniqueSeed(int $examId, int $studentId): int
    {
        $entropy = unpack('N', random_bytes(4))[1];
        $seed    = ($entropy ^ ($examId * 2654435761) ^ ($studentId * 1664525)) & 0xFFFFFFFF;

        return $seed ?: 1;
    }
}

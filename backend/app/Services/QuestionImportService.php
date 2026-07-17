<?php
namespace App\Services;

use App\Models\Question;
use App\Models\QuestionImport;
use Illuminate\Http\UploadedFile;
use Shuchkin\SimpleXLSX;
use Shuchkin\SimpleXLSXGen;

class QuestionImportService
{
    // ─── Template ────────────────────────────────────────────────────────────

    public function generateTemplate(): string
    {
        $rows = [
            ['question_text', 'option_a', 'option_b', 'option_c', 'option_d', 'option_e', 'correct_answer', 'explanation'],
            ['Ibukota Indonesia adalah', 'Jakarta', 'Surabaya', 'Bandung', 'Medan', '', 'C', ''],
            ['Hewan ovipar adalah', 'Kucing', 'Anjing', 'Ikan', 'Sapi', '', 'C', ''],
            ['Bilangan prima terkecil', '0', '1', '2', '3', '', 'C', ''],
            ['Apa fungsi akar pada tumbuhan?', 'Menyerap air', 'Fotosintesis', 'Berkembang biak', 'Bernapas', '', 'A', 'Menyerap air dan mineral'],
        ];

        $xlsx = SimpleXLSXGen::fromArray($rows, 'Soal');
        $path = tempnam(sys_get_temp_dir(), 'template_') . '.xlsx';
        $xlsx->saveAs($path);
        return $path;
    }

    // ─── Import utama (CSV atau XLSX) ────────────────────────────────────────

    public function import(UploadedFile $file, int $teacherId, ?int $subjectId = null): QuestionImport
    {
        $record = QuestionImport::create([
            'teacher_id' => $teacherId,
            'filename'   => $file->getClientOriginalName(),
            'status'     => 'processing',
        ]);

        try {
            $ext  = strtolower($file->getClientOriginalExtension());
            $rows = match($ext) {
                'xlsx', 'xls' => $this->readXlsx($file->getRealPath()),
                default        => $this->readCsv($file->getRealPath()),
            };

            $record->update(['total_rows' => count($rows)]);

            [$success, $errors] = $this->processRows($rows, $teacherId, $subjectId);

            $record->update([
                'success_count' => $success,
                'error_count'   => count($errors),
                'errors'        => $errors,
                'status'        => 'completed',
            ]);
        } catch (\Throwable $e) {
            $record->update(['status' => 'failed', 'errors' => [$e->getMessage()]]);
        }

        return $record->fresh();
    }

    // ─── Preview (parse tanpa simpan ke DB) ─────────────────────────────────

    public function preview(UploadedFile $file, int $teacherId): array
    {
        $ext  = strtolower($file->getClientOriginalExtension());
        $rows = match($ext) {
            'xlsx', 'xls' => $this->readXlsx($file->getRealPath()),
            default        => $this->readCsv($file->getRealPath()),
        };

        $preview  = [];
        $errCount = 0;

        foreach (array_slice($rows, 0, 20) as $i => $row) {
            $rowNum   = $i + 2;
            $validated = $this->validateRow($row, $rowNum, $teacherId);
            if ($validated['valid']) {
                $preview[] = array_merge($validated['data'], ['row' => $rowNum, 'status' => 'ok']);
            } else {
                $errCount++;
                $preview[] = ['row' => $rowNum, 'status' => 'error', 'errors' => $validated['errors']];
            }
        }

        return [
            'total_rows'     => count($rows),
            'preview_rows'   => count($preview),
            'valid_count'    => count($rows) - $errCount,
            'error_count'    => $errCount,
            'preview'        => $preview,
        ];
    }

    // ─── Retry import yang gagal ────────────────────────────────────────────

    public function retry(QuestionImport $import, int $teacherId): QuestionImport
    {
        if (!in_array($import->status, ['failed', 'completed'])) {
            throw new \RuntimeException('Import tidak dapat di-retry dalam status: ' . $import->status);
        }
        if ($import->teacher_id !== $teacherId) {
            throw new \RuntimeException('Akses ditolak.');
        }

        // Import ulang butuh file asli — file sudah tidak ada, kembalikan error informatif
        throw new \RuntimeException('File asli tidak disimpan di server. Upload ulang file untuk retry.');
    }

    // ─── Baca XLSX ──────────────────────────────────────────────────────────

    private function readXlsx(string $path): array
    {
        $xlsx = SimpleXLSX::parse($path);
        if (!$xlsx) {
            throw new \RuntimeException('Gagal membaca file XLSX: ' . SimpleXLSX::parseError());
        }

        $rows = $xlsx->rows();
        array_shift($rows); // buang header

        return array_values(array_filter($rows, fn($r) => !empty(array_filter($r, fn($v) => trim((string)$v) !== ''))));
    }

    // ─── Baca CSV ───────────────────────────────────────────────────────────

    private function readCsv(string $path): array
    {
        $content = file_get_contents($path);
        $content = preg_replace('/^\xEF\xBB\xBF/', '', $content); // Remove BOM
        $lines   = array_filter(explode("\n", str_replace("\r\n", "\n", $content)));
        $rows    = array_values($lines);
        array_shift($rows); // buang header

        return array_map([$this, 'parseCsvLine'], $rows);
    }

    // ─── Proses baris data ──────────────────────────────────────────────────

    private function processRows(array $rows, int $teacherId, ?int $subjectId = null): array
    {
        $success = 0;
        $errors  = [];

        foreach ($rows as $i => $row) {
            $rowNum    = $i + 2;
            $validated = $this->validateRow($row, $rowNum, $teacherId);

            if (!$validated['valid']) {
                $errors[] = implode('; ', $validated['errors']);
                continue;
            }

            $data = $validated['data'];

            // Cek duplikat question_text milik guru yang sama
            $exists = Question::where('teacher_id', $teacherId)
                ->where('question_text', $data['question_text'])
                ->exists();

            if ($exists) {
                $errors[] = "Baris $rowNum: Soal duplikat sudah ada di bank soal Anda.";
                continue;
            }

            Question::create(array_filter([
                'teacher_id'     => $teacherId,
                'subject_id'     => $subjectId,
                'question_text'  => $data['question_text'],
                'question_type'  => $data['question_type'],
                'options'        => $data['options'],
                'correct_answer' => $data['correct_answer'],
                'explanation'    => $data['explanation'],
            ]));

            $success++;
        }

        return [$success, $errors];
    }

    // ─── Validasi satu baris ────────────────────────────────────────────────

    private function validateRow(array $cols, int $rowNum, int $teacherId): array
    {
        // Normalisasi: XLSX mungkin kembalikan array dengan key numerik
        $cols = array_values($cols);

        if (count($cols) < 7) {
            return ['valid' => false, 'errors' => ["Baris $rowNum: Jumlah kolom kurang dari 7 (minimal: question_text, option_a, option_b, correct_answer)."]];
        }

        // Format: [0]question_text [1]option_a [2]option_b [3]option_c [4]option_d [5]option_e
        //         [6]correct_answer [7]explanation
        [$text, $optA, $optB, $optC, $optD, $optE, $correct, $explanation]
            = array_pad(array_map(fn($v) => trim((string)$v), $cols), 8, '');

        $errors = [];

        if (empty($text))  $errors[] = "Baris $rowNum: question_text kosong.";

        // Semua soal adalah pilihan ganda — minimal 2 opsi wajib
        $options = array_filter(['A' => $optA, 'B' => $optB, 'C' => $optC, 'D' => $optD, 'E' => $optE]);
        if (count($options) < 2) {
            $errors[] = "Baris $rowNum: Minimal 2 opsi jawaban diperlukan (option_a dan option_b wajib diisi).";
        }

        $correctUpper = strtoupper($correct);
        if (!empty($correct) && !empty($options) && !array_key_exists($correctUpper, $options)) {
            $errors[] = "Baris $rowNum: correct_answer '$correct' tidak ada di antara opsi yang tersedia (" . implode(',', array_keys($options)) . ").";
        }

        if (empty($correct)) {
            $errors[] = "Baris $rowNum: correct_answer wajib diisi.";
        }

        if (!empty($errors)) {
            return ['valid' => false, 'errors' => $errors];
        }

        return [
            'valid' => true,
            'data'  => [
                'question_text'  => $text,
                'question_type'  => 'multiple_choice',
                'options'        => $options,
                'correct_answer' => $correctUpper,
                'explanation'    => $explanation ?: null,
            ],
        ];
    }

    // ─── Parse satu baris CSV dengan quote-aware ─────────────────────────────

    private function parseCsvLine(string $line): array
    {
        $result  = [];
        $field   = '';
        $inQuote = false;

        for ($i = 0, $len = strlen($line); $i < $len; $i++) {
            $c = $line[$i];
            if ($c === '"') {
                if ($inQuote && isset($line[$i + 1]) && $line[$i + 1] === '"') {
                    $field .= '"';
                    $i++;
                } else {
                    $inQuote = !$inQuote;
                }
            } elseif ($c === ',' && !$inQuote) {
                $result[] = trim($field);
                $field    = '';
            } else {
                $field .= $c;
            }
        }

        $result[] = trim($field);
        return $result;
    }
}

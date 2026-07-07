<?php
namespace App\Services;

use App\Models\Question;
use App\Models\QuestionCategory;
use App\Models\QuestionImport;
use Illuminate\Http\UploadedFile;
use Shuchkin\SimpleXLSX;

class QuestionImportService
{
    // ─── Template ────────────────────────────────────────────────────────────

    public function generateTemplate(): string
    {
        // Kolom: question_text, option_a, option_b, option_c, option_d, option_e,
        //        correct_answer, difficulty, weight, explanation, category, tags
        $header = "question_text,option_a,option_b,option_c,option_d,option_e,correct_answer,difficulty,weight,explanation,category,tags\n";
        $rows   = [
            '"Hitunglah nilai x jika 2x+5=11","x=2","x=3","x=4","x=5",,B,easy,1,"2x=6, x=3",Aljabar,"Bab 1;UTS"',
            '"Nilai sin 30° adalah","0.25","0.5","0.75","1.0",,B,easy,1,"sin 30°=1/2=0.5",Trigonometri,"Bab 3"',
            '"Planet terbesar dalam tata surya adalah","Bumi","Jupiter","Saturnus","Mars",,B,medium,1,,IPA,',
            '"Ibukota Indonesia adalah","Surabaya","Bandung","Jakarta","Medan",,C,easy,1,,IPS,"Geografi;Kelas 5"',
        ];
        return $header . implode("\n", $rows);
    }

    // ─── Import utama (CSV atau XLSX) ────────────────────────────────────────

    public function import(UploadedFile $file, int $teacherId, ?int $categoryId = null): QuestionImport
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

            [$success, $errors] = $this->processRows($rows, $teacherId, $categoryId);

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

    public function retry(QuestionImport $import, int $teacherId, ?int $categoryId = null): QuestionImport
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

    private function processRows(array $rows, int $teacherId, ?int $categoryId): array
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

            // Resolve category
            $catId = $categoryId;
            if (!$catId && !empty($data['category'])) {
                $cat   = QuestionCategory::firstOrCreate(
                    ['teacher_id' => $teacherId, 'name' => $data['category']]
                );
                $catId = $cat->id;
            }

            // Cek duplikat question_text milik guru yang sama
            $exists = Question::where('teacher_id', $teacherId)
                ->where('question_text', $data['question_text'])
                ->exists();

            if ($exists) {
                $errors[] = "Baris $rowNum: Soal duplikat sudah ada di bank soal Anda.";
                continue;
            }

            Question::create([
                'teacher_id'     => $teacherId,
                'category_id'    => $catId,
                'question_text'  => $data['question_text'],
                'question_type'  => $data['question_type'],
                'options'        => $data['options'],
                'correct_answer' => $data['correct_answer'],
                'explanation'    => $data['explanation'],
                'difficulty'     => $data['difficulty'],
                'weight'         => $data['weight'],
                'tags'           => $data['tags'],
            ]);

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
            return ['valid' => false, 'errors' => ["Baris $rowNum: Jumlah kolom kurang dari 7 (minimal: question_text, option_a, option_b, correct_answer, difficulty, weight)."]]; 
        }

        // Format baru tanpa question_type:
        // [0]question_text [1]option_a [2]option_b [3]option_c [4]option_d [5]option_e
        // [6]correct_answer [7]difficulty [8]weight [9]explanation [10]category [11]tags
        [$text, $optA, $optB, $optC, $optD, $optE, $correct, $difficulty, $weight, $explanation, $category, $tags]
            = array_pad(array_map(fn($v) => trim((string)$v), $cols), 12, '');

        $errors = [];

        if (empty($text))  $errors[] = "Baris $rowNum: question_text kosong.";

        if (!in_array($difficulty, ['easy', 'medium', 'hard'])) {
            $errors[] = "Baris $rowNum: difficulty '$difficulty' tidak valid. Gunakan: easy, medium, hard.";
        }

        $weightVal = max(0.1, (float)($weight ?: 1));

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

        // Parse tags: "Bab 1;UTS" → ["Bab 1", "UTS"]
        $tagsArr = !empty($tags)
            ? array_values(array_filter(array_map('trim', explode(';', $tags))))
            : null;

        return [
            'valid' => true,
            'data'  => [
                'question_text'  => $text,
                'question_type'  => 'multiple_choice', // selalu pilihan ganda
                'options'        => $options,
                'correct_answer' => $correctUpper,
                'explanation'    => $explanation ?: null,
                'difficulty'     => $difficulty,
                'weight'         => $weightVal,
                'category'       => $category ?: null,
                'tags'           => $tagsArr,
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

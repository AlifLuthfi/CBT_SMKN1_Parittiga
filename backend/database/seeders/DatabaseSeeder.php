<?php
namespace Database\Seeders;

use App\Models\ClassRoom;
use App\Models\Exam;
use App\Models\ExamQuestion;
use App\Models\Question;

use App\Models\TeacherProfile;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ── ADMIN ──
        $admin = User::where('email', 'admin@examcore.id')
            ->orWhere('nip', '000001')
            ->first();

        if (! $admin) {
            $admin = new User();
        }

        $admin->name     = 'Administrator';
        $admin->email    = 'admin@examcore.id';
        $admin->password = Hash::make('password123');
        $admin->role     = 'admin';
        $admin->status   = 'active';
        $admin->nip      = '000001';
        $admin->save();

        // ── USER SEEDER: 3 guru + 10 siswa ──
        $this->call(UserSeeder::class);

        // ── GURU ──
        $guru = User::where('email', 'guru@examcore.id')
            ->orWhere('nip', '198501012010011001')
            ->first();

        if (! $guru) {
            $guru = new User();
        }

        $guru->name     = 'Budi Santoso';
        $guru->email    = 'guru@examcore.id';
        $guru->password = Hash::make('password123');
        $guru->role     = 'guru';
        $guru->status   = 'active';
        $guru->nip      = '198501012010011001';
        $guru->save();

        $guru2 = User::where('email', 'siti@examcore.id')
            ->orWhere('nip', '198702052012012002')
            ->first();

        if (! $guru2) {
            $guru2 = new User();
        }

        $guru2->name     = 'Siti Rahayu';
        $guru2->email    = 'siti@examcore.id';
        $guru2->password = Hash::make('password123');
        $guru2->role     = 'guru';
        $guru2->status   = 'active';
        $guru2->nip      = '198702052012012002';
        $guru2->save();

        TeacherProfile::updateOrCreate([
            'user_id' => $guru->id,
        ], [
            'preferences' => [
                'default_duration'      => 90,
                'default_passing_grade' => 70,
                'default_max_violations'=> 5,
                'randomize_by_default'  => true,
            ],
        ]);

        // ── SISWA ──
        $siswaNames = [
            ['Ahmad Naufal','ahmadnaufal@siswa.id','2024001'],
            ['Siti Rahayu','sitirahayu@siswa.id','2024002'],
            ['Dita Kusuma','ditakusuma@siswa.id','2024003'],
            ['Rizal Pratama','rizalpratama@siswa.id','2024004'],
            ['Eka Putri','ekaputri@siswa.id','2024005'],
            ['Fajar Nugroho','fajarnugroho@siswa.id','2024006'],
            ['Gita Andriani','gitaandriani@siswa.id','2024007'],
            ['Hendra Wijaya','hendrawijaya@siswa.id','2024008'],
            ['Indah Lestari','indahlestari@siswa.id','2024009'],
            ['Budi Saputra','budisaputra@siswa.id','2024010'],
        ];

        $siswaList = [];
        foreach ($siswaNames as [$name, $email, $nis]) {
            $siswa = User::where('email', $email)
                ->orWhere('nis', $nis)
                ->first();

            if (! $siswa) {
                $siswa = new User();
            }

            $siswa->name     = $name;
            $siswa->email    = $email;
            $siswa->password = Hash::make('password123');
            $siswa->role     = 'siswa';
            $siswa->status   = 'active';
            $siswa->nis      = $nis;
            $siswa->save();

            $siswaList[] = $siswa;
        }

        // ── KELAS ──
        $kelas = ClassRoom::updateOrCreate([
            'teacher_id' => $guru->id,
            'name'       => 'X IPA 1',
        ], [
            'subject'       => 'Matematika',
            'academic_year' => '2024/2025',
            'semester'      => 'Ganjil',
        ]);

        // Enroll siswa
        foreach ($siswaList as $siswa) {
            $kelas->students()->syncWithoutDetaching([
                $siswa->id => [
                    'status'      => 'active',
                    'enrolled_at' => now(),
                    'enrolled_by' => $guru->id,
                ],
            ]);
        }

        // ── QUESTIONS ──
        $questions = [
            ['Hasil dari persamaan 2x + 5 = 11 adalah...','multiple_choice',['A'=>'x = 2','B'=>'x = 3','C'=>'x = 4','D'=>'x = 5'],'B','easy',1,'2x = 11 - 5 = 6, maka x = 3'],
            ['Nilai dari 3² + 4² adalah...','multiple_choice',['A'=>'14','B'=>'25','C'=>'49','D'=>'7'],'B','easy',1,'3²=9, 4²=16, jadi 9+16=25'],
            ['Jika f(x) = 2x² - 3x + 1, maka nilai f(2) adalah...','multiple_choice',['A'=>'3','B'=>'4','C'=>'5','D'=>'6'],'A','medium',1,'f(2)=2(4)-3(2)+1=8-6+1=3'],
            ['Faktorisasi dari x² - 5x + 6 adalah...','multiple_choice',['A'=>'(x-1)(x-6)','B'=>'(x-2)(x-3)','C'=>'(x+2)(x+3)','D'=>'(x-1)(x+6)'],'B','medium',1,'(x-2)(x-3)=-2×-3=6 dan -2+(-3)=-5 ✓'],
            ['Nilai dari ³√27 + ²√16 adalah...','multiple_choice',['A'=>'5','B'=>'6','C'=>'7','D'=>'8'],'C','easy',1,'³√27=3, ²√16=4, jadi 3+4=7'],
            ['Luas segitiga dengan alas 8 cm dan tinggi 6 cm adalah...','multiple_choice',['A'=>'24 cm²','B'=>'48 cm²','C'=>'14 cm²','D'=>'28 cm²'],'A','easy',1,'L=½×a×t=½×8×6=24 cm²'],
            ['Keliling lingkaran dengan jari-jari 7 cm adalah... (π=22/7)','multiple_choice',['A'=>'22 cm','B'=>'44 cm','C'=>'154 cm','D'=>'308 cm'],'B','medium',1,'K=2πr=2×22/7×7=44 cm'],
            ['Nilai dari sin 30° + cos 60° adalah...','multiple_choice',['A'=>'0','B'=>'½','C'=>'1','D'=>'√2'],'C','medium',1,'sin30°=½, cos60°=½, jadi ½+½=1'],
            ['Jika sin α = 3/5 dan α sudut lancip, maka cos α adalah...','multiple_choice',['A'=>'4/5','B'=>'3/4','C'=>'5/3','D'=>'5/4'],'A','hard',1,'cos α=√(1-sin²α)=√(1-9/25)=√(16/25)=4/5'],
            ['Deret aritmetika 2,5,8,11,... Suku ke-10 adalah...','multiple_choice',['A'=>'27','B'=>'29','C'=>'31','D'=>'33'],'B','medium',1,'a=2, b=3. U10=2+(10-1)×3=2+27=29'],
        ];

        $questionModels = [];
        foreach ($questions as [$text,$type,$opts,$correct,$diff,$weight,$expl]) {
            $questionModels[] = Question::updateOrCreate([
                'teacher_id'    => $guru->id,
                'question_text' => $text,
            ], [
                'question_type' => $type,
                'options'       => $opts,
                'correct_answer'=> $correct,
                'explanation'   => $expl,
                'is_active'     => true,
            ]);
        }

        // ── EXAM ──
        $exam = Exam::updateOrCreate([
            'teacher_id' => $guru->id,
            'title'      => 'UH 1 — Aljabar Dasar',
        ], [
            'class_id'               => $kelas->id,
            'description'            => 'Ujian Harian 1 Matematika',
            'duration_minutes'       => 30,
            'total_questions'        => count($questionModels),
            'randomize_questions'    => true,
            'randomize_options'      => false,
            'show_result_immediately'=> true,
            'passing_grade'          => 70,
            'status'                 => 'draft',
            'max_violations'         => 5,
        ]);

        foreach ($questionModels as $i => $q) {
            ExamQuestion::updateOrCreate([
                'exam_id'     => $exam->id,
                'question_id' => $q->id,
            ], [
                'display_order' => $i + 1,
            ]);
        }

        // ── KELAS 2 (guru2) ──
        $kelas2 = ClassRoom::updateOrCreate([
            'teacher_id' => $guru2->id,
            'name'       => 'XI IPS 1',
        ], [
            'subject'       => 'Ekonomi',
            'academic_year' => '2024/2025',
            'semester'      => 'Ganjil',
        ]);

        foreach (array_slice($siswaList, 0, 5) as $siswa) {
            $kelas2->students()->syncWithoutDetaching([
                $siswa->id => [
                    'status'      => 'active',
                    'enrolled_at' => now(),
                    'enrolled_by' => $guru2->id,
                ],
            ]);
        }

        $this->command->info('✓ Database seeded successfully!');
        $this->command->info('  Admin  : admin@examcore.id / password123');
        $this->command->info('  Guru   : guru@examcore.id / password123');
        $this->command->info('  Siswa  : ahmadnaufal@siswa.id / password123');
    }
}

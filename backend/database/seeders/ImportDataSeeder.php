<?php
namespace Database\Seeders;

use App\Models\ClassRoom;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class ImportDataSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('Import data SMKN 1 PARIT TIGA...');

        // ── Semua PTK (63 org) dari file Excel ──
        // [no, nama, nip, nuptk, jenis, jabatan]
        $allPtk = [
            [1,  'Abdul Aziz',              '198907272023211011', '8059767668130303', 'Guru',                'Guru Bimbingan Konseling'],
            [2,  'Afriyanti',               '198511112010012021', '4443763664300073', 'Guru',                'Guru Matematika'],
            [3,  'Agus Herdian',            '197808112009031008', '2143756656200003', 'Guru',                'Guru Desain Komunikasi Visual'],
            [4,  'Ahmad Ferdiansyah',        '199905152024211005', '7847777678130012', 'Guru',                'Guru Teknik Ketenagalistrikan'],
            [5,  'Ahmad Yulizar',           '197907042009031003', '8036757659200053', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [6,  'Alyan Fathoni',           '198901232014031001', '3455767667120002', 'Guru',                'Guru Teknik Otomotif'],
            [7,  'Anak Agung Putu Budiartha','197810182009031001', '1350756658200043', 'Guru',                'Guru Desain Komunikasi Visual'],
            [8,  'Arbiani',                 '197801022006042016', '5434756657300002', 'Guru',                'Guru PPKN'],
            [9,  'Arjoni',                  '196907061999031003', '3038747649200003', 'Guru',                'Guru Matematika'],
            [10, 'Aryanto Leiwakabessy',    '198004112023211006', '0743758659130102', 'Guru',                'Guru Teknik Ketenagalistrikan'],
            [11, 'Bambang Agusfianto',      '198208082008041001', '2140760662120003', 'Kepala Sekolah',      'Kepala Sekolah'],
            [12, 'Bendi Lukman',            '198607062025211019', '1038764665130253', 'Tenaga Kependidikan', 'Laboran'],
            [13, 'Deni Darmanto',           '198111272009031001', '9459759661200033', 'Guru',                'Guru Teknik Otomotif'],
            [14, 'Dina Eka Widiastuti',     '198305012009032002', '0833761662300052', 'Guru',                'Guru Bahasa Inggris'],
            [15, 'Dini Fatiyah',            '199502162022212007', '1548773674130002', 'Guru',                'Guru TIK'],
            [16, 'Eko Robiyanto',           '',                   '4547765666130173', 'Tenaga Kependidikan', 'Laboran'],
            [17, 'Endang Asmara',           '',                   '6541747648230093', 'Tenaga Kependidikan', 'Pesuruh/Office Boy'],
            [18, 'Erni',                    '',                   '8660762663230152', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [19, 'Erniwati Zebua',          '',                   '4348762663230153', 'Guru',                'Guru Agama Kristen'],
            [20, 'FAIZAL AZIS',             '199505052024211014', '2837773674130272', 'Guru',                'Guru Teknik Jaringan Komputer Dan Telekomunikasi'],
            [21, 'Hendry Oktaria',          '198010252009031005', '9357758660200043', 'Guru',                'Guru Teknik Jaringan Komputer Dan Telekomunikasi'],
            [22, 'Ici Aftrini',             '198504122010012038', '1744763663300022', 'Guru',                'Guru Teknik Jaringan Komputer Dan Telekomunikasi'],
            [23, 'Indah Pratiwi',           '199709182024212029', '6250775676230013', 'Guru',                'Guru Agama Islam'],
            [24, 'IRHAM RUHULLAH',          '',                   '8841757658130112', 'Tenaga Kependidikan', 'Pesuruh/Office Boy'],
            [25, 'Juanda Noveri Sinaga',    '198308052014021001', '4137761663120003', 'Guru',                'Guru Desain Komunikasi Visual'],
            [26, 'KELVIN',                  '',                   '9138776677130023', 'Tenaga Kependidikan', 'Laboran'],
            [27, 'Kethy Inriani',           '199606122019022006', '5944774675130002', 'Guru',                'Guru Bahasa Indonesia'],
            [28, 'Lili Asrinawati',         '199202022023212021', '2534770671130042', 'Guru',                'Guru Bahasa Indonesia'],
            [29, 'Lis Setiawati',           '198307072009032002', '2039761663300103', 'Guru',                'Guru Bahasa Inggris'],
            [30, 'Lisa Dona',               '198106112009032007', '5943759661300052', 'Guru',                'Guru Kimia'],
            [31, 'Mardhiyyah Tsaqiilaa',    '',                   '9150774675230033', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [32, 'Marudiyanto',             '',                   '8458766667200003', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [33, 'MASFUDIN',                '',                   '',                 'Tenaga Kependidikan', 'Penjaga Sekolah'],
            [34, 'Maulida Sari Sinaga',     '198711082023212022', '6440765666130093', 'Guru',                'Guru Matematika'],
            [35, 'Mirfan Januar',           '',                   '',                 'Tenaga Kependidikan', 'Tukang Kebun'],
            [36, 'Mochamad Agung Saputra',  '199405162022211006', '6848772673130052', 'Guru',                'Guru Desain Komunikasi Visual'],
            [37, 'Muhammad Darma Aji',      '199605292024211006', '8861774675130012', 'Guru',                'Guru Teknik Jaringan Komputer Dan Telekomunikasi'],
            [38, 'Muhammad Radha Arrahman', '',                   '',                 'Guru',                'Guru Teknik Otomotif'],
            [39, 'Muhammad Ramadhan',       '198804192011011002', '2751766666120002', 'Guru',                'Guru Bimbingan Konseling'],
            [40, 'NAUFAL MUSTAFA',          '199504302024211010', '3762773674130032', 'Guru',                'Guru Desain Komunikasi Visual'],
            [41, 'Nur Anita',               '198608312022212012', '5163764666210053', 'Guru',                'Guru Sejarah'],
            [42, 'Nyoman Hetiriyani',       '',                   '8547759659300002', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [43, 'Ramadani',                '199411212024211007', '9453772673130113', 'Guru',                'Guru Penjasorkes'],
            [44, 'ROBY ANGGARA',            '',                   '9935778679130012', 'Guru',                'Guru Matematika'],
            [45, 'Romla Dewisari',          '199507162023212011', '7048773674130033', 'Guru',                'Guru Bahasa Indonesia'],
            [46, 'Romsan',                  '198705252023211005', '8857765666130372', 'Guru',                'Guru Agama Islam'],
            [47, 'Rossinta',                '',                   '4244770671130123', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [48, 'Rusniah',                 '',                   '8136760661230173', 'Tenaga Kependidikan', 'Pustakawan'],
            [49, 'Sari Rahayu',             '200007162024212008', '5048778679230013', 'Guru',                'Guru Agama Islam'],
            [50, 'Sarwani',                 '197704082006041002', '1740755656200002', 'Guru',                'Guru Penjasorkes'],
            [51, 'Sasmita Pratiwi',         '199501242024212021', '9456773674230072', 'Guru',                'Guru Desain Komunikasi Visual'],
            [52, 'Silpiyani',               '199701082022212007', '1440775676130012', 'Guru',                'Guru TIK'],
            [53, 'Suhardiansyah',           '199007252025211020', '8057768669130063', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [54, 'Suis Zelanda',            '',                   '1254767668130173', 'Tenaga Kependidikan', 'Laboran'],
            [55, 'Susandi',                 '',                   '6947776677130112', 'Guru',                'Guru Teknik Ketenagalistrikan'],
            [56, 'Sutarni',                 '198901092022212009', '1441767668230052', 'Guru',                'Guru Matematika'],
            [57, 'Syamsul Bahri',           '198611102022211011', '6442764665130143', 'Guru',                'Guru Teknik Jaringan Komputer Dan Telekomunikasi'],
            [58, 'TEKAT TRI WIYONO',        '',                   '4152776677130073', 'Tenaga Kependidikan', 'Laboran'],
            [59, 'Tri Wulandari',           '199404292023212026', '2761772673230002', 'Guru',                'Guru Bahasa Inggris'],
            [60, 'Tuti Wihiya',             '',                   '2749767668300022', 'Tenaga Kependidikan', 'Tenaga Administrasi Sekolah'],
            [61, 'Veria Riptohadi',         '198211032014031001', '2435760661130123', 'Guru',                'Guru Teknik Otomotif'],
            [62, 'Wiji Astuti',             '198510162010012026', '1348763664220003', 'Guru',                'Guru Teknik Jaringan Komputer Dan Telekomunikasi'],
            [63, 'Yuniarti',                '',                   '',                 'Guru',                'Guru Seni Budaya'],
        ];

        $teacherMap = [];
        $guruCount = 0;
        $tuCount = 0;

        foreach ($allPtk as [$no, $nama, $nip, $nuptk, $jenis, $jabatan]) {
            // Buat email: nama.lowercase + @smkn1parittiga.sch.id
            $emailBase = strtolower(str_replace([' ', ',', '.', "'"], '', $nama));
            $email = $emailBase . '@smkn1parittiga.sch.id';

            // Cek by email dulu, baru by nip
            $user = User::where('email', $email)->first();
            if (!$user && $nip) {
                $user = User::where('nip', $nip)->first();
            }
            if (!$user) {
                // Guru & tenaga kependidikan → role 'guru' (sistem cuma punya admin/guru/siswa)
                $user = User::create([
                    'name'     => $nama,
                    'email'    => $email,
                    'password' => Hash::make('password123'),
                    'role'     => 'guru',
                    'status'   => 'active',
                    'nip'      => $nip ?: null,
                ]);
                if ($jenis === 'Tenaga Kependidikan') {
                    $tuCount++;
                } else {
                    $guruCount++;
                }
                $this->command->info("  + {$jenis}: {$nama}");
            } else {
                $this->command->info("  ~ Exist: {$nama}");
            }
            $teacherMap[$nama] = $user;
        }

        // ── Rombongan Belajar ──
        $kelasList = [
            ['X DKV 1',   '10', 'Desain Komunikasi Visual',                  'Agus Herdian'],
            ['X DKV 2',   '10', 'Desain Komunikasi Visual',                  'Indah Pratiwi'],
            ['X TITL',    '10', 'Teknik Ketenagalistrikan',                   'Kethy Inriani'],
            ['X TKJ 1',   '10', 'Teknik Jaringan Komputer dan Telekomunikasi','Afriyanti'],
            ['X TKJ 2',   '10', 'Teknik Jaringan Komputer dan Telekomunikasi','Silpiyani'],
            ['X TKJ 3',   '10', 'Teknik Jaringan Komputer dan Telekomunikasi','FAIZAL AZIS'],
            ['X TSM 1',   '10', 'Teknik Otomotif',                           'Lili Asrinawati'],
            ['X TSM 2',   '10', 'Teknik Otomotif',                           'Alyan Fathoni'],
            ['XI DKV 1',  '11', 'Desain Komunikasi Visual',                  'Juanda Noveri Sinaga'],
            ['XI DKV 2',  '11', 'Desain Komunikasi Visual',                  'Anak Agung Putu Budiartha'],
            ['XI TITL',   '11', 'Teknik Instalasi Tenaga Listrik',            'Susandi'],
            ['XI TKJ 1',  '11', 'Teknik Komputer dan Jaringan',               'Ici Aftrini'],
            ['XI TKJ 2',  '11', 'Teknik Komputer dan Jaringan',               'Lis Setiawati'],
            ['XI TKJ 3',  '11', 'Teknik Komputer dan Jaringan',               'Romla Dewisari'],
            ['XI TSM 1',  '11', 'Teknik Sepeda Motor',                        'Arjoni'],
            ['XI TSM 2',  '11', 'Teknik Sepeda Motor',                        'Sarwani'],
            ['XII DKV 1', '12', 'Desain Komunikasi Visual',                   'Sutarni'],
            ['XII DKV 2', '12', 'Desain Komunikasi Visual',                   'Tri Wulandari'],
            ['XII TITL',  '12', 'Teknik Instalasi Tenaga Listrik',            'Ahmad Ferdiansyah'],
            ['XII TKJ 1', '12', 'Teknik Komputer dan Jaringan',               'Maulida Sari Sinaga'],
            ['XII TKJ 2', '12', 'Teknik Komputer dan Jaringan',               'Nur Anita'],
            ['XII TKJ 3', '12', 'Teknik Komputer dan Jaringan',               'Sari Rahayu'],
            ['XII TSM 1', '12', 'Teknik Sepeda Motor',                        'Dini Fatiyah'],
            ['XII TSM 2', '12', 'Teknik Sepeda Motor',                        'ROBY ANGGARA'],
        ];

        // Hapus kelas dummy lama
        ClassRoom::whereIn('name', ['X IPA 1', 'XI IPS 1', 'MM 1', 'MM 2'])->delete();

        $academicYear = '2025/2026';
        $semester     = 'Ganjil';

        $kelasCount = 0;
        foreach ($kelasList as [$name, $level, $subject, $waliNama]) {
            $teacher = $teacherMap[$waliNama] ?? null;
            if (!$teacher) {
                $this->command->warn("  ! Guru '{$waliNama}' not found, skipping {$name}");
                continue;
            }

            ClassRoom::updateOrCreate(
                ['teacher_id' => $teacher->id, 'name' => $name],
                [
                    'subject'       => $subject,
                    'level'         => $level,
                    'academic_year' => $academicYear,
                    'semester'      => $semester,
                    'description'   => "Kelas {$name} - {$subject}",
                ]
            );
            $kelasCount++;
        }

        $this->command->info('');
        $this->command->info('✓ Import selesai!');
        $this->command->info("  Guru: {$guruCount} baru + exist, Tenaga Kependidikan: {$tuCount}");
        $this->command->info("  Total kelas: {$kelasCount}");
        $this->command->info('  Password default: password123');
    }
}

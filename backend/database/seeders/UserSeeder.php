<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $gurus = [
            ['Budi Santoso', 'budi.santoso@guru.id', '198901012010011001'],
            ['Siti Rahayu', 'siti.rahayu@guru.id', '198902052012012002'],
            ['Rian Prasetyo', 'rian.prasetyo@guru.id', '198903151995031003'],
        ];

        foreach ($gurus as [$name, $email, $nip]) {
            $user = User::where('email', $email)
                ->orWhere('nip', $nip)
                ->first();

            if (! $user) {
                $user = new User();
            }

            $user->name     = $name;
            $user->email    = $email;
            $user->password = Hash::make('password123');
            $user->role     = 'guru';
            $user->status   = 'active';
            $user->nip      = $nip;
            $user->save();
        }

        $siswas = [
            ['Ahmad Naufal', 'ahmadnaufal@siswa.id', '2024001'],
            ['Siti Fatimah', 'sitifatimah@siswa.id', '2024002'],
            ['Dita Kusuma', 'ditakusuma@siswa.id', '2024003'],
            ['Rizal Pratama', 'rizalpratama@siswa.id', '2024004'],
            ['Eka Putri', 'ekaputri@siswa.id', '2024005'],
            ['Fajar Nugroho', 'fajarnugroho@siswa.id', '2024006'],
            ['Gita Andriani', 'gitaandriani@siswa.id', '2024007'],
            ['Hendra Wijaya', 'hendrawijaya@siswa.id', '2024008'],
            ['Indah Lestari', 'indahlestari@siswa.id', '2024009'],
            ['Budi Saputra', 'budisaputra@siswa.id', '2024010'],
        ];

        foreach ($siswas as [$name, $email, $nis]) {
            $user = User::where('email', $email)
                ->orWhere('nis', $nis)
                ->first();

            if (! $user) {
                $user = new User();
            }

            $user->name     = $name;
            $user->email    = $email;
            $user->password = Hash::make('password123');
            $user->role     = 'siswa';
            $user->status   = 'active';
            $user->nis      = $nis;
            $user->save();
        }
    }
}

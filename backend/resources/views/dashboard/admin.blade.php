@extends('layouts.app')
@section('title', 'Dashboard Admin')
@section('page-title', 'Dashboard Admin')
@section('content')
<div class="stats-row stats-row-3 mb-6">
  <div class="stat-card orange">
    <div class="sc-header"><span class="sc-label">TOTAL USER</span><span class="sc-status active">AKTIF</span></div>
    <div class="sc-value">{{ number_format($totalUsers) }}</div>
    <div class="sc-change"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/></svg>{{ $totalSiswa }} siswa &bull; {{ $totalGuru }} guru</div>
  </div>
  <div class="stat-card navy">
    <div class="sc-header"><span class="sc-label">UJIAN AKTIF</span><span class="sc-status warn">BERJALAN</span></div>
    <div class="sc-value">{{ $activeExams }}</div>
    <div class="sc-change"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/></svg>{{ $submissionsToday }} dikumpulkan hari ini</div>
  </div>
  <div class="stat-card green">
    <div class="sc-header"><span class="sc-label">PELANGGARAN</span><span class="sc-status {{ $openViolations > 0 ? 'danger' : 'active' }}">{{ $openViolations > 0 ? 'TERBUKA' : 'BERSIH' }}</span></div>
    <div class="sc-value">{{ $openViolations }}</div>
    <div class="sc-change"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/></svg>perlu perhatian</div>
  </div>
</div>

<div class="grid-main mb-6">
  <div class="card">
    <div class="card-head">
      <div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>Aksi Cepat</div>
    </div>
    <div class="card-body" style="display:flex;flex-direction:column;gap:7px">
      <a href="{{ route('admin.users') }}" class="btn btn-ghost" style="justify-content:flex-start;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg>
        Manajemen User
      </a>
      <a href="{{ route('admin.classes') }}" class="btn btn-ghost" style="justify-content:flex-start;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
        Manajemen Kelas
      </a>
      <a href="{{ route('admin.exams') }}" class="btn btn-ghost" style="justify-content:flex-start;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/></svg>
        Semua Ujian
      </a>
      <a href="{{ route('admin.violations') }}" class="btn btn-ghost" style="justify-content:flex-start;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/></svg>
        Pelanggaran ({{ $openViolations }} terbuka)
      </a>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-head">
    <div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/></svg>Manajemen Ujian</div>
    <a href="{{ route('admin.exams') }}" class="btn btn-sm btn-ghost">Lihat Semua</a>
  </div>
  <div class="table-wrap">
    <table>
      <thead><tr><th>Judul</th><th>Guru</th><th>Kelas</th><th>Jadwal</th><th>Status</th><th>Durasi</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @forelse($exams as $exam)
        <tr>
          <td class="td-main">{{ $exam->title }}</td>
          <td>{{ $exam->teacher?->name }}</td>
          <td>{{ $exam->classRoom?->name }}</td>
          <td class="td-sm" style="white-space:nowrap">
            @if($exam->start_time)
              {{ \Carbon\Carbon::parse($exam->start_time)->locale('id')->isoFormat('dddd, DD/MM/YYYY • HH:mm') }}
            @else
              <span style="color:var(--ink3)">—</span>
            @endif
          </td>
          <td class="td-sm">
            @php
              $badge = match($exam->status) {
                'active'    => 'badge badge-success',
                'draft'     => 'badge badge-warning',
                'ended'     => 'badge badge-secondary',
                'paused'    => 'badge badge-info',
                'scheduled' => 'badge badge-primary',
                default     => 'badge',
              };
              $label = match($exam->status) {
                'active'    => 'Aktif',
                'draft'     => 'Draft',
                'ended'     => 'Selesai',
                'paused'    => 'Jeda',
                'scheduled' => 'Terjadwal',
                default     => $exam->status,
              };
            @endphp
            <span class="{{ $badge }}">{{ $label }}</span>
          </td>
          <td class="td-sm">{{ $exam->duration_minutes }} mnt</td>
          <td class="right" style="display:flex;gap:4px;justify-content:flex-end;flex-wrap:nowrap">
            @if(in_array($exam->status, ['draft','scheduled']))
            <form method="POST" action="{{ route('admin.exams.activate', $exam) }}" class="inline">
              @csrf @method('PATCH')
              <button class="btn btn-sm btn-primary">Aktifkan</button>
            </form>
            @endif
            @if($exam->status === 'active')
            <form method="POST" action="{{ route('admin.exams.end', $exam) }}" class="inline">
              @csrf @method('PATCH')
              <button class="btn btn-sm btn-danger">Akhiri</button>
            </form>
            @endif
            <form method="POST" action="{{ route('admin.exams.delete', $exam) }}" class="inline">
              @csrf @method('DELETE')
              <button class="btn btn-sm btn-outline-danger" onclick="return confirm('Hapus {{ $exam->title }}?')">Hapus</button>
            </form>
          </td>
        </tr>
        @empty
        <tr><td colspan="7" style="text-align:center;padding:24px;color:var(--ink3)">Belum ada ujian</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
</div>
@endsection

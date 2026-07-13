@extends('layouts.app')
@section('title', 'Dashboard Guru')
@section('page-title', 'Dashboard Guru')
@section('content')
<div class="stats-row stats-row-3 mb-6">
  <div class="stat-card orange">
    <div class="sc-header"><span class="sc-label">TOTAL UJIAN</span><span class="sc-status warn">BERJALAN</span></div>
    <div class="sc-value">{{ $totalExams }}</div>
    <div class="sc-change"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/></svg>{{ $activeExams }} aktif sekarang</div>
  </div>
  <div class="stat-card navy">
    <div class="sc-header"><span class="sc-label">TOTAL SOAL</span><span class="sc-status info">TERSIMPAN</span></div>
    <div class="sc-value">{{ $totalQuestions }}</div>
    <div class="sc-change">Semua soal di bank soal</div>
  </div>
  <div class="stat-card green">
    <div class="sc-header"><span class="sc-label">TOTAL SISWA</span><span class="sc-status active">AKTIF</span></div>
    <div class="sc-value">{{ $totalStudents }}</div>
    <div class="sc-change"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/></svg>{{ $totalClasses }} kelas</div>
  </div>
</div>

<div class="grid-main mb-6">
  <div class="card">
    <div class="card-head">
      <div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>Ujian Terbaru</div>
    </div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Ujian</th><th>Kelas</th><th>Status</th></tr></thead>
        <tbody>
          @forelse($recentExams as $exam)
          <tr>
            <td class="td-main">{{ $exam->title }}</td>
            <td class="td-sm">{{ $exam->classRoom?->name ?? '-' }}</td>
            <td><span class="badge @switch($exam->status) @case('active') b-green @case('scheduled') b-amber @case('paused') b-orange @case('ended') b-navy @default b-gray @endswitch">{{ $exam->status }}</span></td>
          </tr>
          @empty
          <tr><td colspan="3" style="text-align:center;padding:24px;color:var(--ink3)">Belum ada ujian</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
  </div>

  <div class="card">
    <div class="card-head">
      <div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>Aksi Cepat</div>
    </div>
    <div class="card-body" style="display:flex;flex-direction:column;gap:7px">
      <a href="{{ route('guru.questions') }}" class="btn btn-ghost" style="justify-content:flex-start;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
        Input Soal
      </a>
      <a href="{{ route('guru.exams') }}" class="btn btn-ghost" style="justify-content:flex-start;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/></svg>
        Jadwal Ujian
      </a>
      <a href="{{ route('guru.grade-reports') }}" class="btn btn-ghost" style="justify-content:flex-start;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/></svg>
        Rekap Nilai
      </a>
    </div>
  </div>
</div>

<div class="stats-row stats-row-3 mb-6" style="grid-template-columns:repeat(4,1fr)">
  <div class="stat-card sky"><div class="sc-header"><span class="sc-label">KELAS</span><span class="sc-status info">TOTAL</span></div><div class="sc-value">{{ $totalClasses }}</div></div>
  <div class="stat-card amber"><div class="sc-header"><span class="sc-label">SESI UJIAN</span><span class="sc-status warn">TOTAL</span></div><div class="sc-value">{{ $examSessions }}</div></div>
</div>
@endsection

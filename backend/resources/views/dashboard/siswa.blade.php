@extends('layouts.app')
@section('title', 'Dashboard Siswa')
@section('page-title', 'Dashboard Siswa')
@section('content')
<div class="stats-row stats-row-3 mb-6">
  <div class="stat-card navy">
    <div class="sc-header"><span class="sc-label">UJIAN TERSEDIA</span><span class="sc-status info">SIAP</span></div>
    <div class="sc-value">{{ $availableExams }}</div>
  </div>
  <div class="stat-card green">
    <div class="sc-header"><span class="sc-label">SELESAI</span><span class="sc-status active">{{ $totalPassed }} LULUS</span></div>
    <div class="sc-value">{{ $totalDone }}</div>
  </div>
  <div class="stat-card orange">
    <div class="sc-header"><span class="sc-label">RATA-RATA NILAI</span><span class="sc-status warn">RATA-RATA</span></div>
    <div class="sc-value">{{ $avgScore ? number_format($avgScore, 1) : '-' }}</div>
  </div>
</div>

<div class="card mb-6">
  <div class="card-head">
    <div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>Riwayat Ujian</div>
    <a href="{{ route('siswa.history') }}" class="card-action">Lihat Semua &rarr;</a>
  </div>
  <div class="table-wrap">
    <table>
      <thead><tr><th>Ujian</th><th>Nilai</th><th>Status</th><th>Tanggal</th></tr></thead>
      <tbody>
        @forelse($history as $item)
        <tr>
          <td class="td-main">{{ $item->exam?->title ?? '-' }}</td>
          <td><span style="font-weight:700;color:{{ $item->is_passed ? 'var(--green)' : 'var(--red)' }}">{{ $item->score !== null ? number_format($item->score, 1) : '-' }}</span></td>
          <td><span class="badge {{ $item->is_passed ? 'b-green' : 'b-gray' }}">{{ $item->is_passed ? 'Lulus' : 'Tidak' }}</span></td>
          <td class="td-sm">{{ $item->submitted_at ? $item->submitted_at->format('d/m/Y H:i') : '-' }}</td>
        </tr>
        @empty
        <tr><td colspan="4" style="text-align:center;padding:24px;color:var(--ink3)">Belum ada riwayat</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
</div>

<div style="text-align:center">
  <a href="{{ route('siswa.exams') }}" class="btn btn-primary" style="padding:12px 32px;font-size:15px">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"/></svg>
    Mulai Ujian
  </a>
</div>
@endsection

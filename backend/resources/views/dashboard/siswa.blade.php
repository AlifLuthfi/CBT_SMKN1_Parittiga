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
    <div class="sc-value">{{ $avgScore !== null ? number_format($avgScore, 1) : '-' }}</div>
  </div>
</div>

<div class="card mb-6">
  <div class="card-head">
    <div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>Riwayat Ujian</div>
    <a href="{{ route('siswa.history') }}" class="card-action">Lihat Semua &rarr;</a>
  </div>
  <div class="table-wrap">
    <table>
      <thead><tr><th>Ujian</th><th>Nilai</th><th>Status</th><th>Tanggal</th><th class="right">Detail</th></tr></thead>
      <tbody>
        @forelse($history as $item)
        @php
          $scoreColor   = $item->is_passed ? 'var(--green)' : 'var(--red)';
          $passedText   = $item->is_passed ? 'Lulus' : 'Tidak Lulus';
          $badgeClass   = $item->is_passed ? 'b-green' : 'b-gray';
          $submittedAt  = $item->submitted_at ? $item->submitted_at->locale('id')->isoFormat('dddd, DD/MM/YYYY • HH:mm') : '-';
        @endphp
        <tr>
          <td class="td-main">{{ $item->exam?->title ?? '-' }}</td>
          <td><span style="font-weight:700;color:{{ $scoreColor }}">{{ $item->score !== null ? number_format($item->score, 1) : '-' }}</span></td>
          <td>
            @if($item->status === 'timeout')
              <span class="badge b-orange">Waktu Habis</span>
            @else
              <span class="badge {{ $badgeClass }}">{{ $passedText }}</span>
            @endif
          </td>
          <td class="td-sm" style="white-space:nowrap">{{ $submittedAt }}</td>
          <td class="right">
            @if($item->score !== null)
            <a href="{{ route('siswa.exams.result', $item->id) }}" class="btn btn-sm btn-ghost">Lihat</a>
            @else
            <span style="color:var(--ink3);font-size:12px">—</span>
            @endif
          </td>
        </tr>
        @empty
        <tr><td colspan="5" style="text-align:center;padding:24px;color:var(--ink3)">
          <p style="margin-bottom:12px">Belum ada riwayat ujian</p>
          <a href="{{ route('siswa.exams') }}" class="btn btn-sm btn-primary">Lihat Ujian Tersedia</a>
        </td></tr>
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

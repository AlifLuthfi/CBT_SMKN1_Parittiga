@extends('layouts.app')
@section('title', 'Rekap Nilai')
@section('page-title', 'Rekap Nilai')
@section('content')
<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Siswa</th><th>Kelas</th><th>Semester</th><th>Rata-rata</th><th>Tertinggi</th><th>Terendah</th><th>Kelulusan</th></tr></thead>
      <tbody>
        @forelse($reports as $r)
        <tr>
          <td class="td-main">{{ $r->student?->name }}</td>
          <td>{{ $r->classRoom?->name }}</td>
          <td class="td-sm">{{ $r->academic_year }} {{ $r->semester }}</td>
          <td style="font-weight:700;color:var(--navy)">{{ number_format($r->average_score, 1) }}</td>
          <td class="td-sm">{{ number_format($r->highest_score, 1) }}</td>
          <td class="td-sm">{{ number_format($r->lowest_score, 1) }}</td>
          <td><span class="badge {{ $r->pass_rate >= 70 ? 'b-green' : 'b-orange' }}">{{ number_format($r->pass_rate, 1) }}%</span></td>
        </tr>
        @empty
        <tr><td colspan="7" style="text-align:center;padding:24px;color:var(--ink3)">Belum ada laporan</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $reports->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endSection

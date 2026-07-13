@extends('layouts.app')
@section('title', 'Laporan Kelas')
@section('page-title', 'Rekap Nilai: {{ $class->name }}')
@section('content')
<a href="{{ route('guru.grade-reports') }}" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--navy);text-decoration:none;margin-bottom:16px" onmouseover="this.style.textDecoration='underline'" onmouseout="this.style.textDecoration='none'">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali ke Laporan
</a>

<div class="grid-main mb-6">
  @foreach($exams as $exam)
  <div class="card">
    <div class="card-head">
      <div class="card-title">{{ $exam->title }}</div>
    </div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Siswa</th><th>Nilai</th><th>Status</th></tr></thead>
        <tbody>
          @foreach($students as $student)
          @php $session = $student->examSessions->where('exam_id', $exam->id)->first(); @endphp
          <tr>
            <td class="td-main">{{ $student->name }}</td>
            @if($session)
            <td style="font-weight:700;color:{{ $session->is_passed ? 'var(--green)' : 'var(--red)' }}">{{ $session->score !== null ? number_format($session->score, 1) : '-' }}</td>
            <td><span class="badge {{ $session->is_passed ? 'b-green' : 'b-gray' }}">{{ $session->is_passed ? 'Lulus' : 'Tidak' }}</span></td>
            @else
            <td class="td-sm">-</td>
            <td><span class="badge b-gray">Belum</span></td>
            @endif
          </tr>
          @endforeach
        </tbody>
      </table>
    </div>
  </div>
  @endforeach
</div>
@endSection

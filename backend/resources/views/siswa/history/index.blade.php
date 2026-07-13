@extends('layouts.app')
@section('title', 'Riwayat Ujian')
@section('page-title', 'Riwayat Ujian')
@section('content')
@php
$sessions = \App\Models\ExamSession::where('student_id', auth()->id())
    ->whereIn('status', ['submitted', 'timeout', 'force_submitted'])
    ->with('exam.classRoom')
    ->orderByDesc('submitted_at')
    ->paginate(20)
    ->through(function ($s) {
        $exam = $s->exam;
        return (object) [
            'id' => $s->id,
            'title' => $exam->title ?? '-',
            'class' => $exam->classRoom->name ?? '-',
            'submitted_at' => $s->submitted_at,
            'status' => $s->status,
            'score' => $s->score,
            'is_passed' => $s->is_passed,
        ];
    });
@endphp

@if($sessions->isEmpty())
<div style="text-align:center;padding:60px 20px">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:48px;height:48px;margin:0 auto 16px;color:var(--ink4)"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
  <h3 style="font-size:18px;color:var(--ink2);margin-bottom:4px">Belum ada riwayat</h3>
  <p style="font-size:13px;color:var(--ink3);margin-bottom:20px">Kerjakan ujian untuk melihat riwayat</p>
  <a href="{{ route('siswa.exams') }}" class="btn btn-primary">Lihat Ujian Tersedia</a>
</div>
@else
<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Ujian</th><th>Kelas</th><th>Nilai</th><th class="center">Status</th><th>Tanggal</th></tr></thead>
      <tbody>
        @foreach($sessions as $s)
        <tr>
          <td class="td-main">{{ $s->title }}</td>
          <td class="td-sm">{{ $s->class }}</td>
          <td style="font-weight:700;font-family:'JetBrains Mono',monospace;color:{{ $s->is_passed ? 'var(--green)' : 'var(--red)' }}">{{ $s->score !== null ? number_format($s->score, 1) : '-' }}</td>
          <td class="center"><span class="badge {{ $s->is_passed ? 'b-green' : 'b-gray' }}">{{ $s->is_passed ? 'Lulus' : 'Tidak Lulus' }}</span></td>
          <td class="td-sm">{{ $s->submitted_at ? \Carbon\Carbon::parse($s->submitted_at)->format('d/m/Y H:i') : '-' }}</td>
        </tr>
        @endforeach
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $sessions->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endif
@endSection
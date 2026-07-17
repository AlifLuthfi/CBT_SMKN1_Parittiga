@extends('layouts.app')
@section('title', 'Riwayat Ujian')
@section('page-title', 'Riwayat Ujian')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>

@if($sessions->isEmpty())
<div style="text-align:center;padding:60px 20px">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:48px;height:48px;margin:0 auto 16px;color:var(--ink4)"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
  <h3 style="font-size:18px;color:var(--ink2);margin-bottom:4px">Belum ada riwayat ujian</h3>
  <p style="font-size:13px;color:var(--ink3);margin-bottom:20px">Selesaikan ujian untuk melihat riwayat nilai</p>
  <a href="{{ route('siswa.exams') }}" class="btn btn-primary">Lihat Ujian Tersedia</a>
</div>
@else
<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Ujian</th><th>Kelas</th><th>Nilai</th><th>Benar</th><th>Salah</th><th>Kosong</th><th class="center">Status</th><th>Tanggal</th><th class="right">Detail</th></tr></thead>
      <tbody>
        @foreach($sessions as $s)
        @php
          $scoreColor = $s->is_passed ? 'var(--green)' : 'var(--red)';
          $passedText = $s->is_passed ? 'Lulus' : 'Tidak Lulus';
          $badgeClass = $s->is_passed ? 'b-green' : 'b-gray';
        @endphp
        <tr>
          <td class="td-main">{{ $s->title }}</td>
          <td class="td-sm">{{ $s->class }}</td>
          <td style="font-weight:700;font-family:'JetBrains Mono',monospace;color:{{ $scoreColor }}">{{ $s->score !== null ? number_format($s->score, 1) : '-' }}</td>
          <td style="color:var(--green);font-weight:600">{{ $s->correct }}</td>
          <td style="color:var(--red);font-weight:600">{{ $s->wrong }}</td>
          <td style="color:var(--amber);font-weight:600">{{ $s->unanswered }}</td>
          <td class="center">
            @if($s->status === 'timeout')
              <span class="badge b-orange">Waktu Habis</span>
            @else
              <span class="badge {{ $badgeClass }}">{{ $passedText }}</span>
            @endif
          </td>
          <td class="td-sm" style="white-space:nowrap">{{ $s->submitted_at ? \Carbon\Carbon::parse($s->submitted_at)->locale('id')->isoFormat('dddd, DD/MM/YYYY • HH:mm') : '-' }}</td>
          <td class="right">
            @if($s->score !== null)
            <a href="{{ route('siswa.exams.result', $s->id) }}" class="btn btn-sm btn-ghost">Lihat</a>
            @else
            <span style="color:var(--ink3);font-size:12px">—</span>
            @endif
          </td>
        </tr>
        @endforeach
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $sessions->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endif
@endSection

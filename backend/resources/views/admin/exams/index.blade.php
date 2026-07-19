@extends('layouts.app')
@section('title', 'Manajemen Ujian')
@section('page-title', 'Manajemen Ujian')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>
<div class="card">
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
                'active'    => 'b-green',
                'draft'     => 'b-amber',
                'ended'     => 'b-navy',
                'paused'    => 'b-orange',
                'scheduled' => 'b-sky',
                default     => 'b-gray',
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
            <span class="badge {{ $badge }}">{{ $label }}</span>
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
  <div class="pager">{{ $exams->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endSection

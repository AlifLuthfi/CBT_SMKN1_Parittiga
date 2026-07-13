@extends('layouts.app')
@section('title', 'Manajemen Ujian')
@section('page-title', 'Manajemen Ujian')
@section('content')
<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Judul</th><th>Guru</th><th>Kelas</th><th>Status</th><th>Durasi</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @forelse($exams as $exam)
        <tr>
          <td class="td-main">{{ $exam->title }}</td>
          <td>{{ $exam->teacher?->name }}</td>
          <td>{{ $exam->classRoom?->name }}</td>
          <td><span class="badge @switch($exam->status) @case('active') b-green @case('scheduled') b-amber @case('paused') b-orange @case('ended') b-navy @default b-gray @endswitch">{{ $exam->status }}</span></td>
          <td class="td-sm">{{ $exam->duration_minutes }} mnt</td>
          <td class="right">
            @if(in_array($exam->status, ['draft','scheduled']))
            <form method="POST" action="{{ route('admin.exams.activate', $exam) }}" class="inline">
              @csrf @method('PATCH')
              <button class="btn btn-sm btn-primary" onclick="return confirm('Aktifkan {{ $exam->title }}?')">Aktifkan</button>
            </form>
            @endif
            @if($exam->status === 'active')
            <form method="POST" action="{{ route('admin.exams.end', $exam) }}" class="inline">
              @csrf @method('PATCH')
              <button class="btn btn-sm btn-danger" onclick="return confirm('Akhiri {{ $exam->title }}? Semua sesi akan ditutup.')">Akhiri</button>
            </form>
            @endif
            <form method="POST" action="{{ route('admin.exams.delete', $exam) }}" class="inline">
              @csrf @method('DELETE')
              <button class="btn btn-sm btn-outline-danger" onclick="return confirm('Hapus {{ $exam->title }}?')">Hapus</button>
            </form>
          </td>
        </tr>
        @empty
        <tr><td colspan="6" style="text-align:center;padding:24px;color:var(--ink3)">Belum ada ujian</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $exams->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endSection

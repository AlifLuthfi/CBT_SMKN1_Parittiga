@extends('layouts.app')
@section('title', 'Pelanggaran')
@section('page-title', 'Log Pelanggaran')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>
<form method="GET" class="mb-4" style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">
  <label style="font-weight:600;font-size:14px;color:var(--ink2)">Filter Kelas:</label>
  <select name="class_id" class="form-input" style="max-width:260px" onchange="this.form.submit()">
    <option value="">Semua Kelas</option>
    @foreach($classes as $c)
    <option value="{{ $c->id }}" {{ request('class_id') == $c->id ? 'selected' : '' }}>{{ $c->name }}</option>
    @endforeach
  </select>
</form>
<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Siswa</th><th>Ujian</th><th>Kelas</th><th>Tipe</th><th>Jumlah</th><th>Waktu</th><th>Status</th></tr></thead>
      <tbody>
        @forelse($violations as $v)
        <tr>
          <td class="td-main">{{ $v->student?->name }}</td>
          <td>{{ $v->session?->exam?->title ?? '-' }}</td>
          <td><span class="badge b-navy">{{ $v->session?->exam?->classRoom?->name ?? '-' }}</span></td>
          <td><span class="badge b-amber">{{ str_replace('_', ' ', $v->violation_type) }}</span></td>
          <td style="font-family:'JetBrains Mono',monospace;font-weight:700;color:{{ $v->count >= 5 ? 'var(--red)' : ($v->count >= 3 ? 'var(--orange)' : 'var(--amber)') }}">{{ $v->count }}×</td>
          <td class="td-sm">{{ $v->created_at->format('d/m/Y H:i') }}</td>
          <td><span class="badge {{ $v->status === 'open' ? 'b-red' : 'b-sky' }}">{{ $v->status === 'open' ? 'TERBUKA' : 'SELESAI' }}</span></td>
        </tr>
        @empty
        <tr><td colspan="7" style="text-align:center;padding:24px;color:var(--ink3)">Belum ada pelanggaran</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $violations->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endSection

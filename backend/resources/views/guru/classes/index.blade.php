@extends('layouts.app')
@section('title', 'Manajemen Kelas')
@section('page-title', 'Kelas Saya')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>
@forelse($classes as $class)
<div class="card mb-4">
  <div class="card-head">
    <div class="card-title">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
      {{ $class->name }}
    </div>
    <span class="badge b-navy">{{ $class->subject }}</span>
  </div>
  <div class="card-body">
    <div style="display:flex;gap:16px;margin-bottom:12px;font-size:13px;color:var(--ink2)">
      <span><strong style="color:var(--ink)">{{ $class->students_count }}</strong> siswa</span>
      <span>{{ $class->academic_year }} {{ $class->semester }}</span>
    </div>
    @if($class->students->count() > 0)
    <div style="display:flex;flex-wrap:wrap;gap:4px">
      @foreach($class->students->where('pivot.status', 'active')->take(20) as $s)
      <span class="badge b-gray">{{ $s->name }}</span>
      @endforeach
      @if($class->students->count() > 20)
      <span class="badge b-navy">+{{ $class->students->count() - 20 }} lainnya</span>
      @endif
    </div>
    @else
    <div style="text-align:center;padding:20px;color:var(--ink3);font-size:13px">Belum ada siswa terdaftar</div>
    @endif
  </div>
</div>
@empty
<div style="text-align:center;padding:40px;color:var(--ink3)">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:40px;height:40px;margin:0 auto 12px;opacity:.3"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
  <p>Belum ada kelas</p>
</div>
@endforelse
@endSection

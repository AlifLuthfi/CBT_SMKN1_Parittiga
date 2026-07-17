@extends('layouts.app')
@section('title', 'Rekap Nilai')
@section('page-title', 'Rekap Nilai')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>
@if($classes->count() > 0)
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:14px">
  @foreach($classes as $class)
  <a href="{{ route('guru.grade-reports.class', $class) }}" style="text-decoration:none;color:inherit">
    <div class="card" style="cursor:pointer" onmouseover="this.style.boxShadow='0 6px 24px rgba(0,0,0,.1)';this.style.transform='translateY(-3px)'" onmouseout="this.style.boxShadow='';this.style.transform=''">
      <div class="card-body" style="padding:18px">
        <div style="width:42px;height:42px;border-radius:10px;background:var(--navy-light);display:grid;place-items:center;margin-bottom:12px">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--navy)" stroke-width="2" style="width:20px;height:20px"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
        </div>
        <div style="font-size:15px;font-weight:600;color:var(--ink);margin-bottom:2px">{{ $class->name }}</div>
        <div style="font-size:12px;color:var(--ink3);margin-bottom:10px">{{ $class->subject }}</div>
        <div style="display:flex;gap:12px;font-size:12px;color:var(--ink2)">
          <span style="display:flex;align-items:center;gap:4px">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:13px;height:13px"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
            {{ $class->students_count ?? $class->students->count() }} siswa
          </span>
          <span style="display:flex;align-items:center;gap:4px">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:13px;height:13px"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
            {{ $class->exams_count ?? $class->exams->count() ?? 0 }} ujian
          </span>
        </div>
      </div>
    </div>
  </a>
  @endforeach
</div>
@else
<div class="card">
  <div style="text-align:center;padding:40px;color:var(--ink3)">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:40px;height:40px;margin:0 auto 12px;opacity:.3"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
    <p>Belum ada kelas</p>
  </div>
</div>
@endif
@endSection

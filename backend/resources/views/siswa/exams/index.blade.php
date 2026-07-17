@extends('layouts.app')
@section('title', 'Ujian Tersedia')
@section('page-title', 'Ujian Tersedia')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>

@if($exams->isEmpty())
<div style="text-align:center;padding:60px 20px">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:48px;height:48px;margin:0 auto 16px;color:var(--ink4)"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
  <h3 style="font-size:18px;color:var(--ink2);margin-bottom:4px">Tidak ada ujian tersedia</h3>
  <p style="font-size:13px;color:var(--ink3)">Kamu belum terdaftar di kelas dengan ujian aktif</p>
</div>
@else
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:16px">
  @foreach($exams as $exam)
  <div class="card" style="display:flex;flex-direction:column">
    <div class="card-body" style="flex:1">
      <div style="display:flex;align-items:start;justify-content:space-between;margin-bottom:12px">
        <div>
          <h4 style="font-size:16px;font-weight:600;color:var(--ink)">{{ $exam->title }}</h4>
          <p style="font-size:12px;color:var(--ink3)">{{ $exam->subject ?? '-' }}</p>
        </div>
        <span class="badge b-green">Aktif</span>
      </div>
      <div style="display:flex;flex-direction:column;gap:8px;font-size:13px;color:var(--ink2);margin-bottom:16px">
        <div style="display:flex;align-items:center;gap:8px"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;color:var(--ink3)"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>{{ $exam->class_name }}</div>
        <div style="display:flex;align-items:center;gap:8px"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;color:var(--ink3)"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>{{ $exam->duration }} menit</div>
        <div style="display:flex;align-items:center;gap:8px"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;color:var(--ink3)"><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>{{ $exam->total_questions }} soal</div>
        @if($exam->start_time)
        <div style="display:flex;align-items:center;gap:8px"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;color:var(--ink3)"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>{{ \Carbon\Carbon::parse($exam->start_time)->locale('id')->isoFormat('dddd, DD/MM/YYYY • HH:mm') }}</div>
        @endif
        <div style="display:flex;align-items:center;gap:8px"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;color:var(--ink3)"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>Lulus &ge; {{ $exam->passing_grade }}</div>
      </div>
    </div>
    <div style="padding:0 18px 18px">
      @php $done = $exam->session_status && $exam->session_status !== 'in_progress'; @endphp
      @if($done)
      <a href="{{ route('siswa.exams.result', $exam->session_id) }}" class="btn btn-ghost" style="justify-content:center;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
        Lihat Hasil
      </a>
      @else
      <a href="{{ route('siswa.exams.start', $exam->id) }}" class="btn btn-primary" style="justify-content:center;width:100%">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"/></svg>
        {{ $exam->session_status === 'in_progress' ? 'Lanjutkan' : 'Mulai Ujian' }}
      </a>
      @endif
    </div>
  </div>
  @endforeach
</div>
@endif
@endSection

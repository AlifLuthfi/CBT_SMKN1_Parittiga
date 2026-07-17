@extends('layouts.bare')
@section('title', 'Hasil Ujian')
@section('content')
<a href="{{ route('siswa.history') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali ke Riwayat
</a>

<div class="card mb-4" style="text-align:center;padding:32px">
  @php $pass = ($result['is_passed'] ?? false); @endphp
  <div style="width:72px;height:72px;border-radius:50%;margin:0 auto 16px;display:grid;place-items:center;font-size:36px;background:{{ $pass ? 'var(--green-light)' : 'var(--red-light)' }};color:{{ $pass ? 'var(--green)' : 'var(--red)' }}">
    {{ $pass ? '✓' : '✕' }}
  </div>
  <h2 style="font-size:22px;margin-bottom:4px">{{ $pass ? 'Lulus!' : 'Tidak Lulus' }}</h2>
  <div style="font-size:52px;font-weight:700;font-family:'JetBrains Mono',monospace;color:{{ $pass ? 'var(--green)' : 'var(--red)' }};margin-bottom:4px">{{ number_format($result['score'] ?? 0, 1) }}</div>
  <p style="color:var(--ink3);font-size:14px;margin-bottom:24px">Minimal lulus: {{ number_format($result['passing_grade'] ?? 0, 1) }}</p>
</div>

<div class="card">
  <div class="card-body">
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;text-align:center">
      <div>
        <div style="font-size:24px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--ink)">{{ $result['total'] ?? 0 }}</div>
        <div style="font-size:12px;color:var(--ink3)">Total Soal</div>
      </div>
      <div>
        <div style="font-size:24px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--green)">{{ $result['correct'] ?? 0 }}</div>
        <div style="font-size:12px;color:var(--ink3)">Benar</div>
      </div>
      <div>
        <div style="font-size:24px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--red)">{{ $result['wrong'] ?? 0 }}</div>
        <div style="font-size:12px;color:var(--ink3)">Salah</div>
      </div>
      <div>
        <div style="font-size:24px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--amber)">{{ $result['unanswered'] ?? 0 }}</div>
        <div style="font-size:12px;color:var(--ink3)">Kosong</div>
      </div>
    </div>
  </div>
</div>

@if(!empty($result['wrong']) && $result['wrong'] > 0)
<div class="card mt-4">
  <div class="card-body">
    <h3 style="font-size:16px;font-weight:600;margin-bottom:16px">Pembahasan Soal (hanya yang salah)</h3>
    <div style="display:flex;flex-direction:column;gap:16px">
      @foreach($result['answers'] as $idx => $a)
      @php $isCorrect = ($a['is_correct'] ?? false); @endphp
      @if($isCorrect) @continue @endif
      <div style="padding:14px;border:1px solid var(--border);border-radius:8px;border-left:4px solid {{ empty($a['user_answer']) ? 'var(--amber)' : 'var(--red)' }}">
        <div style="display:flex;gap:10px;margin-bottom:10px">
          <span style="width:28px;height:28px;border-radius:6px;background:{{ empty($a['user_answer']) ? 'var(--amber-light)' : 'var(--red-light)' }};color:{{ empty($a['user_answer']) ? 'var(--amber)' : 'var(--red)' }};display:grid;place-items:center;font-size:13px;font-weight:700;flex-shrink:0">{{ $loop->index + 1 }}</span>
          <div>
            <p style="font-size:14px;color:var(--ink);line-height:1.6">{{ $a['question_text'] ?? '' }}</p>
            @if(!empty($a['image_url']))
            <img src="{{ $a['image_url'] }}" style="max-width:100%;border-radius:8px;margin-top:8px;max-height:150px" alt="Gambar">
            @endif
          </div>
        </div>
        <div style="margin-left:38px;font-size:13px">
          <div style="color:{{ empty($a['user_answer']) ? 'var(--ink3)' : 'var(--red)' }}">
            <strong>Jawabanmu:</strong>
            @if(!empty($a['user_answer']))
              {{ $a['user_answer'] }} (Salah)
            @else
              Tidak dijawab
            @endif
          </div>
          @if(!empty($a['explanation']))
          <div style="color:var(--ink3);margin-top:6px;padding:8px;background:var(--bg);border-radius:6px">
            <strong>Pembahasan:</strong> {{ $a['explanation'] }}
          </div>
          @endif
        </div>
      </div>
      @endforeach
    </div>
  </div>
</div>
@endif
@endSection

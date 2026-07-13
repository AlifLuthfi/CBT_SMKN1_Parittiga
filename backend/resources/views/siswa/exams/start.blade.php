@extends('layouts.app')
@section('title', 'Ujian')
@section('page-title', 'Ujian: ' . $exam->title)

@push('styles')
<style>
.exam-container{max-width:800px;margin:0 auto}
.question-card{display:none}.question-card.active{display:block}
.option-label{cursor:pointer;transition:all .15s}
.option-label:hover{border-color:var(--navy);background:var(--navy-light)}
.option-label.selected{border-color:var(--navy);background:var(--navy-light)}
.option-label.correct{border-color:var(--green);background:var(--green-light)}
.option-label.wrong{border-color:var(--red);background:var(--red-light)}
.nav-btn{width:36px;height:36px;border-radius:8px;border:1.5px solid var(--border);background:var(--surface);color:var(--ink2);cursor:pointer;font-family:'Inter',sans-serif;font-size:13px;font-weight:600;transition:all .15s}
.nav-btn:hover{background:var(--bg)}
.nav-btn.active{background:var(--navy);color:#fff;border-color:var(--navy)}
.nav-btn.answered{background:var(--green-light);color:var(--green);border-color:var(--green)}
</style>
@endpush

@section('content')
<div class="exam-container">
  {{-- Header --}}
  <div class="card mb-4">
    <div class="card-body" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px">
      <div>
        <h3 style="font-size:16px;font-weight:600">{{ $exam->title }}</h3>
        <p style="font-size:12px;color:var(--ink3)">{{ $exam->classRoom?->subject }} &middot; {{ $exam->classRoom?->name }}</p>
      </div>
      <div style="text-align:right">
        <div style="font-size:12px;color:var(--ink3)">Sisa Waktu</div>
        <div style="font-size:28px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--navy)" id="timer">
          {{ floor($remainingSeconds / 60) }}:{{ str_pad($remainingSeconds % 60, 2, '0', STR_PAD_LEFT) }}
        </div>
      </div>
    </div>
    {{-- Progress --}}
    <div style="padding:0 18px 14px">
      <div style="display:flex;justify-content:space-between;font-size:12px;color:var(--ink3);margin-bottom:6px">
        <span>Terjawab: <strong id="answeredCount">0</strong>/{{ count($questions) }}</span>
        <span>Soal <strong id="currentNum">1</strong>/{{ count($questions) }}</span>
      </div>
      <div style="height:6px;background:var(--bg);border-radius:3px;overflow:hidden">
        <div style="height:100%;background:var(--navy);border-radius:3px;transition:width .3s ease" id="progressBar" class="pr-fill"></div>
      </div>
    </div>
  </div>

  {{-- Questions --}}
  <form id="examForm">
    @csrf
    <input type="hidden" name="session_id" value="{{ $sessionId }}">

    @foreach($questions as $idx => $q)
    <div class="question-card card {{ $idx === 0 ? 'active' : '' }}" data-index="{{ $idx }}">
      <div class="card-body">
        <div style="display:flex;align-items:flex-start;gap:12px;margin-bottom:20px">
          <span style="width:32px;height:32px;border-radius:8px;background:var(--navy-light);color:var(--navy);display:grid;place-items:center;font-size:14px;font-weight:700;flex-shrink:0">{{ $idx + 1 }}</span>
          <div>
            <p style="font-size:14px;color:var(--ink);line-height:1.6">{{ $q['question_text'] }}</p>
            @if($q['image_url'])<img src="{{ $q['image_url'] }}" style="max-width:100%;border-radius:8px;margin-top:12px" alt="Gambar">@endif
          </div>
        </div>

        <div style="display:flex;flex-direction:column;gap:8px;padding-left:44px">
          @foreach($q['options'] ?? [] as $key => $val)
          <label class="option-label" style="display:flex;align-items:center;gap:10px;padding:12px 14px;border:1.5px solid var(--border);border-radius:8px" data-letter="{{ $key }}">
            <input type="radio" name="answer_{{ $q['id'] }}" value="{{ $key }}"
                   class="answer-input" data-qid="{{ $q['id'] }}" style="accent-color:var(--navy);width:16px;height:16px">
            <span style="width:28px;height:28px;border-radius:6px;background:var(--bg);color:var(--ink2);display:grid;place-items:center;font-size:13px;font-weight:600;flex-shrink:0">{{ $key }}</span>
            <span style="font-size:13px;color:var(--ink2)">{{ $val }}</span>
          </label>
          @endforeach
        </div>

        <div style="display:flex;align-items:center;justify-content:space-between;margin-top:24px;padding-top:16px;border-top:1px solid var(--border)">
          <button type="button" onclick="prevQuestion()" class="btn btn-ghost {{ $idx === 0 ? 'invisible' : '' }}">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
            Sebelumnya
          </button>
          @if($idx < count($questions) - 1)
          <button type="button" onclick="nextQuestion()" class="btn btn-primary">
            Selanjutnya <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="9 18 15 12 9 6"/></svg>
          </button>
          @else
          <button type="button" onclick="submitExam()" class="btn btn-primary" style="background:var(--green)">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:14px;height:14px"><polyline points="20 6 9 17 4 12"/></svg>
            Kumpulkan
          </button>
          @endif
        </div>
      </div>
    </div>
    @endforeach
  </form>

  {{-- Navigator --}}
  <div class="card mt-4">
    <div class="card-body">
      <p style="font-size:11px;color:var(--ink3);margin-bottom:8px">Navigasi Cepat:</p>
      <div style="display:flex;flex-wrap:wrap;gap:6px" id="questionNav">
        @foreach($questions as $idx => $q)
        <button type="button" onclick="goToQuestion({{ $idx }})" class="nav-btn {{ $idx === 0 ? 'active' : '' }}" data-index="{{ $idx }}">{{ $idx + 1 }}</button>
        @endforeach
      </div>
    </div>
    <div style="padding:0 18px 18px;text-align:center">
      <button type="button" onclick="submitExam()" class="btn btn-danger">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="20 6 9 17 4 12"/></svg>
        Kumpulkan Ujian
      </button>
    </div>
  </div>
</div>

@push('scripts')
<script>
const TOTAL_QS = {{ count($questions) }};
const SESSION_ID = '{{ $sessionId }}';
const CSRF = document.querySelector('meta[name="csrf-token"]')?.content;
let remainingSeconds = {{ $remainingSeconds }};
const savedAnswers = JSON.parse(localStorage.getItem('exam_answers_' + SESSION_ID) || '{}');

// Restore saved answers
document.querySelectorAll('.answer-input').forEach(input => {
  if (savedAnswers[input.dataset.qid] === input.value) {
    input.checked = true;
    input.closest('.option-label')?.classList.add('selected');
  }
});
updateProgress();

// Timer
const timerEl = document.getElementById('timer');
setInterval(() => {
  remainingSeconds--;
  const m = Math.floor(remainingSeconds / 60);
  const s = remainingSeconds % 60;
  timerEl.textContent = m + ':' + String(s).padStart(2, '0');
  if (remainingSeconds <= 300) timerEl.style.color = 'var(--amber)';
  if (remainingSeconds <= 60) timerEl.style.color = 'var(--red)';
  if (remainingSeconds <= 0) { alert('Waktu habis!'); window.location.href = '/siswa/exams'; }
}, 1000);

// Auto save
setInterval(saveAnswers, 15000);

document.querySelectorAll('.answer-input').forEach(input => {
  input.addEventListener('change', function() {
    savedAnswers[this.dataset.qid] = this.value;
    localStorage.setItem('exam_answers_' + SESSION_ID, JSON.stringify(savedAnswers));
    document.querySelectorAll('.option-label').forEach(l => l.classList.remove('selected'));
    document.querySelectorAll('.answer-input:checked').forEach(i => i.closest('.option-label')?.classList.add('selected'));
    updateProgress();
    saveAnswers();
  });
});

function goToQuestion(idx) {
  document.querySelectorAll('.question-card').forEach(c => c.classList.remove('active'));
  document.querySelector(`.question-card[data-index="${idx}"]`)?.classList.add('active');
  document.getElementById('currentNum').textContent = idx + 1;
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`.nav-btn[data-index="${idx}"]`)?.classList.add('active');
}
function nextQuestion() { const c = document.querySelector('.question-card.active'); if (c) goToQuestion(parseInt(c.dataset.index) + 1); }
function prevQuestion() { const c = document.querySelector('.question-card.active'); if (c) goToQuestion(parseInt(c.dataset.index) - 1); }

function updateProgress() {
  const answered = Object.keys(savedAnswers).length;
  document.getElementById('answeredCount').textContent = answered;
  document.getElementById('progressBar').style.width = (answered / TOTAL_QS * 100) + '%';
  document.querySelectorAll('.nav-btn').forEach(btn => {
    const idx = parseInt(btn.dataset.index);
    const q = document.querySelectorAll('.question-card')[idx];
    if (q?.querySelector('.answer-input:checked')) btn.classList.add('answered');
    else btn.classList.remove('answered');
  });
}

async function saveAnswers() {
  const answers = [];
  document.querySelectorAll('.answer-input:checked').forEach(input => answers.push({ question_id: input.dataset.qid, answer: input.value }));
  try {
    const token = localStorage.getItem('api_token');
    const headers = { 'Content-Type':'application/json', 'X-CSRF-TOKEN':CSRF };
    if (token) headers['Authorization'] = 'Bearer ' + token;
    await fetch('/api/siswa/sessions/' + SESSION_ID + '/answers', { method:'POST', headers, body: JSON.stringify({ answers }) });
  } catch(e) {}
}

async function submitExam() {
  if (!confirm('Yakin ingin mengumpulkan ujian?')) return;
  await saveAnswers();
  try {
    const headers = { 'Content-Type':'application/json', 'X-CSRF-TOKEN':CSRF, 'Accept':'application/json' };
    const token = localStorage.getItem('api_token');
    if (token) headers['Authorization'] = 'Bearer ' + token;
    const res = await fetch('/api/siswa/sessions/' + SESSION_ID + '/submit', { method:'POST', headers, body: '{}' });
    const data = await res.json();
    localStorage.removeItem('exam_answers_' + SESSION_ID);
    if (data.result) {
      showResult(data.result);
    } else {
      window.location.href = '/siswa/history';
    }
  } catch(e) {
    alert('Gagal mengumpulkan. Coba lagi.');
  }
}

function showResult(r) {
  const o = document.createElement('div');
  o.className = 'modal-overlay open';
  o.innerHTML = `<div class="modal" style="max-width:400px;text-align:center">
    <div class="modal-body" style="padding:32px">
      <div style="width:64px;height:64px;border-radius:50%;margin:0 auto 16px;display:grid;place-items:center;font-size:30px;background:${r.is_passed ? 'var(--green-light)' : 'var(--red-light)'};color:${r.is_passed ? 'var(--green)' : 'var(--red)'}">${r.is_passed ? '✓' : '✕'}</div>
      <h2 style="font-size:20px;margin-bottom:4px">${r.is_passed ? 'Lulus!' : 'Tidak Lulus'}</h2>
      <p style="color:var(--ink3);font-size:13px;margin-bottom:16px">Nilai kamu</p>
      <div style="font-size:48px;font-weight:700;font-family:'JetBrains Mono',monospace;color:${r.is_passed ? 'var(--green)' : 'var(--red)'};margin-bottom:4px">${(r.score||0).toFixed(1)}</div>
      <p style="color:var(--ink3);font-size:13px;margin-bottom:24px">Minimal lulus: ${(r.passing_grade||0).toFixed(1)}</p>
      <div style="display:flex;justify-content:center;gap:8px">
        <a href="/siswa/history" class="btn btn-primary">Riwayat</a>
        <a href="/siswa/exams" class="btn btn-ghost">Kembali</a>
      </div>
    </div>
  </div>`;
  document.body.appendChild(o);
}
</script>
@endpush
@endSection

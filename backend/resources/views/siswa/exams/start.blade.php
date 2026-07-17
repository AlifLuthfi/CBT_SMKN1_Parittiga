@extends('layouts.bare')
@section('title', 'Ujian: ' . $exam->title)

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
const MAX_VIOLATIONS = {{ $exam->max_violations ?? 5 }};
const TOTAL_SECONDS = {{ $remainingSeconds }};
const CSRF = document.querySelector('meta[name="csrf-token"]')?.content;

function getApiToken() { return localStorage.getItem('api_token'); }
function apiHeaders() {
  const h = {'Content-Type':'application/json','X-CSRF-TOKEN':CSRF,'Accept':'application/json'};
  const t = getApiToken(); if (t) h['Authorization'] = 'Bearer ' + t;
  return h;
}
function getStorageKey(s) { return 'exam_' + s + '_' + SESSION_ID; }

// ── Restore answers + wall-clock timer ──────────────────────
const savedAnswers = JSON.parse(localStorage.getItem(getStorageKey('answers')) || '{}');
let timeElapsed = parseInt(localStorage.getItem(getStorageKey('timeElapsed')), 10) || 0;
let timerStartedAt = Date.now();
let remainingSeconds = TOTAL_SECONDS - timeElapsed;
if (remainingSeconds <= 0 || remainingSeconds > TOTAL_SECONDS) { remainingSeconds = TOTAL_SECONDS; timeElapsed = 0; }

document.querySelectorAll('.answer-input').forEach(input => {
  if (savedAnswers[input.dataset.qid] === input.value) {
    input.checked = true; input.closest('.option-label')?.classList.add('selected');
  }
});
updateProgress();

// ── Violation ───────────────────────────────────────────────
let violationCount = parseInt(localStorage.getItem(getStorageKey('violations')), 10) || 0;
let violationMsgShowing = false;

async function recordViolation(type) {
  violationCount++;
  localStorage.setItem(getStorageKey('violations'), violationCount.toString());
  try {
    await fetch('/api/siswa/violations', { method:'POST', headers: apiHeaders(),
      body: JSON.stringify({ session_id: SESSION_ID, violation_type: type }) });
  } catch(e) {}
  if (violationCount >= MAX_VIOLATIONS) { submitExam(); return; }
  if (violationMsgShowing) return;
  violationMsgShowing = true;
  alert('⚠ Pelanggaran! (' + violationCount + '/' + MAX_VIOLATIONS + ')');
  setTimeout(() => { violationMsgShowing = false; }, 5000);
}

// ── Fullscreen: burst 50ms → 150ms ─────────────────────────
function enterFs() {
  const e = document.documentElement;
  if (e.requestFullscreen) e.requestFullscreen();
  else if (e.webkitRequestFullscreen) e.webkitRequestFullscreen();
  else if (e.msRequestFullscreen) e.msRequestFullscreen();
}
let fsViolated = false;
document.addEventListener('fullscreenchange', function() {
  if (!document.fullscreenElement && !document.webkitIsFullScreen) {
    if (!fsViolated) { fsViolated = true; recordViolation('fullscreen_exit'); }
    setTimeout(enterFs, 100);
  } else { fsViolated = false; }
});
let fc = 0;
const fsBurst = setInterval(function() {
  if (remainingSeconds <= 0) { clearInterval(fsBurst); return; }
  if (!document.fullscreenElement && !document.webkitIsFullScreen) enterFs();
  if (++fc >= 40) clearInterval(fsBurst);
}, 50);
setInterval(function() {
  if (remainingSeconds <= 0) return;
  if (!document.fullscreenElement && !document.webkitIsFullScreen) enterFs();
}, 150);

// ── Visibility / focus loss ───────────────────────────────
document.addEventListener('visibilitychange', function() { if (document.hidden) recordViolation('blur'); });
let blurCooldown = false;
window.addEventListener('blur', function() {
  if (!blurCooldown) { blurCooldown = true; recordViolation('tab_switch'); setTimeout(() => { blurCooldown = false; }, 5000); }
});
document.addEventListener('contextmenu', function(e) { e.preventDefault(); });
document.addEventListener('copy', function(e) { e.preventDefault(); });
document.addEventListener('paste', function(e) { e.preventDefault(); });
document.addEventListener('cut', function(e) { e.preventDefault(); });

window.addEventListener('beforeunload', function(e) { e.preventDefault(); e.returnValue = 'Ujian sedang berlangsung!'; });

// ── Keyboard block ─────────────────────────────────────────
document.addEventListener('keydown', function(e) {
  const c = e.ctrlKey || e.metaKey, a = e.altKey, s = e.shiftKey;
  if (e.key === 'F12' || (c && s && (e.key==='I'||e.key==='J'||e.key==='C')) ||
      (c && (e.key==='u'||e.key==='U'||e.key==='s'||e.key==='S')) ||
      e.key==='PrintScreen' || e.keyCode===44) { e.preventDefault(); recordViolation('devtools'); }
  if (a && (e.key==='Tab'||e.key==='F4'||e.key==='Escape')) { e.preventDefault(); recordViolation('tab_switch'); }
  if (e.key==='Meta'||e.key==='OS'||e.keyCode===91||e.keyCode===92) { e.preventDefault(); }
  if (c && e.key==='Escape') { e.preventDefault(); }
  if (e.key==='Escape') { e.preventDefault(); }
});
try { enterFs(); } catch(e) {}

// ── Timer (wall-clock based) ───────────────────────────────
const timerEl = document.getElementById('timer');
let timerInt;
function showTimer(s) {
  const m = Math.floor(s/60), sec = s%60;
  timerEl.textContent = m + ':' + String(sec).padStart(2,'0');
  timerEl.style.color = s<=60 ? 'var(--red)' : s<=300 ? 'var(--amber)' : 'var(--navy)';
}
showTimer(remainingSeconds);

function startTimer() {
  timerStartedAt = Date.now();
  timerInt = setInterval(function() {
    const wall = timeElapsed + Math.floor((Date.now()-timerStartedAt)/1000);
    remainingSeconds = TOTAL_SECONDS - wall;
    if (remainingSeconds <= 0) {
      remainingSeconds = 0; clearInterval(timerInt);
      localStorage.removeItem(getStorageKey('timeElapsed'));
      showTimer(0); submitExam(); return;
    }
    localStorage.setItem(getStorageKey('timeElapsed'), wall.toString());
    showTimer(remainingSeconds);
  }, 1000);
}
startTimer();

// ── Auto-save + bulk sync ─────────────────────────────────
let isBulkSync = false;
setInterval(async function() {
  if (isBulkSync) return; isBulkSync = true;
  try {
    const a = []; document.querySelectorAll('.answer-input:checked').forEach(i => a.push({question_id:i.dataset.qid,answer:i.value}));
    if (a.length) await fetch('/api/siswa/sessions/'+SESSION_ID+'/answers',{method:'POST',headers:apiHeaders(),body:JSON.stringify({answers:a})});
  } catch(e) {} isBulkSync = false;
}, 60000);

document.querySelectorAll('.answer-input').forEach(input => {
  input.addEventListener('change', function() {
    savedAnswers[this.dataset.qid] = this.value;
    localStorage.setItem(getStorageKey('answers'), JSON.stringify(savedAnswers));
    document.querySelectorAll('.option-label').forEach(l => l.classList.remove('selected'));
    document.querySelectorAll('.answer-input:checked').forEach(i => i.closest('.option-label')?.classList.add('selected'));
    updateProgress();
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
    await fetch('/api/siswa/sessions/' + SESSION_ID + '/answers', { method:'POST', headers: apiHeaders(), body: JSON.stringify({ answers }) });
  } catch(e) {}
}

async function submitExam() {
  if (!confirm('Yakin ingin mengumpulkan ujian?')) return;
  await saveAnswers();
  try {
    const res = await fetch('/api/siswa/sessions/' + SESSION_ID + '/submit', { method:'POST', headers: apiHeaders(), body: '{}' });
    const data = await res.json();
    localStorage.removeItem(getStorageKey('answers'));
    localStorage.removeItem(getStorageKey('timeElapsed'));
    localStorage.removeItem(getStorageKey('violations'));
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
  o.innerHTML = `<div class="modal" style="max-width:410px;text-align:center">
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
  clearInterval(timerInt);
}
</script>
@endpush
@endSection

@extends('layouts.app')
@section('title', 'Import Soal')
@section('page-title', 'Import Soal')
@section('content')
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="page-sub" style="margin:0">Upload file Excel/CSV untuk import soal massal</div>
  <a href="{{ route('guru.questions') }}" class="btn btn-ghost">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
    Kembali
  </a>
</div>

<div class="grid-main" style="grid-template-columns:1fr 300px">
  {{-- LEFT: Upload + Preview --}}
  <div>
    {{-- Dropzone --}}
    <div class="card mb-4">
      <div class="card-head"><div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>Upload File Excel/CSV</div></div>
      <div class="card-body">
        <div class="dropzone" id="dropzone" onclick="document.getElementById('file-input').click()" style="border:2.5px dashed var(--border2);border-radius:12px;padding:48px 32px;text-align:center;cursor:pointer;transition:all .2s;background:var(--surface)">
          <div style="width:56px;height:56px;border-radius:14px;background:var(--navy-light);display:grid;place-items:center;margin:0 auto 16px">
            <svg viewBox="0 0 24 24" fill="none" stroke="var(--navy)" stroke-width="2" style="width:28px;height:28px"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
          </div>
          <div style="font-size:15px;font-weight:600;color:var(--ink);margin-bottom:5px">Seret file ke sini atau klik untuk pilih</div>
          <div style="font-size:13px;color:var(--ink3)">.xlsx, .xls, .csv — Maks 10 MB</div>
          <div style="display:flex;gap:8px;justify-content:center;margin-top:14px">
            <span style="padding:3px 12px;border-radius:20px;font-size:11px;font-weight:600;background:var(--bg);color:var(--ink3)">XLSX</span>
            <span style="padding:3px 12px;border-radius:20px;font-size:11px;font-weight:600;background:var(--bg);color:var(--ink3)">CSV</span>
          </div>
        </div>
        <input type="file" id="file-input" accept=".xlsx,.xls,.csv" onchange="handleFile(this.files[0])" style="display:none">

        <div id="file-info" style="display:none;margin-top:12px;padding:12px;background:var(--green-light);border-radius:8px">
          <div style="display:flex;align-items:center;gap:8px">
            <span style="font-size:16px">📄</span>
            <span style="flex:1;font-size:13px;font-weight:600;color:var(--green)" id="file-name"></span>
            <button class="icon-btn" onclick="resetFile()" style="width:24px;height:24px">✕</button>
          </div>
        </div>
      </div>
    </div>

    {{-- Preview --}}
    <div class="card" id="card-preview" style="display:none">
      <div class="card-head">
        <div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>Preview Soal</div>
        <div style="display:flex;gap:8px;align-items:center">
          <select id="filter-preview" onchange="renderPreview()" style="font-size:12px;padding:5px 10px;border-radius:6px;border:1px solid var(--border2);font-family:'Inter',sans-serif;background:var(--surface)">
            <option value="all">Semua</option>
            <option value="ok">Valid</option>
            <option value="error">Error</option>
          </select>
        </div>
      </div>

      {{-- Summary --}}
      <div id="summary-bar" style="display:none;padding:14px 18px;border-bottom:1px solid var(--border);background:var(--bg)">
        <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px">
          <div style="text-align:center;padding:10px;background:var(--surface);border-radius:8px">
            <div style="font-size:22px;font-weight:700;font-family:'JetBrains Mono',monospace" id="s-total">0</div>
            <div style="font-size:10.5px;color:var(--ink3)">Total Baris</div>
          </div>
          <div style="text-align:center;padding:10px;background:var(--surface);border-radius:8px">
            <div style="font-size:22px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--green)" id="s-ok">0</div>
            <div style="font-size:10.5px;color:var(--ink3)">Valid</div>
          </div>
          <div style="text-align:center;padding:10px;background:var(--surface);border-radius:8px">
            <div style="font-size:22px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--red)" id="s-err">0</div>
            <div style="font-size:10.5px;color:var(--ink3)">Error</div>
          </div>
          <div style="text-align:center;padding:10px;background:var(--surface);border-radius:8px">
            <div style="font-size:22px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--navy)" id="s-preview">0</div>
            <div style="font-size:10.5px;color:var(--ink3)">Ditampilkan</div>
          </div>
        </div>
      </div>

      {{-- Preview table --}}
      <div class="table-wrap">
        <table>
          <thead><tr><th>#</th><th>Pertanyaan</th><th>Opsi</th><th>Kunci</th><th>Sulit</th><th>Status</th></tr></thead>
          <tbody id="tbody-preview"></tbody>
        </table>
      </div>

      {{-- Footer --}}
      <div id="preview-footer" style="display:none;padding:14px 18px;border-top:1px solid var(--border);justify-content:space-between;align-items:center;background:#f7f9fc">
        <div style="font-size:12.5px;color:var(--ink3)">Soal error tidak akan diimpor</div>
        <button class="btn btn-primary" id="btn-import" onclick="executeImport()" disabled>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          Import Soal
        </button>
      </div>
    </div>
  </div>

  {{-- RIGHT: Settings --}}
  <div>
    <div class="card mb-4">
      <div class="card-head"><div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>Pengaturan</div></div>
      <div class="card-body">
        <div class="form-group">
          <label class="form-label">Mata Pelajaran</label>
          <select id="import-subject" class="form-input">
            <option value="">— Pilih mapel —</option>
            @foreach($subjects as $s)
            <option value="{{ $s->id }}">{{ $s->name }}</option>
            @endforeach
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Kategori Default</label>
          <select id="import-category" class="form-input">
            <option value="">— Tidak ada —</option>
            @foreach($categories as $c)
            <option value="{{ $c->id }}">{{ $c->name }}</option>
            @endforeach
          </select>
        </div>
      </div>
    </div>

    {{-- Template download --}}
    <div class="card">
      <div class="card-head"><div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>Template</div></div>
      <div class="card-body">
        <div style="font-size:12.5px;color:var(--ink2);margin-bottom:12px">Download template untuk format yang benar:</div>
        <a href="{{ asset('api/guru/question-imports/template') }}" class="btn btn-ghost w-full" style="justify-content:center;margin-bottom:8px">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          Download Template CSV
        </a>
        <div style="font-size:11px;color:var(--ink3);line-height:1.7">
          <strong>Kolom:</strong> question_text, option_a, option_b, option_c, option_d, option_e, correct_answer, difficulty, weight, explanation, category, tags
        </div>
      </div>
    </div>

    {{-- Result card --}}
    <div class="card mt-4" id="card-result" style="display:none">
      <div class="card-head"><div class="card-title" id="result-title">Hasil Import</div></div>
      <div class="card-body" id="result-body"></div>
    </div>

    {{-- History --}}
    <div class="card mt-4">
      <div class="card-head"><div class="card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>Riwayat Import</div></div>
      <div id="history-list" style="padding:10px 14px">
        <div class="sk" style="height:50px;margin-bottom:8px;border-radius:8px"></div>
        <div class="sk" style="height:50px;margin-bottom:8px;border-radius:8px"></div>
        <div class="sk" style="height:50px;border-radius:8px"></div>
      </div>
    </div>
  </div>
</div>

@push('scripts')
<script>
let currentFile = null;
let previewData = null;

document.addEventListener('DOMContentLoaded', () => {
  loadHistory();

  const dz = document.getElementById('dropzone');
  dz.addEventListener('dragover', e => { e.preventDefault(); dz.style.borderColor = 'var(--navy)'; dz.style.background = 'var(--navy-light)'; });
  dz.addEventListener('dragleave', () => { dz.style.borderColor = ''; dz.style.background = ''; });
  dz.addEventListener('drop', e => { e.preventDefault(); dz.style.borderColor = ''; dz.style.background = ''; const f = e.dataTransfer.files[0]; if (f) handleFile(f); });
});

function handleFile(file) {
  if (!file) return;
  if (!file.name.match(/\.(xlsx?|csv)$/i)) { showToast('Format harus .xlsx, .xls, atau .csv', 'err'); return; }
  if (file.size > 10 * 1024 * 1024) { showToast('File maksimal 10 MB', 'err'); return; }

  currentFile = file;
  document.getElementById('file-name').textContent = file.name + ' (' + (file.size / 1024).toFixed(1) + ' KB)';
  document.getElementById('file-info').style.display = 'block';

  uploadPreview(file);
}

function resetFile() {
  currentFile = null;
  previewData = null;
  document.getElementById('file-info').style.display = 'none';
  document.getElementById('card-preview').style.display = 'none';
  document.getElementById('card-result').style.display = 'none';
  document.getElementById('file-input').value = '';
}

async function uploadPreview(file) {
  const form = new FormData();
  form.append('file', file);

  document.getElementById('card-preview').style.display = 'block';
  document.getElementById('tbody-preview').innerHTML = '<tr><td colspan="6" style="text-align:center;padding:30px;color:var(--ink3)">Memproses...</td></tr>';

  try {
    const res = await fetch('{{ route('guru.questions.import.preview') }}', {
      method: 'POST',
      headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
      body: form,
    });
    const data = await res.json();
    previewData = data;
    renderPreview();
  } catch (e) {
    document.getElementById('tbody-preview').innerHTML = '<tr><td colspan="6" style="text-align:center;padding:30px;color:var(--red)">Gagal memproses file</td></tr>';
    showToast('Gagal preview file', 'err');
  }
}

function renderPreview() {
  if (!previewData) return;

  const filter = document.getElementById('filter-preview').value;
  const rows = previewData.preview || [];
  const filtered = filter === 'all' ? rows : rows.filter(r => r.status === filter);

  // Summary
  document.getElementById('summary-bar').style.display = 'block';
  document.getElementById('s-total').textContent = previewData.total_rows || 0;
  document.getElementById('s-ok').textContent = previewData.valid_count || 0;
  document.getElementById('s-err').textContent = previewData.error_count || 0;
  document.getElementById('s-preview').textContent = rows.length;

  // Table
  const diffLabel = {easy:'Mudah', medium:'Sedang', hard:'Sulit'};
  document.getElementById('tbody-preview').innerHTML = filtered.map(r => {
    const isOk = r.status === 'ok';
    const opts = r.options || {};
    const optStr = Object.keys(opts).slice(0,4).map(k => `<span style="display:inline-block;padding:1px 5px;border-radius:3px;font-size:10px;font-weight:${k===r.correct_answer?'700':'400'};background:${k===r.correct_answer?'var(--green-light)':'var(--bg)'};color:${k===r.correct_answer?'var(--green)':'var(--ink3)'};margin-right:3px">${k}. ${opts[k]}</span>`).join('');

    if (isOk) {
      return `<tr style="border-left:3px solid var(--green)">
        <td style="font-family:monospace;color:var(--ink3);font-size:12px">${r.row}</td>
        <td class="td-main" style="max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${r.question_text || ''}</td>
        <td style="font-size:11px">${optStr}</td>
        <td style="font-family:monospace;font-weight:700;color:var(--green)">${r.correct_answer || ''}</td>
        <td><span class="badge ${ {easy:'b-green',medium:'b-amber',hard:'b-red'}[r.difficulty] || 'b-gray'}">${diffLabel[r.difficulty] || r.difficulty}</span></td>
        <td><span class="badge b-green">Valid</span></td>
      </tr>`;
    } else {
      const errors = (r.errors || []).join('; ');
      return `<tr style="border-left:3px solid var(--red)">
        <td style="font-family:monospace;color:var(--ink3);font-size:12px">${r.row}</td>
        <td colspan="4" style="color:var(--red);font-size:12px">${errors}</td>
        <td><span class="badge b-red">Error</span></td>
      </tr>`;
    }
  }).join('') || '<tr><td colspan="6" style="text-align:center;padding:20px;color:var(--ink3)">Tidak ada data</td></tr>';

  // Footer
  const validCount = previewData.valid_count || 0;
  const footer = document.getElementById('preview-footer');
  footer.style.display = 'flex';
  document.getElementById('btn-import').disabled = validCount === 0;
}

async function executeImport() {
  if (!currentFile || !previewData) return;

  const btn = document.getElementById('btn-import');
  btn.disabled = true;
  btn.innerHTML = '<span class="sk" style="display:inline-block;width:14px;height:14px;border-radius:50%;vertical-align:middle"></span> Mengimport...';

  const form = new FormData();
  form.append('file', currentFile);
  form.append('subject_id', document.getElementById('import-subject').value || '');
  form.append('category_id', document.getElementById('import-category').value || '');

  try {
    const res = await fetch('{{ route('guru.questions.import.execute') }}', {
      method: 'POST',
      headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
      body: form,
    });
    const data = await res.json();

    // Show result
    const resultCard = document.getElementById('card-result');
    resultCard.style.display = 'block';
    const imp = data.import || {};
    const hasErr = imp.error_count > 0;
    document.getElementById('result-title').innerHTML = hasErr
      ? '<span style="color:var(--amber)">⚠️ Import Selesai dengan Error</span>'
      : '<span style="color:var(--green)">✅ Import Berhasil</span>';

    let html = `<div style="text-align:center;padding:8px">
      <div style="font-size:28px;font-weight:700;color:${hasErr ? 'var(--amber)' : 'var(--green)'}">${imp.success_count || 0}</div>
      <div style="font-size:12px;color:var(--ink3)">Soal berhasil diimpor</div>`;
    if (imp.error_count > 0) {
      html += `<div style="font-size:14px;color:var(--red);margin-top:4px">${imp.error_count} error</div>`;
    }
    html += `</div>`;

    if (imp.errors && imp.errors.length > 0) {
      html += `<div style="margin-top:10px;padding:10px;background:var(--red-light);border-radius:6px;font-size:11px;color:var(--red)">`;
      imp.errors.forEach(e => { html += `<div style="margin-bottom:3px">• ${e}</div>`; });
      html += `</div>`;
    }

    document.getElementById('result-body').innerHTML = html;

    showToast(imp.success_count + ' soal berhasil diimpor', hasErr ? 'err' : 'ok');
    loadHistory();
    resetFile();
  } catch (e) {
    showToast('Gagal import: ' + (e.message || 'Unknown error'), 'err');
    btn.disabled = false;
    btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg> Import Soal';
  }
}

async function loadHistory() {
  try {
    const res = await fetch('{{ route('guru.questions.import.history') }}', {
      headers: { 'Accept': 'application/json' },
    });
    const data = await res.json();
    const list = data.data || [];
    document.getElementById('history-list').innerHTML = list.length === 0
      ? '<div style="padding:16px;text-align:center;color:var(--ink3);font-size:13px">Belum ada riwayat import</div>'
      : list.map(h => {
          const icon = h.status === 'completed' ? (h.has_errors ? '⚠️' : '✅') : '❌';
          const color = h.has_errors ? 'var(--amber)' : 'var(--green)';
          return `<div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid var(--border)">
            <span style="font-size:18px">${icon}</span>
            <div style="flex:1;min-width:0">
              <div style="font-size:13px;font-weight:500;color:var(--ink);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${h.filename}</div>
              <div style="font-size:11px;color:var(--ink3)">${new Date(h.created_at).toLocaleDateString('id-ID')}</div>
            </div>
            <div style="text-align:right;flex-shrink:0">
              <div style="font-size:13px;font-weight:700;color:${color}">${h.success_count}</div>
              ${h.error_count > 0 ? `<div style="font-size:11px;color:var(--red)">${h.error_count} err</div>` : ''}
            </div>
          </div>`;
        }).join('');
  } catch (e) {
    document.getElementById('history-list').innerHTML = '<div style="padding:16px;text-align:center;color:var(--red);font-size:13px">Gagal load history</div>';
  }
}
</script>
@endpush
@endSection

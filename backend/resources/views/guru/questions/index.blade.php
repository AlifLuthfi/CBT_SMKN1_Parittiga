@extends('layouts.app')
@section('title', $subject->name ?? 'Input Soal')
@section('page-title', $subject->name ?? 'Input Soal')
@section('content')
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="flex items-center gap-3">
    @if(isset($subject))
    <a href="{{ route('guru.subjects') }}" class="icon-btn" title="Kembali ke Mapel">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
    </a>
    @endif
    <div class="page-sub" style="margin:0">Total {{ $questions->total() }} soal</div>
  </div>
  <div class="ph-actions">
    <a href="{{ route('guru.questions.import') }}{{ isset($subject) ? '?subject_id='.$subject->id : '' }}" class="btn btn-ghost">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
      Import Excel
    </a>
    <button class="btn btn-primary" onclick="openModal('createModal')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
      Tambah Soal
    </button>
  </div>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Soal</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @foreach($questions as $q)
        <tr>
          <td class="td-main truncate" style="max-width:280px">{{ strip_tags($q->question_text) }}</td>
          <td class="right">
            <div style="display:flex;gap:5px;justify-content:flex-end">
              <button class="icon-btn" onclick='openInfoModal(@json($q))' title="Info Soal"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg></button>
              <button class="icon-btn" onclick='openEditModal(@json($q))' title="Edit"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
              <form method="POST" action="{{ route('guru.questions.delete', $q) }}" class="inline">
                @csrf @method('DELETE')
                <button class="icon-btn danger" onclick="return confirm('Hapus soal?')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg></button>
              </form>
            </div>
          </td>
        </tr>
        @endforeach
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $questions->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>

{{-- Create Modal --}}
<div class="modal-overlay" id="createModal">
  <div class="modal" style="max-width:610px">
    <div class="modal-head"><span class="modal-title">Tambah Soal</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('guru.questions.store') }}" enctype="multipart/form-data">
      @csrf
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Mapel</label>@if(isset($subject))<input type="hidden" name="subject_id" value="{{ $subject->id }}"><div class="form-input" style="background:var(--bg2);color:var(--ink2);cursor:not-allowed;display:flex;align-items:center;height:38px;padding:0 10px;border-radius:6px;font-size:14px">{{ $subject->name }}</div>@else<select name="subject_id" class="form-input" required><option value="">-- Pilih Mapel --</option>@foreach($allSubjects as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach</select>@endif</div>
        <div class="form-group"><label class="form-label">Teks Soal *</label><textarea name="question_text" class="form-input" rows="3" required></textarea></div>
        <div class="form-group"><label class="form-label">Gambar Soal</label><input type="file" name="image" class="form-input" accept="image/*"></div>
        <div class="form-group">
          <label class="form-label">Opsi Jawaban</label>
          @foreach(['A','B','C','D','E'] as $l)
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px">
            <span style="width:20px;font-size:12px;font-weight:600;color:var(--ink3)">{{ $l }}.</span>
            <input type="text" name="options[{{ $l }}]" class="form-input" placeholder="Opsi {{ $l }}">
            <label style="display:flex;align-items:center;gap:4px;font-size:12px;white-space:nowrap;color:var(--ink2);cursor:pointer">
              <input type="radio" name="correct_answer" value="{{ $l }}" required style="accent-color:var(--navy)"> Benar
            </label>
          </div>
          @endforeach
        </div>
        <div class="form-group"><label class="form-label">Pembahasan</label><textarea name="explanation" class="form-input" rows="2"></textarea></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('createModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Simpan Soal</button>
      </div>
    </form>
  </div>
</div>

{{-- Edit Modal --}}
<div class="modal-overlay" id="editModal">
  <div class="modal" style="max-width:610px">
    <div class="modal-head"><span class="modal-title">Edit Soal</span><button class="modal-close" onclick="closeModal('editModal')">✕</button></div>
    <form method="POST" id="editForm" enctype="multipart/form-data">
      @csrf @method('PUT')
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Mapel</label><select name="subject_id" id="editSubject" class="form-input"><option value="">--</option>@foreach($allSubjects as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach</select></div>
        <div class="form-group"><label class="form-label">Teks Soal</label><textarea name="question_text" id="editText" class="form-input" rows="3" required></textarea></div>
        <div class="form-group">
          <label class="form-label">Gambar Soal</label>
          <div id="editImagePreview" style="margin-bottom:6px;display:none">
            <img id="editImageTag" src="" style="max-height:100px;border-radius:6px;margin-bottom:6px;display:block">
            <label style="display:flex;align-items:center;gap:6px;font-size:12px;cursor:pointer;color:var(--red)">
              <input type="checkbox" name="remove_image" value="1"> Hapus gambar
            </label>
          </div>
          <input type="file" name="image" class="form-input" accept="image/*">
        </div>
          <div class="form-group" id="editOptions"></div>
        <div class="form-group"><label class="form-label">Pembahasan</label><textarea name="explanation" id="editExplanation" class="form-input" rows="2"></textarea></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('editModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Simpan</button>
      </div>
    </form>
  </div>
</div>

{{-- Info Modal --}}
<div class="modal-overlay" id="infoModal">
  <div class="modal" style="max-width:560px">
    <div class="modal-head"><span class="modal-title">Info Soal</span><button class="modal-close" onclick="closeModal('infoModal')">✕</button></div>
    <div class="modal-body" id="infoBody"></div>
    <div class="modal-footer">
      <button type="button" class="btn btn-ghost" onclick="closeModal('infoModal')">Tutup</button>
    </div>
  </div>
</div>

@push('scripts')
<script>
function openInfoModal(q) {
  const opts = q.options || {};
  let optHtml = '';
  for (const [k, v] of Object.entries(opts)) {
    const ck = q.correct_answer === k;
    optHtml += `<div style="display:flex;align-items:center;gap:8px;padding:6px 10px;border-radius:6px;margin-bottom:4px;${ck ? 'background:var(--green-light);border:1px solid var(--green)' : 'background:var(--bg)'}">
      <span style="width:20px;font-size:12px;font-weight:700;color:${ck ? 'var(--green)' : 'var(--ink3)'}">${k}.</span>
      <span style="flex:1;font-size:13px">${v || ''}</span>
      ${ck ? '<span class="badge b-green" style="font-size:10px">✓ Benar</span>' : ''}
    </div>`;
  }

  let imgHtml = '';
  if (q.image_url) {
    imgHtml = `<div style="margin:12px 0"><img src="${q.image_url}" style="max-width:100%;max-height:200px;border-radius:8px;display:block"></div>`;
  }

  document.getElementById('infoBody').innerHTML = `
    <div style="margin-bottom:10px">
      <div style="font-size:11px;color:var(--ink3);margin-bottom:4px">Mata Pelajaran</div>
      <div style="font-weight:600">${q.subject_name || (q.subject?.name || '-')}</div>
    </div>
    <div style="margin-bottom:10px">
      <div style="font-size:11px;color:var(--ink3);margin-bottom:4px">Teks Soal</div>
      <div style="font-size:14px;line-height:1.6;background:var(--bg);padding:10px;border-radius:6px">${q.question_text}</div>
    </div>
    ${imgHtml}
    <div style="margin-bottom:10px">
      <div style="font-size:11px;color:var(--ink3);margin-bottom:4px">Opsi Jawaban</div>
      ${optHtml}
    </div>
    ${q.explanation ? `<div style="margin-bottom:6px"><div style="font-size:11px;color:var(--ink3);margin-bottom:4px">Pembahasan</div><div style="font-size:13px;background:var(--navy-light);padding:10px;border-radius:6px;color:var(--navy)">${q.explanation}</div></div>` : ''}
  `;
  openModal('infoModal');
}

function openEditModal(q) {
  document.getElementById('editSubject').value = q.subject_id || '';
  document.getElementById('editText').value = q.question_text;
  document.getElementById('editExplanation').value = q.explanation || '';
  document.getElementById('editForm').action = '/guru/questions/' + q.id + '/update';

  // Image preview
  const imgPreview = document.getElementById('editImagePreview');
  const imgTag = document.getElementById('editImageTag');
  if (q.image_url) {
    imgPreview.style.display = 'block';
    imgTag.src = q.image_url;
  } else {
    imgPreview.style.display = 'none';
    imgTag.src = '';
  }

  let h = '<label class="form-label">Opsi Jawaban</label>';
  const opts = q.options || {};
  for (const [k, v] of Object.entries(opts)) {
    const ck = q.correct_answer === k ? 'checked' : '';
    h += `<div style="display:flex;align-items:center;gap:8px;margin-bottom:6px"><span style="width:20px;font-size:12px;font-weight:600;color:var(--ink3)">${k}.</span><input type="text" name="options[${k}]" class="form-input" value="${v||''}"><label style="display:flex;align-items:center;gap:4px;font-size:12px;white-space:nowrap;color:var(--ink2);cursor:pointer"><input type="radio" name="correct_answer" value="${k}" ${ck} required style="accent-color:var(--navy)"> Benar</label></div>`;
  }
  document.getElementById('editOptions').innerHTML = h;
  openModal('editModal');
}
</script>
@endpush
@endSection

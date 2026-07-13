@extends('layouts.app')
@section('title', 'Input Soal')
@section('page-title', 'Input Soal')
@section('content')
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="page-sub" style="margin:0">Total {{ $questions->total() }} soal</div>
  <div class="ph-actions">
    <a href="{{ route('guru.questions.import') }}" class="btn btn-ghost">
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
      <thead><tr><th>Soal</th><th>Mapel</th><th>Gbr</th><th>Tingkat</th><th>Bobot</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @foreach($questions as $q)
        <tr>
          <td class="td-main truncate" style="max-width:280px">{{ strip_tags($q->question_text) }}</td>
          <td><span class="badge b-navy">{{ $q->subject?->name ?? '-' }}</span></td>
          <td>@if($q->image_url) <span title="Ada gambar" style="cursor:help;font-size:16px">🖼️</span> @else <span style="color:var(--ink4)">—</span> @endif</td>
          <td><span class="badge {{ $q->difficulty === 'easy' ? 'b-green' : ($q->difficulty === 'medium' ? 'b-amber' : 'b-red') }}">{{ $q->difficulty === 'easy' ? 'Mudah' : ($q->difficulty === 'medium' ? 'Sedang' : 'Sulit') }}</span></td>
          <td style="font-family:'JetBrains Mono',monospace">{{ $q->weight }}</td>
          <td class="right">
            <div style="display:flex;gap:5px;justify-content:flex-end">
              <button class="icon-btn" onclick='openEditModal(@json($q))'><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
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
  <div class="modal" style="max-width:600px">
    <div class="modal-head"><span class="modal-title">Tambah Soal</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('guru.questions.store') }}" enctype="multipart/form-data">
      @csrf
      <div class="modal-body">
        <div class="row2">
          <div class="form-group"><label class="form-label">Mapel</label><select name="subject_id" class="form-input"><option value="">--</option>@foreach($subjects as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach</select></div>
          <div class="form-group"><label class="form-label">Tingkat</label><select name="difficulty" class="form-input"><option value="easy">Mudah</option><option value="medium" selected>Sedang</option><option value="hard">Sulit</option></select></div>
        </div>
        <div class="form-group"><label class="form-label">Teks Soal *</label><textarea name="question_text" class="form-input" rows="3" required></textarea></div>
        <div class="form-group"><label class="form-label">Gambar Soal</label><input type="file" name="image" class="form-input" accept="image/*"></div>
        <div class="form-group"><label class="form-label">Bobot</label><input name="weight" class="form-input" value="1" step="0.01" style="width:100px"></div>
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
  <div class="modal" style="max-width:600px">
    <div class="modal-head"><span class="modal-title">Edit Soal</span><button class="modal-close" onclick="closeModal('editModal')">✕</button></div>
    <form method="POST" id="editForm" enctype="multipart/form-data">
      @csrf @method('PUT')
      <div class="modal-body">
        <div class="row2">
          <div class="form-group"><label class="form-label">Mapel</label><select name="subject_id" id="editSubject" class="form-input"><option value="">--</option>@foreach($subjects as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach</select></div>
          <div class="form-group"><label class="form-label">Tingkat</label><select name="difficulty" id="editDifficulty" class="form-input"><option value="easy">Mudah</option><option value="medium">Sedang</option><option value="hard">Sulit</option></select></div>
        </div>
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
        <div class="form-group"><label class="form-label">Bobot</label><input name="weight" id="editWeight" class="form-input" step="0.01" style="width:100px"></div>
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

@push('scripts')
<script>
function openEditModal(q) {
  document.getElementById('editSubject').value = q.subject_id || '';
  document.getElementById('editDifficulty').value = q.difficulty;
  document.getElementById('editText').value = q.question_text;
  document.getElementById('editWeight').value = q.weight;
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

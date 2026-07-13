@extends('layouts.app')
@section('title', 'Jadwal Ujian')
@section('page-title', 'Jadwal Ujian')
@section('content')
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="page-sub" style="margin:0">Total {{ $exams->total() }} ujian</div>
  <button class="btn btn-primary" onclick="openModal('createModal')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Ujian Baru
  </button>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Judul</th><th>Kelas</th><th>Status</th><th>Durasi</th><th>Soal</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @foreach($exams as $exam)
        <tr>
          <td class="td-main">{{ $exam->title }}</td>
          <td>{{ $exam->classRoom?->name }}</td>
          <td><span class="badge @switch($exam->status) @case('active') b-green @case('scheduled') b-amber @case('paused') b-orange @case('ended') b-navy @default b-gray @endswitch">{{ $exam->status }}</span></td>
          <td class="td-sm">{{ $exam->duration_minutes }} mnt</td>
          <td style="font-family:'JetBrains Mono',monospace">{{ $exam->questions_count }}</td>
          <td class="right">
            @if(in_array($exam->status, ['draft','scheduled']))
            <button class="icon-btn" onclick='openEditModal(@json($exam))' title="Edit"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
            <button class="icon-btn" onclick='openScheduleModal(@json($exam))' title="Jadwalkan"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg></button>
            <button class="icon-btn" onclick='openAddQModal(@json($exam))' title="Tambah Soal"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg></button>
            <form method="POST" action="{{ route('guru.exams.delete', $exam) }}" class="inline">
              @csrf @method('DELETE')
              <button class="icon-btn danger" onclick="return confirm('Hapus {{ $exam->title }}?')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg></button>
            </form>
            @endif
          </td>
        </tr>
        @endforeach
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $exams->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>

{{-- Create Modal --}}
<div class="modal-overlay" id="createModal">
  <div class="modal" style="max-width:560px">
    <div class="modal-head"><span class="modal-title">Buat Ujian Baru</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('guru.exams.store') }}">
      @csrf
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Judul *</label><input name="title" class="form-input" required></div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Kelas *</label><select name="class_id" class="form-input" required><option value="">--</option>@foreach($classes as $c)<option value="{{ $c->id }}">{{ $c->name }}</option>@endforeach</select></div>
          <div class="form-group"><label class="form-label">Paket</label><select name="package_id" class="form-input"><option value="">--</option>@foreach($packages as $p)<option value="{{ $p->id }}">{{ $p->title }}</option>@endforeach</select></div>
        </div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Durasi (menit)</label><input name="duration_minutes" class="form-input" value="90" type="number" required></div>
          <div class="form-group"><label class="form-label">Total Soal</label><input name="total_questions" class="form-input" value="10" type="number" required></div>
        </div>
        <div class="row2">
          <div class="form-group"><label class="form-label">KKM</label><input name="passing_grade" class="form-input" value="70" step="0.01"></div>
          <div class="form-group"><label class="form-label">Maks Pelanggaran</label><input name="max_violations" class="form-input" value="5" type="number"></div>
        </div>
        <div class="row2" style="font-size:12.5px;color:var(--ink2)">
          <label class="checkbox-label"><input type="checkbox" name="randomize_questions" value="1" checked> Acak Soal</label>
          <label class="checkbox-label"><input type="checkbox" name="randomize_options" value="1"> Acak Opsi</label>
          <label class="checkbox-label"><input type="checkbox" name="show_result_immediately" value="1" checked> Tampilkan Hasil</label>
          <label class="checkbox-label"><input type="checkbox" name="allow_review" value="1" checked> Izinkan Review</label>
        </div>
        <div class="form-group"><label class="form-label">Deskripsi</label><textarea name="description" class="form-input" rows="2"></textarea></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('createModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Buat Ujian</button>
      </div>
    </form>
  </div>
</div>

{{-- Edit Modal --}}
<div class="modal-overlay" id="editModal">
  <div class="modal" style="max-width:560px">
    <div class="modal-head"><span class="modal-title">Edit Ujian</span><button class="modal-close" onclick="closeModal('editModal')">✕</button></div>
    <form method="POST" id="editForm">
      @csrf @method('PUT')
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Judul</label><input name="title" id="editTitle" class="form-input" required></div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Durasi (menit)</label><input name="duration_minutes" id="editDuration" class="form-input" type="number" required></div>
          <div class="form-group"><label class="form-label">KKM</label><input name="passing_grade" id="editPassing" class="form-input" step="0.01"></div>
        </div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Total Soal</label><input name="total_questions" id="editTotal" class="form-input" type="number" required></div>
          <div class="form-group"><label class="form-label">Maks Pelanggaran</label><input name="max_violations" id="editViolations" class="form-input" type="number"></div>
        </div>
        <div class="row2" style="font-size:12.5px;color:var(--ink2)">
          <label class="checkbox-label"><input type="checkbox" name="randomize_questions" id="editRandQ" value="1"> Acak Soal</label>
          <label class="checkbox-label"><input type="checkbox" name="randomize_options" id="editRandO" value="1"> Acak Opsi</label>
          <label class="checkbox-label"><input type="checkbox" name="show_result_immediately" id="editShowResult" value="1"> Tampilkan Hasil</label>
          <label class="checkbox-label"><input type="checkbox" name="allow_review" id="editAllowReview" value="1"> Izinkan Review</label>
        </div>
        <div class="form-group"><label class="form-label">Deskripsi</label><textarea name="description" id="editDesc" class="form-input" rows="2"></textarea></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('editModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Simpan</button>
      </div>
    </form>
  </div>
</div>

{{-- Schedule Modal --}}
<div class="modal-overlay" id="scheduleModal">
  <div class="modal" style="max-width:420px">
    <div class="modal-head"><span class="modal-title">Jadwalkan Ujian</span><button class="modal-close" onclick="closeModal('scheduleModal')">✕</button></div>
    <form method="POST" id="scheduleForm">
      @csrf @method('PATCH')
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Waktu Mulai</label><input type="datetime-local" name="start_time" id="schedStart" class="form-input" required></div>
        <div class="form-group"><label class="form-label">Waktu Selesai</label><input type="datetime-local" name="end_time" id="schedEnd" class="form-input" required></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('scheduleModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Jadwalkan</button>
      </div>
    </form>
  </div>
</div>

{{-- Add Questions Modal --}}
<div class="modal-overlay" id="addQModal">
  <div class="modal" style="max-width:420px">
    <div class="modal-head"><span class="modal-title">Tambah Soal</span><button class="modal-close" onclick="closeModal('addQModal')">✕</button></div>
    <form method="POST" id="addQForm">
      @csrf
      <div class="modal-body">
        <div class="form-group"><label class="form-label">ID Soal (pisahkan koma)</label><input name="question_ids" class="form-input" placeholder="1,2,3,4,5" required></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('addQModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Tambah</button>
      </div>
    </form>
  </div>
</div>

@push('scripts')
<script>
function openEditModal(e) {
  document.getElementById('editTitle').value = e.title;
  document.getElementById('editDuration').value = e.duration_minutes;
  document.getElementById('editPassing').value = e.passing_grade;
  document.getElementById('editTotal').value = e.total_questions;
  document.getElementById('editViolations').value = e.max_violations;
  document.getElementById('editDesc').value = e.description || '';
  document.getElementById('editRandQ').checked = e.randomize_questions;
  document.getElementById('editRandO').checked = e.randomize_options;
  document.getElementById('editShowResult').checked = e.show_result_immediately;
  document.getElementById('editAllowReview').checked = e.allow_review;
  document.getElementById('editForm').action = '/guru/exams/' + e.id + '/update';
  openModal('editModal');
}
function openScheduleModal(e) {
  document.getElementById('scheduleForm').action = '/guru/exams/' + e.id + '/schedule';
  openModal('scheduleModal');
}
function openAddQModal(e) {
  document.getElementById('addQForm').action = '/guru/exams/' + e.id + '/questions';
  openModal('addQModal');
}
</script>
@endpush
@endSection

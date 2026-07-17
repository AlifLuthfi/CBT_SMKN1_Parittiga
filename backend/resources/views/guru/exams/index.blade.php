@extends('layouts.app')
@section('title', 'Jadwal Ujian')
@section('page-title', 'Jadwal Ujian')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div style="display:flex;align-items:center;gap:12px">
    <div class="page-sub" style="margin:0">Total {{ $exams->total() }} ujian</div>
  </div>
  <button class="btn btn-primary" onclick="openModal('createModal')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Ujian Baru
  </button>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Judul</th><th>Kelas</th><th>Jadwal</th><th>Status</th><th>Durasi</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @foreach($exams as $exam)
        <tr>
          <td class="td-main">{{ $exam->title }}</td>
          <td>{{ $exam->classRoom?->name }}</td>
          <td class="td-sm" style="white-space:nowrap">
            @if($exam->start_time)
              {{ \Carbon\Carbon::parse($exam->start_time)->locale('id')->isoFormat('dddd, DD/MM/YYYY • HH:mm') }}
            @else
              <span style="color:var(--ink3)">—</span>
            @endif
          </td>
          <td><span class="badge @switch($exam->status) @case('active') b-green @case('scheduled') b-amber @case('paused') b-orange @case('ended') b-navy @default b-gray @endswitch">{{ $exam->status }}</span></td>
          <td class="td-sm">{{ $exam->duration_minutes }} mnt</td>
          <td class="right">
            @if(in_array($exam->status, ['draft','scheduled']))
            <button class="icon-btn" onclick='openEditModal(@json($exam))' title="Edit"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
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
  <div class="modal" style="max-width:570px">
    <div class="modal-head"><span class="modal-title">Buat Ujian Baru</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('guru.exams.store') }}">
      @csrf
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Judul *</label><input name="title" class="form-input" required></div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Kelas *</label><select name="class_id" class="form-input" required><option value="">--</option>@foreach($classes as $c)<option value="{{ $c->id }}">{{ $c->name }}</option>@endforeach</select></div>
          <div class="form-group"><label class="form-label">Mata Pelajaran *</label><select name="subject_id" class="form-input" required><option value="">--</option>@foreach($subjects as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach</select></div>
        </div>
        <div class="row2">
          <div class="form-group date-wrap"><label class="form-label">Tanggal Ujian</label><input type="date" name="start_date" class="form-input"></div>
          <div class="form-group time-wrap"><label class="form-label">Jam Mulai</label><div class="input-icon-wrap"><input type="text" name="start_time" class="form-input fp-time" value="07:30" placeholder="--:--" autocomplete="off"><svg class="clock-trigger" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div></div>
        </div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Durasi (menit)</label><input name="duration_minutes" class="form-input" value="90" type="number" required></div>
          <div class="form-group"><label class="form-label">KKM</label><input name="passing_grade" class="form-input" value="70" step="0.01"></div>
        </div>
        <div class="form-group" style="background:var(--navy-light);padding:12px;border-radius:8px">
          <div style="font-size:12px;color:var(--navy);display:flex;align-items:center;gap:6px">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:15px;height:15px;flex-shrink:0"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            Soal dan opsi diacak otomatis (LCG). Hasil hanya menampilkan jawaban salah.
          </div>
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
  <div class="modal" style="max-width:570px">
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
          <div class="form-group date-wrap"><label class="form-label">Tanggal Ujian</label><input type="date" name="start_date" id="editStartDate" class="form-input"></div>
          <div class="form-group time-wrap"><label class="form-label">Jam Mulai</label><div class="input-icon-wrap"><input type="text" name="start_time" id="editStartTime" class="form-input fp-time" placeholder="--:--" autocomplete="off"><svg class="clock-trigger" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div></div>
        </div>
        <div class="form-group" style="background:var(--navy-light);padding:12px;border-radius:8px">
          <div style="font-size:12px;color:var(--navy);display:flex;align-items:center;gap:6px">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:15px;height:15px;flex-shrink:0"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            Soal dan opsi diacak otomatis (LCG). Hasil hanya menampilkan jawaban salah.
          </div>
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
  <div class="modal" style="max-width:430px">
    <div class="modal-head"><span class="modal-title">Jadwalkan Ujian</span><button class="modal-close" onclick="closeModal('scheduleModal')">✕</button></div>
    <form method="POST" id="scheduleForm">
      @csrf @method('PATCH')
      <div class="modal-body">
        <div class="form-group date-wrap"><label class="form-label">Tanggal Ujian</label><input type="date" name="start_date" id="schedDate" class="form-input" required></div>
        <div class="row2">
          <div class="form-group time-wrap"><label class="form-label">Jam Mulai</label><div class="input-icon-wrap"><input type="text" name="start_time" id="schedStart" class="form-input fp-time" placeholder="--:--" autocomplete="off" required><svg class="clock-trigger" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div></div>
          <div class="form-group time-wrap"><label class="form-label">Jam Selesai</label><div class="input-icon-wrap"><input type="text" name="end_time" id="schedEnd" class="form-input fp-time" placeholder="--:--" autocomplete="off" required><svg class="clock-trigger" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div></div>
        </div>
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
  <div class="modal" style="max-width:430px">
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
function toLocalDate(d) {
  return d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0');
}
function toLocalTime(d) {
  return String(d.getHours()).padStart(2,'0') + ':' + String(d.getMinutes()).padStart(2,'0');
}
function parseExamDate(str) {
  if (!str) return null;
  // MySQL YYYY-MM-DD HH:MM:SS
  var m = str.match(/^(\d{4})-(\d{2})-(\d{2})[\sT](\d{2}):(\d{2})/);
  if (m) return new Date(+m[1], +m[2]-1, +m[3], +m[4], +m[5]);
  // ISO with timezone
  var d = new Date(str);
  return isNaN(d.getTime()) ? null : d;
}
function openEditModal(e) {
  document.getElementById('editTitle').value = e.title;
  document.getElementById('editDuration').value = e.duration_minutes;
  document.getElementById('editPassing').value = e.passing_grade;
  document.getElementById('editDesc').value = e.description || '';
  var dt = parseExamDate(e.start_time);
  if (dt) {
    document.getElementById('editStartDate').value = toLocalDate(dt);
    document.getElementById('editStartDate').closest('.date-wrap')?.classList.add('has-date');
    document.getElementById('editStartTime').value = toLocalTime(dt);
    document.getElementById('editStartTime').closest('.time-wrap')?.classList.add('has-time');
  } else {
    document.getElementById('editStartDate').value = '';
    document.getElementById('editStartDate').closest('.date-wrap')?.classList.remove('has-date');
    document.getElementById('editStartTime').value = '';
    document.getElementById('editStartTime').closest('.time-wrap')?.classList.remove('has-time');
  }
  document.getElementById('editForm').action = '/guru/exams/' + e.id + '/update';
  openModal('editModal');
}
function openScheduleModal(e) {
  document.getElementById('scheduleForm').action = '/guru/exams/' + e.id + '/schedule';
  var dt = parseExamDate(e.start_time);
  if (dt) {
    document.getElementById('schedDate').value = toLocalDate(dt);
    document.getElementById('schedDate').closest('.date-wrap')?.classList.add('has-date');
    document.getElementById('schedStart').value = toLocalTime(dt);
    document.getElementById('schedStart').closest('.time-wrap')?.classList.add('has-time');
  } else {
    document.getElementById('schedDate').value = '';
    document.getElementById('schedDate').closest('.date-wrap')?.classList.remove('has-date');
    document.getElementById('schedStart').value = '';
    document.getElementById('schedStart').closest('.time-wrap')?.classList.remove('has-time');
  }
  document.getElementById('schedEnd').value = '';
  document.getElementById('schedEnd').closest('.time-wrap')?.classList.remove('has-time');
  openModal('scheduleModal');
}
function openAddQModal(e) {
  document.getElementById('addQForm').action = '/guru/exams/' + e.id + '/questions';
  openModal('addQModal');
}
</script>
@endpush
@endSection

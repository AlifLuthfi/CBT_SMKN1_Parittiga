@extends('layouts.app')
@section('title', 'Kelas')
@section('page-title', 'Manajemen Kelas')
@section('content')
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="page-sub" style="margin:0">Total {{ $classes->total() }} kelas</div>
  <button class="btn btn-primary" onclick="openModal('createModal')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Tambah Kelas
  </button>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Nama Kelas</th><th>Guru</th><th>Mapel</th><th>Tingkat</th><th>Siswa</th><th>Tahun Ajaran</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @foreach($classes as $class)
        <tr>
          <td class="td-main">{{ $class->name }}</td>
          <td>{{ $class->teacher?->name ?? '-' }}</td>
          <td><span class="badge b-navy">{{ $class->subject }}</span></td>
          <td><span class="badge {{ $class->level === '10' ? 'b-orange' : ($class->level === '11' ? 'b-sky' : 'b-green') }}">Kelas {{ $class->level }}</span></td>
          <td style="font-family:'JetBrains Mono',monospace">{{ $class->students_count ?? $class->student_count }}</td>
          <td class="td-sm">{{ $class->academic_year }} {{ $class->semester }}</td>
          <td class="right">
            <div style="display:flex;gap:5px;justify-content:flex-end">
              <button class="icon-btn" onclick='openEditModal(@json($class))'><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
              <form method="POST" action="{{ route('admin.classes.delete', $class) }}" class="inline">
                @csrf @method('DELETE')
                <button class="icon-btn danger" onclick="return confirm('Hapus kelas?')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg></button>
              </form>
            </div>
          </td>
        </tr>
        @endforeach
      </tbody>
    </table>
  </div>
  <div class="pager">
    <span>Menampilkan {{ $classes->firstItem() }}-{{ $classes->lastItem() }} dari {{ $classes->total() }}</span>
    <div class="pager-btns">{{ $classes->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
  </div>
</div>

{{-- Create Modal --}}
<div class="modal-overlay" id="createModal">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Tambah Kelas Baru</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('admin.classes.store') }}">
      @csrf
      <div class="modal-body">
        <div class="row2">
          <div class="form-group"><label class="form-label">Nama Kelas *</label><input name="name" class="form-input" required placeholder="X IPA 1"></div>
          <div class="form-group"><label class="form-label">Mata Pelajaran *</label><input name="subject" class="form-input" required placeholder="Matematika"></div>
        </div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Tingkatan *</label><select name="level" class="form-input" required><option value="10">Kelas 10</option><option value="11">Kelas 11</option><option value="12">Kelas 12</option></select></div>
          <div class="form-group"><label class="form-label">Guru *</label><select name="teacher_id" class="form-input" required><option value="">-- Pilih --</option>@foreach($gurus as $g)<option value="{{ $g->id }}">{{ $g->name }}</option>@endforeach</select></div>
        </div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Tahun Ajaran</label><input name="academic_year" class="form-input" value="2024/2025"></div>
          <div class="form-group"><label class="form-label">Semester</label><select name="semester" class="form-input"><option value="Ganjil">Ganjil</option><option value="Genap">Genap</option></select></div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('createModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Buat Kelas</button>
      </div>
    </form>
  </div>
</div>

{{-- Edit Modal --}}
<div class="modal-overlay" id="editModal">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Edit Kelas</span><button class="modal-close" onclick="closeModal('editModal')">✕</button></div>
    <form method="POST" id="editForm">
      @csrf @method('PUT')
      <div class="modal-body">
        <div class="row2">
          <div class="form-group"><label class="form-label">Nama Kelas</label><input name="name" id="editName" class="form-input" required></div>
          <div class="form-group"><label class="form-label">Mata Pelajaran</label><input name="subject" id="editSubject" class="form-input" required></div>
        </div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Tingkatan</label><select name="level" id="editLevel" class="form-input" required><option value="10">Kelas 10</option><option value="11">Kelas 11</option><option value="12">Kelas 12</option></select></div>
          <div class="form-group"><label class="form-label">Tahun Ajaran</label><input name="academic_year" id="editYear" class="form-input"></div>
        </div>
        <div class="form-group"><label class="form-label">Semester</label><select name="semester" id="editSemester" class="form-input"><option value="Ganjil">Ganjil</option><option value="Genap">Genap</option></select></div>
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
function openEditModal(c) {
  document.getElementById('editName').value = c.name;
  document.getElementById('editSubject').value = c.subject;
  document.getElementById('editLevel').value = c.level || '10';
  document.getElementById('editYear').value = c.academic_year;
  document.getElementById('editSemester').value = c.semester;
  document.getElementById('editForm').action = '/admin/classes/' + c.id + '/update';
  openModal('editModal');
}
</script>
@endpush
@endSection

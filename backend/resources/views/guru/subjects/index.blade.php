@extends('layouts.app')
@section('title', 'Mata Pelajaran')
@section('page-title', 'Mata Pelajaran')
@section('content')
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="page-sub" style="margin:0">{{ $subjects->count() }} mapel</div>
  <button class="btn btn-primary" onclick="openModal('createModal')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Tambah Mapel
  </button>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Nama Mapel</th><th>Total Soal</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @foreach($subjects as $s)
        <tr>
          <td class="td-main">{{ $s->name }}</td>
          <td style="font-family:'JetBrains Mono',monospace">{{ $s->questions_count }}</td>
          <td class="right">
            <div style="display:flex;gap:5px;justify-content:flex-end">
              <button class="icon-btn" onclick='openEditModal(@json($s))'><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
              <form method="POST" action="{{ route('guru.subjects.delete', $s) }}" class="inline">
                @csrf @method('DELETE')
                <button class="icon-btn danger" onclick="return confirm('Hapus {{ $s->name }}?')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg></button>
              </form>
            </div>
          </td>
        </tr>
        @endforeach
      </tbody>
    </table>
  </div>
</div>

{{-- Create Modal --}}
<div class="modal-overlay" id="createModal">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Tambah Mapel</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('guru.subjects.store') }}">
      @csrf
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Nama Mapel *</label><input name="name" class="form-input" required></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('createModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Tambah</button>
      </div>
    </form>
  </div>
</div>

{{-- Edit Modal --}}
<div class="modal-overlay" id="editModal">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Edit Mapel</span><button class="modal-close" onclick="closeModal('editModal')">✕</button></div>
    <form method="POST" id="editForm">
      @csrf @method('PUT')
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Nama Mapel</label><input name="name" id="editName" class="form-input" required></div>
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
function openEditModal(s) {
  document.getElementById('editName').value = s.name;
  document.getElementById('editForm').action = '/guru/subjects/' + s.id + '/update';
  openModal('editModal');
}
</script>
@endpush
@endSection

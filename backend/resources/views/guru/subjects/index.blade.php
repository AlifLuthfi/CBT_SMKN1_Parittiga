@extends('layouts.app')
@section('title', 'Input Soal')
@section('page-title', 'Input Soal')
@section('content')
<a href="{{ route('dashboard') }}" class="back-link">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
  Kembali
</a>
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="page-sub" style="margin:0">{{ $subjects->count() }} mapel — klik mapel untuk kelola soal</div>
  <button class="btn btn-primary" onclick="openModal('createModal')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Tambah Mapel
  </button>
</div>

<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:14px">
  @forelse($subjects as $s)
  <div class="subject-card-wrap">
    <a href="{{ route('guru.subjects.questions', $s) }}" class="subject-card">
      <div class="sc-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
      </div>
      <div class="sc-name">{{ $s->name }}</div>
      <div class="sc-count">{{ $s->questions_count }} soal</div>
    </a>
    <div class="sc-actions">
      <button class="icon-btn" data-subject='{{ json_encode($s, JSON_HEX_APOS) }}' onclick="openEditModal(this)"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
      <form method="POST" action="{{ route('guru.subjects.delete', $s) }}" class="inline">
        @csrf @method('DELETE')
        <button class="icon-btn danger" onclick="return confirm('Hapus {{ $s->name }}?')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg></button>
      </form>
    </div>
  </div>
  @empty
  <div class="card" style="grid-column:1/-1;padding:40px;text-align:center;color:var(--ink3)">
    Belum ada mata pelajaran. Klik Tambah Mapel untuk mulai.
  </div>
  @endforelse
</div>

{{-- Create Modal --}}
<div class="modal-overlay" id="createModal">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Tambah Mapel</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('guru.subjects.store') }}">
      @csrf
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Nama Mapel *</label><input name="name" class="form-input @error('name') is-invalid @enderror" required value="{{ old('name') }}">
          @error('name')<span style="color:var(--red);font-size:11px;margin-top:4px;display:block">{{ $message }}</span>@enderror
        </div>
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
    <div class="modal-head"><span class="modal-title">Edit Nama Mapel</span><button class="modal-close" onclick="closeModal('editModal')">✕</button></div>
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
function openEditModal(btn) {
  var s = JSON.parse(btn.getAttribute('data-subject'));
  document.getElementById('editName').value = s.name;
  document.getElementById('editForm').action = '/guru/subjects/' + s.id + '/update';
  openModal('editModal');
}
</script>
@endpush

<style>
.subject-card-wrap{position:relative;display:flex;flex-direction:column}
.subject-card{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:24px 20px;text-align:center;text-decoration:none;color:var(--ink);transition:all .2s;display:flex;flex-direction:column;align-items:center;gap:10px}
.subject-card:hover{box-shadow:0 4px 20px rgba(0,0,0,.1);transform:translateY(-2px);border-color:var(--navy)}
.subject-card .sc-icon{width:48px;height:48px;border-radius:12px;background:var(--navy-light);display:grid;place-items:center;color:var(--navy)}
.subject-card .sc-icon svg{width:24px;height:24px}
.subject-card .sc-name{font-size:15px;font-weight:600}
.subject-card .sc-count{font-size:12px;color:var(--ink3);font-family:'JetBrains Mono',monospace}
.sc-actions{display:flex;gap:4px;justify-content:center;padding:8px 0 4px}
</style>
@endSection

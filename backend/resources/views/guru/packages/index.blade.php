@extends('layouts.app')
@section('title', 'Paket Soal')
@section('page-title', 'Paket Soal')
@section('content')
<div class="flex items-center justify-between mb-6" style="flex-wrap:wrap;gap:12px">
  <div class="page-sub" style="margin:0">Total {{ $packages->total() }} paket</div>
  <button class="btn btn-primary" onclick="openModal('createModal')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Paket Baru
  </button>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead><tr><th>Judul</th><th>Mapel</th><th>Kelas</th><th>Soal</th><th class="right">Aksi</th></tr></thead>
      <tbody>
        @foreach($packages as $p)
        <tr>
          <td class="td-main">{{ $p->title }}</td>
          <td><span class="badge b-navy">{{ $p->subject }}</span></td>
          <td>{{ $p->classRoom?->name ?? '-' }}</td>
          <td style="font-family:'JetBrains Mono',monospace">{{ $p->questions_count }}</td>
          <td class="right">
            <form method="POST" action="{{ route('guru.packages.delete', $p) }}" class="inline">
              @csrf @method('DELETE')
              <button class="icon-btn danger" onclick="return confirm('Hapus paket?')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg></button>
            </form>
          </td>
        </tr>
        @endforeach
      </tbody>
    </table>
  </div>
  <div class="pager">{{ $packages->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>

{{-- Create Modal --}}
<div class="modal-overlay" id="createModal">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Paket Baru</span><button class="modal-close" onclick="closeModal('createModal')">✕</button></div>
    <form method="POST" action="{{ route('guru.packages.store') }}">
      @csrf
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Judul *</label><input name="title" class="form-input" required></div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Mapel *</label><input name="subject" class="form-input" required></div>
          <div class="form-group"><label class="form-label">Kelas *</label><select name="class_id" class="form-input" required><option value="">--</option>@foreach($classes as $c)<option value="{{ $c->id }}">{{ $c->name }}</option>@endforeach</select></div>
        </div>
        <div class="form-group"><label class="form-label">ID Soal (pisahkan koma)</label><input name="question_ids" class="form-input" placeholder="1,2,3,4,5"></div>
        <div class="form-group"><label class="form-label">Deskripsi</label><textarea name="description" class="form-input" rows="2"></textarea></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('createModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Buat</button>
      </div>
    </form>
  </div>
</div>

@push('scripts')
<script>
function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
</script>
@endpush
@endSection

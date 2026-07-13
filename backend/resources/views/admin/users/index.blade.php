@extends('layouts.app')
@section('title', 'Manajemen User')
@section('page-title', 'Manajemen User')
@section('content')

@if(!request('role'))
{{-- ===== MENU: 3 clickable cards ===== --}}
@php
$menuRoles = [
  ['key' => 'admin', 'label' => 'Admin', 'desc' => 'Kelola akun admin & pengaturan sistem',
   'sub' => 'Akses penuh ke semua fitur',
   'icon' => 'M12 15v2m-6 4h12a2 2 0 0 0 2-2v-6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2zm10-10V7a4 4 0 0 0-8 0v4h8z',
   'color' => 'var(--orange)', 'bg' => 'var(--orange-light)', 'count' => $stats['admin']],
  ['key' => 'guru',  'label' => 'Guru',  'desc' => 'Kelola akun guru, mapel, & kelas',
   'sub' => 'Buat soal, jadwal ujian, rekap nilai',
   'icon' => 'M4 19.5A2.5 2.5 0 0 1 6.5 17H20M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z',
   'color' => 'var(--navy)', 'bg' => 'var(--navy-light)', 'count' => $stats['guru']],
  ['key' => 'siswa', 'label' => 'Siswa', 'desc' => 'Kelola akun siswa & pendaftaran kelas',
   'sub' => 'Atur akses ujian & pantau aktivitas',
   'icon' => 'M22 10v6M2 10l10-5 10 5-10 5zM6 12v5c3 3 9 3 12 0v-5',
   'color' => 'var(--green)', 'bg' => 'var(--green-light)', 'count' => $stats['siswa']],
];
@endphp

<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(400px,1fr));gap:16px;padding:8px 0">
  @foreach($menuRoles as $m)
  <a href="{{ route('admin.users', ['role' => $m['key']]) }}" class="role-menu-card" style="text-decoration:none;display:flex;align-items:center;gap:18px;background:var(--surface);border:1px solid var(--border);border-radius:18px;padding:24px 22px;transition:all .25s ease;box-shadow:0 2px 8px rgba(0,0,0,.04)">
    <div style="width:60px;height:60px;border-radius:16px;background:{{ $m['bg'] }};color:{{ $m['color'] }};display:grid;place-items:center;flex-shrink:0;box-shadow:0 4px 12px {{ $m['color'] }}22">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" style="width:30px;height:30px"><path d="{{ $m['icon'] }}"/></svg>
    </div>
    <div style="flex:1;min-width:0">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:5px">
        <span style="font-size:18px;font-weight:700;color:var(--ink)">{{ $m['label'] }}</span>
        <span style="font-size:12px;color:{{ $m['color'] }};font-weight:700;background:{{ $m['bg'] }};padding:2px 10px;border-radius:10px">{{ $m['count'] }} akun</span>
      </div>
      <div style="font-size:13px;color:var(--ink2);margin-bottom:3px">{{ $m['desc'] }}</div>
      <div style="display:flex;align-items:center;gap:5px">
        <svg viewBox="0 0 24 24" fill="none" stroke="{{ $m['color'] }}" stroke-width="2" style="width:12px;height:12px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        <span style="font-size:11px;color:var(--ink3);font-weight:500">{{ $m['sub'] }}</span>
      </div>
    </div>
    <svg viewBox="0 0 24 24" fill="none" stroke="var(--ink3)" stroke-width="2" style="width:22px;height:22px;flex-shrink:0"><polyline points="9 18 15 12 9 6"/></svg>
  </a>
  @endforeach
</div>

<style>
.role-menu-card:hover {
  transform:translateY(-3px);
  box-shadow:0 10px 30px rgba(0,0,0,.08) !important;
}
.role-menu-card:hover div[style*="60px;height:60px"] {
  transform:scale(1.05);
}
@media(max-width:600px){[style*="grid-template-columns:repeat(auto-fill,minmax(400px,1fr))"]{grid-template-columns:1fr!important}}
</style>

@else
{{-- ===== PER-ROLE CRUD LIST ===== --}}
@php
  $rk = request('role');
  $rl = ucfirst($rk);
  $roleColors = ['admin' => 'orange', 'guru' => 'navy', 'siswa' => 'green'];
  $rc = $roleColors[$rk] ?? 'navy';
@endphp

<div class="flex items-center justify-between mb-4" style="flex-wrap:wrap;gap:10px">
  <div style="display:flex;align-items:center;gap:10px">
    <a href="{{ route('admin.users') }}" class="btn btn-sm btn-ghost" style="padding:5px 10px">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="15 18 9 12 15 6"/></svg>
      Kembali
    </a>
    <span class="page-sub" style="margin:0">Menampilkan {{ $users->firstItem() }}-{{ $users->lastItem() }} dari {{ $users->total() }}</span>
  </div>
  <div style="display:flex;gap:6px">
    <form method="GET" action="{{ route('admin.users') }}" style="display:flex;gap:6px;align-items:center">
      <input type="hidden" name="role" value="{{ $rk }}">
      @if(request('level'))<input type="hidden" name="level" value="{{ request('level') }}">@endif
      <input type="text" name="search" class="form-input" style="width:180px;padding:5px 10px;font-size:12px" placeholder="Cari nama..." value="{{ request('search') }}">
      <button type="submit" class="btn btn-sm btn-ghost" style="padding:5px 9px">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:13px;height:13px"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
      </button>
      @if(request('search'))
      <a href="{{ route('admin.users', ['role' => $rk, 'level' => request('level')]) }}" class="btn btn-sm btn-ghost" style="padding:5px 9px">✕</a>
      @endif
    </form>
    @if($rk === 'siswa')
    @foreach(['10','11','12'] as $lv)
    <a href="{{ route('admin.users', array_merge(['role' => $rk], request('level') === $lv ? [] : ['level' => $lv], request('search') ? ['search' => request('search')] : [])) }}"
       class="btn btn-sm {{ request('level') === $lv ? 'btn-primary' : 'btn-ghost' }}">Kelas {{ $lv }}</a>
    @endforeach
    @endif
    <button class="btn btn-primary btn-sm" onclick="openModal('createModal{{ $rk }}')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:13px;height:13px"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
      Tambah {{ $rl }}
    </button>
  </div>
</div>

@if($users->count())
  <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(360px,1fr));gap:10px">
    @foreach($users as $u)
    @php
      $rc2 = $rc;
      $rcl = $rc === 'orange' ? 'var(--orange-light)' : ($rc === 'navy' ? 'var(--navy-light)' : 'var(--green-light)');
      $rcColor = $rc === 'orange' ? 'var(--orange)' : ($rc === 'navy' ? 'var(--navy)' : 'var(--green)');
    @endphp
    <div class="user-card-sm">
      <div class="ucs-head">
        <div class="ucs-av" style="background:{{ $u->status === 'active' ? $rcl : 'var(--bg)' }};color:{{ $u->status === 'active' ? $rcColor : 'var(--ink3)' }}">{{ strtoupper(substr($u->name,0,1)) }}</div>
        <div class="ucs-info">
          <div class="ucs-name">{{ $u->name }} @if($u->status !== 'active')<span class="rc-inactive">Nonaktif</span>@endif</div>
          <div class="ucs-email">{{ $u->email }}</div>
          @if($u->role === 'guru' && $u->classRooms->isNotEmpty())
          <div class="ucs-meta">{{ $u->classRooms->pluck('subject')->unique()->join(', ') }} · {{ $u->classRooms->pluck('name')->join(', ') }}</div>
          @elseif($u->role === 'siswa' && $u->enrolledClasses->isNotEmpty())
          <div class="ucs-meta">Kelas {{ $u->enrolledClasses->pluck('level')->unique()->join(', ') }} · {{ $u->enrolledClasses->pluck('name')->join(', ') }}</div>
          @endif
        </div>
        <div class="ucs-actions">
          <button type="button" class="ucs-btn ub-edit" onclick="openEdit({{ $u->id }})" title="Ubah">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
          @if($u->isSiswa())
          <!-- Pindah Kelas via Ubah -->
          @endif
          <button type="button" class="ucs-btn ub-toggle" onclick="toggleStatus({{ $u->id }})" title="{{ $u->status === 'active' ? 'Nonaktifkan' : 'Aktifkan' }}">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">@if($u->status === 'active')<circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>@else<polyline points="20 6 9 17 4 12"/>@endif</svg>
          </button>
          <button type="button" class="ucs-btn ub-ganti" onclick="gantiPw({{ $u->id }}, '{{ str_replace("'", "\'", $u->name) }}')" title="Ganti Password">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
          </button>
          @if(!$u->isAdmin())
          <button type="button" class="ucs-btn ub-delete" onclick="hapusUser({{ $u->id }})" title="Hapus">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
          </button>
          @endif
        </div>
      </div>
    </div>
    @endforeach
  </div>
@else
  <div class="card"><div class="card-body" style="text-align:center;padding:40px;color:var(--ink3)">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:48px;height:48px;margin:0 auto 12px;opacity:.4"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
    <p>Tidak ada user {{ $rl }}</p>
  </div></div>
@endif

@if($users->hasPages())
<div class="pager" style="margin-top:16px">
  <span>Menampilkan {{ $users->firstItem() }}-{{ $users->lastItem() }} dari {{ $users->total() }}</span>
  <div class="pager-btns">{{ $users->onEachSide(2)->links('pagination::bootstrap-4') }}</div>
</div>
@endif

{{-- Create modals per role --}}
@foreach([['key' => $rk, 'label' => $rl]] as $rd)
<div class="modal-overlay" id="createModal{{ $rk }}">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Tambah {{ $rl }} Baru</span><button class="modal-close" onclick="closeModal('createModal{{ $rk }}')">✕</button></div>
    <form method="POST" action="{{ route('admin.users.store') }}">
      @csrf
      <input type="hidden" name="role" value="{{ $rk }}">
      <div class="modal-body">
        <div class="row2">
          <div class="form-group"><label class="form-label">Nama Lengkap *</label><input name="name" class="form-input" required></div>
          <div class="form-group"><label class="form-label">{{ $rk === 'siswa' ? 'NIS' : 'NIP' }}</label><input name="{{ $rk === 'siswa' ? 'nis' : 'nip' }}" class="form-input"></div>
        </div>
        <div class="form-group"><label class="form-label">Email *</label><input name="email" type="email" class="form-input" required></div>
        <div class="row2">
          <div class="form-group">
            <label class="form-label">Password *</label>
            <div style="position:relative">
              <input name="password" type="password" class="form-input" id="pwCreate" minlength="6" required style="padding-right:36px">
              <button type="button" onclick="togglePw('pwCreate',this)" style="position:absolute;right:6px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;padding:4px;color:var(--ink3);line-height:1">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px;display:block"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              </button>
            </div>
          </div>
          @if($rk === 'siswa')
          <div class="form-group"><label class="form-label">Kelas</label><select name="class_id" class="form-input"><option value="">-- Pilih --</option>@foreach($classes as $c)<option value="{{ $c->id }}">{{ $c->name }}</option>@endforeach</select></div>
          @endif
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('createModal{{ $rk }}')">Batal</button>
        <button type="submit" class="btn btn-primary">Buat Akun</button>
      </div>
    </form>
  </div>
</div>
@endforeach

<style>
.user-card-sm {
  background:var(--surface);border:1px solid var(--border);border-radius:12px;
  padding:14px;
  transition:box-shadow .2s;
}
.user-card-sm:hover { box-shadow:0 3px 12px rgba(0,0,0,.06); }
.ucs-head { display:flex;align-items:center;gap:12px; }
.ucs-av { width:40px;height:40px;border-radius:10px;display:grid;place-items:center;font-size:14px;font-weight:700;flex-shrink:0; }
.ucs-info { flex:1;min-width:0; }
.ucs-name { font-size:13.5px;font-weight:600;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis; }
.ucs-email { font-size:11px;color:var(--ink3);margin-top:1px; }
.ucs-meta { font-size:10.5px;color:var(--ink2);margin-top:2px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis; }
.ucs-actions { display:flex;align-items:center;gap:0;flex-shrink:0; }
.ucs-btn {
  width:32px;height:32px;border:1px solid transparent;background:transparent;
  cursor:pointer;border-radius:7px;
  display:grid;place-items:center;
  transition:all .12s;padding:0;
}
.ucs-btn svg { width:16px;height:16px; }
.ucs-btn:hover { background:var(--bg); }
.ub-edit { color:var(--navy); }
.ub-edit:hover { background:var(--navy-light); }
.ub-toggle { color:var(--ink3); }
.ub-toggle:hover { background:var(--bg); }
.ub-ganti { color:var(--amber); }
.ub-ganti:hover { background:var(--amber-light); }
.ub-delete { color:var(--red); }
.ub-delete:hover { background:var(--red-light); }
.ub-class { color:var(--navy); }
.ub-class:hover { background:var(--navy-light); }
/* Choices.js dalam modal */
#editKelasGuruGroup .choices { margin-top:4px; }
#editKelasGuruGroup .choices__inner { background:var(--surface);border-color:var(--border);border-radius:7px;min-height:auto;padding:3px 6px;font-size:13px; }
#editKelasGuruGroup .choices__input { font-size:13px;background:transparent;color:var(--ink); }
#editKelasGuruGroup .choices__list--multiple .choices__item { background:var(--navy);border-color:var(--navy);border-radius:5px;font-size:11px;padding:2px 8px; }
#editKelasGuruGroup .choices__list--dropdown { border-color:var(--border);border-radius:0 0 7px 7px;font-size:13px; }
#editKelasGuruGroup .choices__list--dropdown .choices__item--selectable.is-highlighted { background:var(--navy-light); }
</style>
@endif

{{-- Shared: Edit Modal --}}
<div class="modal-overlay" id="editModal">
  <div class="modal">
    <div class="modal-head"><span class="modal-title">Ubah User</span><button class="modal-close" onclick="closeModal('editModal')">✕</button></div>
    <form method="POST" id="editForm">
      @csrf @method('PUT')
      <div class="modal-body">
        <div class="form-group"><label class="form-label">Nama Lengkap</label><input name="name" id="editName" class="form-input" required></div>
        <div class="form-group"><label class="form-label">Email</label><input name="email" id="editEmail" type="email" class="form-input" required></div>
        <div class="row2">
          <div class="form-group"><label class="form-label">Role</label><select name="role" id="editRole" class="form-input"><option value="admin">Admin</option><option value="guru">Guru</option><option value="siswa">Siswa</option></select></div>
          <div class="form-group"><label class="form-label" id="editNipLabel">NIP</label><input name="nip" id="editNip" class="form-input"></div>
        </div>
        <div class="form-group" id="editKelasSiswaGroup" style="display:none">
          <label class="form-label">Kelas</label>
          <select name="class_id" class="form-input"><option value="">-- Tidak ada --</option>@foreach($classes as $c)<option value="{{ $c->id }}">{{ $c->name }} ({{ $c->subject }})</option>@endforeach</select>
        </div>
        <div class="form-group" id="editKelasGuruGroup" style="display:none">
          <label class="form-label">Kelas Diampu</label>
          <select name="class_ids[]" id="editKelasGuruSelect" multiple placeholder="Cari & pilih kelas…">@foreach($classes as $c)<option value="{{ $c->id }}">{{ $c->name }} · {{ $c->subject }}</option>@endforeach</select>
          <small style="color:var(--ink3);font-size:11px">Ketik untuk cari, pilih lebih dari satu</small>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('editModal')">Batal</button>
        <button type="submit" class="btn btn-primary">Simpan</button>
      </div>
    </form>
  </div>
</div>

{{-- Shared: Ganti Password Modal --}}
<div class="modal-overlay" id="gantiPasswordModal">
  <div class="modal" style="max-width:400px">
    <div class="modal-head"><span class="modal-title">Ganti Password</span><button class="modal-close" onclick="closeModal('gantiPasswordModal')">✕</button></div>
    <form method="POST" id="gantiPasswordForm">
      @csrf @method('PATCH')
      <div class="modal-body">
        <p style="font-size:13px;color:var(--ink2);margin-bottom:12px">Ganti password untuk: <strong id="gpName"></strong></p>
        <div class="form-group">
          <label class="form-label">Password Baru *</label>
          <div style="position:relative">
            <input name="password" type="password" class="form-input" id="gpPassword" minlength="8" required style="padding-right:36px" autocomplete="new-password">
            <button type="button" onclick="togglePw('gpPassword',this)" style="position:absolute;right:6px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;padding:4px;color:var(--ink3);line-height:1">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px;display:block"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            </button>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Konfirmasi Password *</label>
          <div style="position:relative">
            <input type="password" class="form-input" id="gpConfirm" minlength="8" required style="padding-right:36px" autocomplete="new-password" placeholder="Ketik ulang password">
            <button type="button" onclick="togglePw('gpConfirm',this)" style="position:absolute;right:6px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;padding:4px;color:var(--ink3);line-height:1">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px;display:block"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            </button>
          </div>
          <span id="gpError" style="color:var(--red);font-size:12px;display:none;margin-top:4px">Password tidak cocok.</span>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" onclick="closeModal('gantiPasswordModal')">Batal</button>
        <button type="submit" class="btn btn-primary" id="gpSubmitBtn">Simpan</button>
      </div>
    </form>
  </div>
</div>

{{-- Pindah Kelas via Ubah --}}
</div>

@push('scripts')
<script>
// ── Toggle Password Visibility ──
function togglePw(id, btn) {
  const inp = document.getElementById(id);
  if (!inp) return;
  const isPass = inp.type === 'password';
  inp.type = isPass ? 'text' : 'password';
  btn.innerHTML = isPass
    ? '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px;display:block"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>'
    : '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px;display:block"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
}

const allUsers = @json($users->items());

// ── Edit ──
let kelasChoices = null;
function openEdit(id) {
  const u = allUsers.find(x => x.id === id); if (!u) return;
  document.getElementById('editName').value = u.name;
  document.getElementById('editEmail').value = u.email;
  document.getElementById('editRole').value = u.role;
  document.getElementById('editNip').value = u.nip || u.nis || '';
  document.getElementById('editNipLabel').textContent = u.role === 'siswa' ? 'NIS' : 'NIP';
  const ksg = document.getElementById('editKelasSiswaGroup');
  const kgg = document.getElementById('editKelasGuruGroup');
  ksg.style.display = 'none';
  kgg.style.display = 'none';
  if (u.role === 'siswa') {
    ksg.style.display = 'block';
    ksg.querySelector('select').value = (u.enrolled_classes?.length) ? u.enrolled_classes[0].id : '';
  } else if (u.role === 'guru') {
    kgg.style.display = 'block';
    if (kelasChoices) kelasChoices.destroy();
    const sel = document.getElementById('editKelasGuruSelect');
    sel.querySelectorAll('option').forEach(o => o.selected = false);
    const gk = (u.class_rooms || []).map(c => c.id);
    sel.querySelectorAll('option').forEach(o => { if (gk.includes(parseInt(o.value))) o.selected = true; });
    kelasChoices = new Choices(sel, {removeItemButton:true, searchEnabled:true, placeholder:true, placeholderValue:'Cari & pilih kelas…'});
  }

  document.getElementById('editForm').action = '/admin/users/' + u.id + '/update';
  openModal('editModal');
}

// ── Toggle ──
function toggleStatus(id) {
  document.getElementById('tf_' + id).submit();
}

	// ── Ganti Password (manual input modal) ──
	let gpUserId = null;
	function gantiPw(id, name) {
	  gpUserId = id;
	  document.getElementById('gpName').textContent = name || 'User #' + id;
	  document.getElementById('gpPassword').value = '';
	  document.getElementById('gpConfirm').value = '';
	  document.getElementById('gpError').style.display = 'none';
	  document.getElementById('gantiPasswordForm').action = '/admin/users/' + id + '/ganti-password';
	  openModal('gantiPasswordModal');
	  setTimeout(() => document.getElementById('gpPassword').focus(), 100);
	}
	document.getElementById('gantiPasswordForm').addEventListener('submit', function(e) {
	  const pw = document.getElementById('gpPassword').value;
	  const cf = document.getElementById('gpConfirm').value;
	  if (pw !== cf) {
	    e.preventDefault();
	    document.getElementById('gpError').style.display = 'block';
	    return;
	  }
	});

// ── Delete ──
function hapusUser(id) {
  if (!confirm('Hapus user ini? Tindakan tidak dapat dibatalkan.')) return;
  document.getElementById('df_' + id).submit();
}

// ── Pindah Kelas via Ubah ──
// Dihapus — pakai form Ubah yang sudah ada field kelas
</script>
@endpush

{{-- Hidden forms for CRUD actions --}}
@if(request('role'))
@foreach($users as $u)
<form method="POST" id="tf_{{ $u->id }}" action="{{ route('admin.users.toggle-status', $u) }}" style="display:none">@csrf @method('PATCH')</form>
<form method="POST" id="gf_{{ $u->id }}" action="{{ route('admin.users.ganti-password', $u) }}" style="display:none">@csrf @method('PATCH')</form>
@if(!$u->isAdmin())
<form method="POST" id="df_{{ $u->id }}" action="{{ route('admin.users.delete', $u) }}" style="display:none">@csrf @method('DELETE')</form>
@endif
@endforeach
@endif
@endSection

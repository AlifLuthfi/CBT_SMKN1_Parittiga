@extends('layouts.app')
@section('title', 'Login')
@section('content')
<style>
body{background:var(--bg);display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px;margin:0}
.login-card{background:var(--surface);border-radius:12px;box-shadow:0 2px 12px rgba(0,0,0,.08),0 0 0 1px var(--border);width:100%;max-width:440px;overflow:hidden}
.card-header{background:var(--navy);padding:28px 32px 24px;display:flex;align-items:center;gap:14px}
.header-icon{width:44px;height:44px;background:rgba(255,255,255,.15);border-radius:8px;display:grid;place-items:center;flex-shrink:0}
.header-icon svg{width:22px;height:22px;fill:white}
.header-title{font-size:18px;font-weight:700;color:#fff;line-height:1.2}
.header-sub{font-size:12px;color:rgba(255,255,255,.6);margin-top:2px;text-transform:uppercase;letter-spacing:.5px}
.card-body{padding:28px 32px 32px}
.welcome-text{font-size:22px;font-weight:700;color:var(--ink);margin-bottom:4px}
.welcome-sub{font-size:13px;color:var(--ink3);margin-bottom:24px}
.form-group{margin-bottom:16px}
.form-label{display:block;font-size:12px;font-weight:600;color:var(--ink2);margin-bottom:6px;letter-spacing:.2px}
.input-wrap{position:relative}
.input-icon{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--ink3)}
.input-icon svg{width:16px;height:16px}
.login-input{width:100%;padding:10px 44px 10px 38px;border:1.5px solid var(--border);border-radius:8px;font-family:'Inter',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;transition:border-color .18s,box-shadow .18s}
.login-input:focus{border-color:var(--navy);box-shadow:0 0 0 3px rgba(26,60,110,.1)}
.login-input::placeholder{color:var(--ink3)}
.pw-toggle{position:absolute;right:12px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--ink3);padding:2px}
.pw-toggle{position:absolute;right:8px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;padding:6px;z-index:2;display:grid;place-items:center;border-radius:6px}
.pw-toggle:hover{background:var(--bg)}
.pw-toggle svg{width:20px;height:20px;display:block}
.form-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px}
.checkbox-label{display:flex;align-items:center;gap:7px;font-size:12.5px;color:var(--ink2);cursor:pointer}
.checkbox-label input{accent-color:var(--navy);width:14px;height:14px}
.btn-submit{width:100%;padding:12px;background:var(--navy);color:#fff;border:none;border-radius:8px;font-family:'Inter',sans-serif;font-size:14px;font-weight:600;cursor:pointer;transition:background .18s;display:flex;align-items:center;justify-content:center;gap:8px}
.btn-submit:hover{background:var(--navy-dark)}
.btn-submit:disabled{background:var(--ink3);cursor:not-allowed}
.spinner{width:16px;height:16px;border:2.5px solid rgba(255,255,255,.3);border-top-color:#fff;border-radius:50%;animation:spin .7s linear infinite;display:none}
@keyframes spin{to{transform:rotate(360deg)}}
.alert-box{display:none;padding:10px 13px;border-radius:8px;font-size:13px;margin-bottom:14px;align-items:center;gap:8px;border:1.5px solid}
.alert-box.show{display:flex}
.alert-err{background:var(--red-light);border-color:rgba(198,40,40,.2);color:var(--red)}
.alert-ok{background:var(--green-light);border-color:rgba(46,125,50,.2);color:var(--green)}
.alert-box svg{width:14px;height:14px;flex-shrink:0}
.demo-btn{display:flex;align-items:center;gap:10px;padding:10px 14px;border-radius:10px;border:1.5px solid var(--border);background:var(--surface);cursor:pointer;font-family:'Inter',sans-serif;font-size:12.5px;color:var(--ink2);transition:all .2s cubic-bezier(.34,1.56,.64,1);text-align:left;width:100%}
.demo-btn:hover{background:#f7f9fc;border-color:var(--border2);transform:translateY(-1.5px);box-shadow:0 4px 14px rgba(0,0,0,.06)}
.demo-btn:active{transform:translateY(0)}
.demo-avatar{width:30px;height:30px;border-radius:7px;display:grid;place-items:center;font-size:12px;font-weight:700;color:#fff;flex-shrink:0}
.demo-info{flex:1;min-width:0}
.demo-name{display:block;font-size:12.5px;font-weight:600;color:var(--ink);margin-bottom:1px}
.demo-sub{font-size:10.5px;color:var(--ink3)}
.demo-arrow{font-size:13px;color:var(--ink3);transition:transform .2s}
.demo-btn:hover .demo-arrow{transform:translateX(3px)}
</style>

<div class="login-card">
  <div class="card-header">
    <div class="header-icon" style="overflow:hidden;padding:0"><img src="{{ asset('images/logo.png') }}" alt="Logo SMKN 1 Parittiga" style="width:100%;height:100%;object-fit:contain"></div>
    <div><div class="header-title">CBT SMKN 1 Parittiga</div><div class="header-sub">Sistem Manajemen Ujian</div></div>
  </div>

  <div class="card-body">
    <div class="welcome-text">Selamat Datang</div>
    <div class="welcome-sub">Masuk ke akun Anda untuk melanjutkan</div>

    <div class="alert-box alert-err" id="alert-err">
      <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
      <span id="alert-err-msg">Email atau password salah.</span>
    </div>

    <form method="POST" action="{{ route('login') }}" id="loginForm">
      @csrf
      <div class="form-group">
        <label class="form-label">Alamat Email</label>
        <div class="input-wrap">
          <span class="input-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,12 2,6"/></svg></span>
          <input class="login-input" name="email" type="email" placeholder="nama@sekolah.id" value="{{ old('email') }}" required autofocus>
        </div>
        @error('email') <p style="color:var(--red);font-size:12px;margin-top:4px">{{ $message }}</p> @enderror
      </div>

      <div class="form-group">
        <label class="form-label">Password</label>
        <div class="input-wrap">
          <span class="input-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg></span>
          <input class="login-input" name="password" type="password" placeholder="••••••••" required>
          <button type="button" class="pw-toggle" onclick="togglePw()"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" id="eye-icon"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg></button>
        </div>
        @error('password') <p style="color:var(--red);font-size:12px;margin-top:4px">{{ $message }}</p> @enderror
      </div>

<button type="submit" class="btn-submit" id="btn-submit">
        <div class="spinner" id="spinner"></div>
        <span id="btn-text">Masuk ke Sistem</span>
      </button>
    </form>

    {{-- DEMO ACCOUNTS --}}
    <div style="display:flex;align-items:center;gap:10px;margin:18px 0">
      <span style="flex:1;height:1px;background:var(--border)"></span>
      <span style="font-size:11px;color:var(--ink3);text-transform:uppercase;letter-spacing:.5px;font-weight:600">Akun Demo</span>
      <span style="flex:1;height:1px;background:var(--border)"></span>
    </div>

    <div style="display:flex;flex-direction:column;gap:6px">
      <button type="button" class="demo-btn" data-email="admin@examcore.id" data-pass="password123">
        <span class="demo-avatar" style="background:#0f766e">A</span>
        <span class="demo-info"><span class="demo-name">Administrator</span><span class="demo-sub">admin@examcore.id &middot; Admin</span></span>
        <span class="demo-arrow">&rarr;</span>
      </button>
      <button type="button" class="demo-btn" data-email="guru@examcore.id" data-pass="password123">
        <span class="demo-avatar" style="background:var(--navy)">G</span>
        <span class="demo-info"><span class="demo-name">Budi Santoso</span><span class="demo-sub">guru@examcore.id &middot; Guru</span></span>
        <span class="demo-arrow">&rarr;</span>
      </button>
      <button type="button" class="demo-btn" data-email="ahmadnaufal@siswa.id" data-pass="password123">
        <span class="demo-avatar" style="background:var(--orange)">S</span>
        <span class="demo-info"><span class="demo-name">Ahmad Naufal</span><span class="demo-sub">ahmadnaufal@siswa.id &middot; Siswa</span></span>
        <span class="demo-arrow">&rarr;</span>
      </button>
    </div>

    <p style="text-align:center;font-size:11px;color:var(--ink3);margin-top:24px">&copy; {{ date('Y') }} CBT SMKN 1 Parittiga</p>
  </div>
</div>

<script>
function togglePw() {
  const p = document.querySelector('[name="password"]');
  const ico = document.getElementById('eye-icon');
  if (p.type === 'password') {
    p.type = 'text';
    ico.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/>';
  } else {
    p.type = 'password';
    ico.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
  }
}
document.getElementById('loginForm')?.addEventListener('submit', function() {
  document.getElementById('btn-text').style.display = 'none';
  document.getElementById('spinner').style.display = 'block';
  document.getElementById('btn-submit').disabled = true;
});

// Demo account auto-fill — isi form saja, submit manual
document.querySelectorAll('.demo-btn').forEach(btn => {
  btn.addEventListener('mouseenter', function() { this.style.borderColor = 'var(--navy)'; this.style.background = 'rgba(26,60,110,.04)'; });
  btn.addEventListener('mouseleave', function() { this.style.borderColor = 'var(--border)'; this.style.background = 'transparent'; });
  btn.addEventListener('click', function() {
    document.querySelector('[name="email"]').value = this.dataset.email;
    document.querySelector('[name="password"]').value = this.dataset.pass;
    document.querySelector('[name="email"]').focus();
  });
});
</script>
@endSection
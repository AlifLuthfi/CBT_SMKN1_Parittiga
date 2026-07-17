<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="csrf-token" content="{{ csrf_token() }}">
<title>@yield('title', 'Ujian') — CBT SMKN 1 Parittiga</title>
<link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
:root{
  --navy:#1a3c6e;--navy-dark:#122a52;--navy-light:#e8eef7;
  --orange:#e8821a;--orange-light:#fff4e8;
  --bg:#f0f2f5;--surface:#ffffff;--border:#e2e6ea;--border2:#d1d8e0;
  --ink:#1a2332;--ink2:#4a5568;--ink3:#9aa5b4;--ink4:#c9d3dc;
  --green:#2e7d32;--green-light:#e8f5e9;
  --red:#c62828;--red-light:#ffebee;
  --amber:#f59e0b;--amber-light:#fffbeb;
  --sky:#0369a1;--sky-light:#e0f2fe;
  --violet:#5b21b6;--violet-light:#f5f3ff;
}
body{font-family:'Inter',sans-serif;background:var(--bg);color:var(--ink);min-height:100vh;overflow-x:hidden}
.content{max-width:820px;margin:0 auto;padding:20px 16px 40px}
.card{background:var(--surface);border:1px solid var(--border);border-radius:10px;overflow:hidden}
.card-body{padding:16px 18px}
.btn{display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:9px 18px;border-radius:9px;font-family:'Inter',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .22s cubic-bezier(.34,1.56,.64,1);border:none;text-decoration:none;line-height:1.2;box-shadow:0 1px 2px rgba(0,0,0,.04)}
.btn:hover{transform:translateY(-1.5px);box-shadow:0 6px 16px rgba(0,0,0,.1)}
.btn-primary{background:linear-gradient(135deg,var(--navy) 0%,#234b82 100%);color:#fff}
.btn-ghost{border:1.5px solid var(--border);background:var(--surface);color:var(--ink2)}
.btn-danger{background:linear-gradient(135deg,var(--red) 0%,#d32f2f 100%);color:#fff}
.btn-sm{padding:5px 12px;font-size:12px;border-radius:7px}
.btn svg{width:15px;height:15px;flex-shrink:0}
.invisible{visibility:hidden}
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.3);backdrop-filter:blur(3px);z-index:500;display:none;place-items:center;padding:20px}
.modal-overlay.open{display:grid}
.modal{background:var(--surface);border-radius:12px;border:1px solid var(--border);width:100%;max-width:410px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.15);animation:mi .2s ease}
@keyframes mi{from{opacity:0;transform:scale(.97)}to{opacity:1;transform:none}}
.modal-body{padding:20px;max-height:80vh;overflow-y:auto}
.form-input{width:100%;padding:9px 12px;border:1.5px solid var(--border);border-radius:7px;font-family:'Inter',sans-serif;font-size:13px;color:var(--ink);outline:none;background:var(--surface);transition:border-color .18s}
.form-input:focus{border-color:var(--navy);box-shadow:0 0 0 3px rgba(26,60,110,.1)}
::-webkit-scrollbar{width:5px;height:5px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:var(--border2);border-radius:3px}
</style>
@stack('styles')
</head>
<body>
<div class="content">
  @yield('content')
</div>
@stack('scripts')
</body>
</html>

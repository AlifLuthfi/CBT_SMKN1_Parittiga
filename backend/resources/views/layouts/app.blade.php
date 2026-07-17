<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="csrf-token" content="{{ csrf_token() }}">
<title>@yield('title', 'CBT SMKN 1 Parittiga') — Sistem Ujian</title>
<link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
<link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/clockpicker/0.0.7/bootstrap-clockpicker.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/styles/choices.min.css">
<style>
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
:root{
  --navy:#1a3c6e;--navy-dark:#122a52;--navy-light:#e8eef7;
  --orange:#e8821a;--orange-light:#fff4e8;
  --bg:#f0f2f5;--surface:#ffffff;--border:#e2e6ea;--border2:#d1d8e0;
  --ink:#1a2332;--ink2:#4a5568;--ink3:#9aa5b4;--ink4:#c9d3dc;
  --green:#2e7d32;--green-light:#e8f5e9;--green-mid:rgba(46,125,50,.12);
  --red:#c62828;--red-light:#ffebee;--red-mid:rgba(198,40,40,.12);
  --amber:#f59e0b;--amber-light:#fffbeb;
  --sky:#0369a1;--sky-light:#e0f2fe;
  --violet:#5b21b6;--violet-light:#f5f3ff;
  --sidebar-w:220px;--topbar-h:60px;
}
body{font-family:'Inter',sans-serif;background:var(--bg);color:var(--ink);min-height:100vh;display:flex;overflow-x:hidden}

/* ── Skeleton loading ── */
@keyframes shimmer{0%{background-position:-600px 0}100%{background-position:600px 0}}
.sk{background:linear-gradient(90deg,#e8ebef 25%,#f4f6f8 50%,#e8ebef 75%);background-size:600px 100%;animation:shimmer 1.4s ease-in-out infinite;border-radius:6px}
.sk-text{height:14px;margin-bottom:8px}.sk-text.sm{height:11px}.sk-text.lg{height:22px}

/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar-w);background:var(--surface);border-right:1px solid var(--border);position:fixed;top:0;left:0;bottom:0;z-index:100;display:flex;flex-direction:column;overflow-y:auto;transition:transform .25s}
.sidebar-brand{display:flex;align-items:center;gap:11px;padding:0 18px;height:var(--topbar-h);border-bottom:1px solid var(--border);flex-shrink:0}
.brand-icon{width:36px;height:36px;background:var(--navy);border-radius:8px;display:grid;place-items:center;flex-shrink:0}
.brand-icon svg{width:18px;height:18px;fill:white}
.brand-name{font-size:15px;font-weight:700;color:var(--ink)}
.brand-sub{font-size:9.5px;font-weight:500;color:var(--ink3);text-transform:uppercase;letter-spacing:.5px;margin-top:1px}

.nav-section{padding:16px 10px 0}
.nav-label{font-size:9.5px;font-weight:700;text-transform:uppercase;letter-spacing:.8px;color:var(--ink3);padding:0 8px;margin-bottom:5px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 10px;border-radius:7px;font-size:13px;font-weight:500;color:var(--ink2);cursor:pointer;transition:all .15s;border:none;background:transparent;width:100%;text-align:left;font-family:'Inter',sans-serif;margin-bottom:1px;text-decoration:none}
.nav-item:hover{background:var(--bg);color:var(--ink)}
.nav-item.active{background:var(--navy-light);color:var(--navy);font-weight:600}
.nav-item svg{width:15px;height:15px;flex-shrink:0}
.nav-badge{margin-left:auto;font-size:10px;font-weight:700;padding:1px 7px;border-radius:10px;background:var(--red);color:#fff}
.nav-badge.warn{background:var(--amber)}

.sidebar-footer{margin-top:auto;border-top:1px solid var(--border);padding:14px;flex-shrink:0}
.user-info{display:flex;align-items:center;gap:10px;padding:8px;border-radius:8px}
.user-avatar{width:34px;height:34px;background:var(--navy);border-radius:8px;display:grid;place-items:center;font-size:13px;font-weight:700;color:#fff;flex-shrink:0}
.user-name{font-size:13px;font-weight:600;color:var(--ink)}
.user-role{font-size:11px;color:var(--ink3)}
.logout-link{display:flex;align-items:center;gap:8px;padding:7px 8px;border-radius:6px;font-size:12px;color:var(--ink3);cursor:pointer;transition:all .15s;border:none;background:transparent;width:100%;margin-top:2px;font-family:'Inter',sans-serif;text-decoration:none}
.logout-link:hover{background:var(--red-light);color:var(--red)}
.logout-link svg{width:14px;height:14px}
.hamburger{display:none;width:36px;height:36px;border-radius:8px;border:1px solid var(--border);background:transparent;cursor:pointer;place-items:center;color:var(--ink2);margin-right:8px}
.hamburger svg{width:18px;height:18px}

/* ── MAIN ── */
.main{margin-left:var(--sidebar-w);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:var(--topbar-h);background:var(--surface);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 24px;gap:8px;position:sticky;top:0;z-index:50}
.topbar-brand{display:flex;align-items:center;gap:10px}
.topbar-app{font-size:15px;font-weight:700;color:var(--ink)}
.topbar-role-badge{display:inline-flex;align-items:center;padding:2px 10px;border-radius:20px;font-size:11px;font-weight:600;background:var(--navy-light);color:var(--navy)}
.topbar-greeting{font-size:13px;color:var(--ink2);display:flex;align-items:center;gap:6px}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:8px}

/* ── Content ── */
.content{padding:22px 24px;flex:1}
.page-heading{margin-bottom:20px;display:flex;align-items:flex-start;justify-content:space-between;gap:16px;flex-wrap:wrap}
.page-title{font-size:22px;font-weight:700;color:var(--ink)}
.page-sub{font-size:13px;color:var(--ink3);margin-top:2px}
.ph-actions{display:flex;gap:8px;flex-shrink:0}

/* ── Stat cards ── */
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:20px}
.stats-row-3{grid-template-columns:repeat(3,1fr)}
.stat-card{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:20px 22px;border-left:5px solid;transition:box-shadow .2s,transform .2s}
.stat-card:hover{box-shadow:0 4px 18px rgba(0,0,0,.08);transform:translateY(-1px)}
.stat-card.orange{border-left-color:var(--orange)}.stat-card.navy{border-left-color:var(--navy)}
.stat-card.green{border-left-color:var(--green)}.stat-card.red{border-left-color:var(--red)}
.stat-card.sky{border-left-color:var(--sky)}.stat-card.amber{border-left-color:var(--amber)}
.stat-card.violet{border-left-color:var(--violet)}
.sc-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}
.sc-label{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--ink3)}
.sc-status{font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.4px}
.sc-status.active{color:var(--green)}.sc-status.info{color:var(--sky)}.sc-status.warn{color:var(--orange)}.sc-status.danger{color:var(--red)}
.sc-value{font-size:36px;font-weight:700;color:var(--ink);line-height:1;margin-bottom:6px;font-variant-numeric:tabular-nums}
.sc-change{font-size:12px;color:var(--ink3);display:flex;align-items:center;gap:5px}
.sc-change svg{width:13px;height:13px}

/* ── Grid ── */
.grid-main{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px}
.grid-main-3{grid-template-columns:1fr 1fr 1fr}

/* ── Card ── */
.card{background:var(--surface);border:1px solid var(--border);border-radius:10px;overflow:hidden}
.card-head{display:flex;align-items:center;justify-content:space-between;padding:14px 18px;border-bottom:1px solid var(--border)}
.card-title{font-size:14px;font-weight:600;color:var(--ink);display:flex;align-items:center;gap:8px}
.card-title svg{width:15px;height:15px;color:var(--ink3);flex-shrink:0}
.card-action{font-size:12px;font-weight:500;color:var(--navy);text-decoration:none;cursor:pointer;background:none;border:none;font-family:'Inter',sans-serif}
.card-action:hover{text-decoration:underline}
.card-body{padding:16px 18px}

/* ── Table ── */
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:13px}
thead tr{background:#f7f9fc}
th{padding:10px 14px;text-align:left;font-size:10.5px;font-weight:700;letter-spacing:.6px;text-transform:uppercase;color:var(--ink3);border-bottom:1.5px solid var(--border);white-space:nowrap}
th.right,td.right{text-align:right}th.center,td.center{text-align:center}
td{padding:12px 14px;border-bottom:1px solid var(--border);color:var(--ink2);vertical-align:middle}
tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#f9fafc}
.td-main{color:var(--ink);font-weight:500}
.td-sm{font-size:12px;color:var(--ink3)}

/* ── Badge ── */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;white-space:nowrap}
.b-green{background:var(--green-light);color:var(--green)}
.b-orange{background:var(--orange-light);color:var(--orange)}
.b-red{background:var(--red-light);color:var(--red)}
.b-sky{background:var(--sky-light);color:var(--sky)}
.b-navy{background:var(--navy-light);color:var(--navy)}
.b-gray{background:var(--bg);color:var(--ink3)}
.b-amber{background:var(--amber-light);color:#92400e}

/* ── Buttons ── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:9px 18px;border-radius:9px;font-family:'Inter',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .22s cubic-bezier(.34,1.56,.64,1);border:none;text-decoration:none;line-height:1.2;box-shadow:0 1px 2px rgba(0,0,0,.04);position:relative;overflow:hidden}
.btn::after{content:'';position:absolute;inset:0;background:transparent;transition:background .22s}
.btn:hover{transform:translateY(-1.5px);box-shadow:0 6px 16px rgba(0,0,0,.1)}
.btn:active{transform:translateY(0);box-shadow:0 1px 3px rgba(0,0,0,.08)}
.btn-primary{background:linear-gradient(135deg,var(--navy) 0%,#234b82 100%);color:#fff}
.btn-primary:hover{box-shadow:0 6px 20px rgba(26,60,110,.35)}
.btn-ghost{border:1.5px solid var(--border);background:var(--surface);color:var(--ink2)}
.btn-ghost:hover{background:#f7f9fc;color:var(--ink);border-color:var(--border2);box-shadow:0 4px 12px rgba(0,0,0,.06)}
.btn-danger{background:linear-gradient(135deg,var(--red) 0%,#d32f2f 100%);color:#fff}
.btn-danger:hover{box-shadow:0 6px 20px rgba(198,40,40,.35)}
.btn-outline-danger{border:1.5px solid var(--red);background:transparent;color:var(--red)}
.btn-outline-danger:hover{background:var(--red-light);box-shadow:0 4px 12px rgba(198,40,40,.15);border-color:var(--red)}
.btn-sm{padding:5px 12px;font-size:12px;border-radius:7px}
.btn-sm:hover{transform:translateY(-1px)}
.btn svg{width:15px;height:15px;flex-shrink:0;transition:transform .25s cubic-bezier(.34,1.56,.64,1)}
.btn:hover svg{transform:scale(1.12) rotate(-3deg)}
.btn-primary:hover svg,.btn-danger:hover svg{filter:brightness(1.2)}
.icon-btn{width:32px;height:32px;border-radius:8px;border:1.5px solid var(--border);background:var(--surface);color:var(--ink3);cursor:pointer;display:inline-grid;place-items:center;transition:all .2s cubic-bezier(.34,1.56,.64,1);text-decoration:none;box-shadow:0 1px 2px rgba(0,0,0,.04)}
.icon-btn svg{width:14px;height:14px;transition:transform .25s cubic-bezier(.34,1.56,.64,1),color .2s}
.icon-btn:hover{background:#f7f9fc;color:var(--ink);border-color:var(--border2);transform:translateY(-2px) scale(1.05);box-shadow:0 5px 14px rgba(0,0,0,.08)}
.icon-btn:hover svg{transform:scale(1.2)}
.icon-btn.danger:hover{background:var(--red-light);color:var(--red);border-color:rgba(198,40,40,.3);box-shadow:0 4px 12px rgba(198,40,40,.15)}
.icon-btn.danger:hover svg{transform:scale(1.2) rotate(2deg)}

/* ── Back link ── */
.back-link{display:inline-flex;align-items:center;gap:6px;font-size:13px;font-weight:500;color:var(--navy);text-decoration:none;padding:5px 10px;border-radius:7px;transition:all .2s;margin-bottom:16px}
.back-link:hover{background:var(--navy-light);gap:8px}
.back-link svg{width:14px;height:14px;transition:transform .2s}
.back-link:hover svg{transform:translateX(-3px)}

/* ── Forms ── */
.form-group{margin-bottom:14px}
.form-label{display:block;font-size:12px;font-weight:600;color:var(--ink2);margin-bottom:5px}
.form-input{width:100%;padding:9px 12px;border:1.5px solid var(--border);border-radius:7px;font-family:'Inter',sans-serif;font-size:13px;color:var(--ink);outline:none;background:var(--surface);transition:border-color .18s}
.form-input:focus{border-color:var(--navy);box-shadow:0 0 0 3px rgba(26,60,110,.1)}
.form-input::placeholder{color:var(--ink3)}
select.form-input{appearance:auto;cursor:pointer}
textarea.form-input{resize:vertical;min-height:60px}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:12px}

/* Time/date highlight when filled */
.time-wrap.has-time .form-input.fp-time,
.date-wrap.has-date .form-input[type="date"]{background:var(--navy-light);border-color:rgba(26,60,110,.3);font-weight:600}

/* Clock icon trigger — wrapped with input */
.input-icon-wrap{position:relative;display:flex;align-items:center}
.input-icon-wrap .form-input{padding-right:34px!important;cursor:pointer}
.input-icon-wrap .clock-trigger{position:absolute;right:10px;top:50%;transform:translateY(-50%);width:18px;height:18px;color:var(--ink3);cursor:pointer;pointer-events:auto;transition:color .15s;flex-shrink:0}
.input-icon-wrap .clock-trigger:hover{color:var(--navy)}
.time-wrap.has-time .clock-trigger{color:var(--navy);opacity:.85}

/* ── ClockPicker custom theme (navy) ── */
.clockpicker-popover{z-index:99999!important;border:1px solid var(--border);border-radius:10px;box-shadow:0 8px 30px rgba(0,0,0,.15);font-family:'Inter',sans-serif;margin-top:4px!important}
.clockpicker-popover.popover{position:fixed!important}
.clockpicker-popover .popover-content{background:var(--surface);border-radius:10px;padding:16px}
.clockpicker-plate{background:var(--bg);border-radius:50%}
.clockpicker-tick{color:var(--ink2);font-weight:600;font-size:13px}
.clockpicker-tick:hover{background:var(--navy-light);color:var(--navy);border-radius:50%}
.clockpicker-canvas line{stroke:var(--navy)!important}
.clockpicker-canvas-bg{fill:rgba(26,60,110,.12)!important}
.clockpicker-canvas-bearing{fill:var(--navy)!important}
.clockpicker-canvas-fg{fill:var(--navy)!important}
.clockpicker-button{color:var(--navy);font-weight:600;font-size:13px;padding:10px 16px;border-radius:0 0 10px 10px;background:var(--surface);border:none;cursor:pointer;transition:background .15s}
.clockpicker-button:hover{background:var(--navy-light)}
.clockpicker-button.clockpicker-button-clear{color:var(--red);float:left}
.clockpicker-popover .popover-arrow{display:none}
.checkbox-label{display:flex;align-items:center;gap:7px;font-size:12.5px;color:var(--ink2);cursor:pointer}
.checkbox-label input{accent-color:var(--navy);width:14px;height:14px}

/* ── Modal ── */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.3);backdrop-filter:blur(3px);z-index:500;display:none;place-items:center;padding:20px}
.modal-overlay.open{display:grid}
.modal{background:var(--surface);border-radius:12px;border:1px solid var(--border);width:100%;max-width:530px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.15);animation:mi .2s ease}
@keyframes mi{from{opacity:0;transform:scale(.97)}to{opacity:1;transform:none}}
.modal-head{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;background:#f7f9fc}
.modal-title{font-size:15px;font-weight:700;color:var(--ink)}
.modal-close{width:28px;height:28px;border-radius:6px;border:1px solid var(--border);background:var(--surface);color:var(--ink3);cursor:pointer;display:grid;place-items:center;font-size:14px;font-family:'Inter',sans-serif}
.modal-close:hover{background:var(--bg)}
.modal-body{padding:20px;max-height:80vh;overflow-y:auto}
.modal-footer{padding:14px 20px;border-top:1px solid var(--border);display:flex;gap:8px;justify-content:flex-end;background:#f7f9fc}

/* ── Pagination ── */
.pager{display:flex;align-items:center;justify-content:space-between;padding:11px 16px;border-top:1px solid var(--border);font-size:12px;color:var(--ink3)}
.pager:has(.pager-btns:only-child){justify-content:center}
.pager:has(.pager-btns:only-child) .pager-btns{margin:0 auto}
.pager-btns{display:flex;gap:3px}
.pager-btn{width:28px;height:28px;border-radius:6px;border:1px solid var(--border);background:transparent;color:var(--ink2);cursor:pointer;display:grid;place-items:center;font-size:12px;font-family:'Inter',sans-serif;transition:all .15s;text-decoration:none}
.pager-btn:hover{background:var(--bg)}
.pager-btn.active{background:var(--navy);color:#fff;border-color:var(--navy)}
.pager-btn:disabled{opacity:.4;cursor:not-allowed}

/* ── Toast ── */
.toast{position:fixed;bottom:24px;left:50%;transform:translateX(-50%) translateY(80px);background:var(--ink);color:#fff;padding:10px 18px;border-radius:8px;font-size:13px;display:flex;align-items:center;gap:8px;z-index:999;transition:transform .35s cubic-bezier(.34,1.56,.64,1);box-shadow:0 4px 20px rgba(0,0,0,.2)}
.toast.show{transform:translateX(-50%) translateY(0)}
.toast.ok{background:var(--green)}.toast.err{background:var(--red)}
.toast svg{width:15px;height:15px}

/* ── Alert banner ── */
.alert-banner{display:flex;align-items:center;gap:12px;padding:12px 16px;border-radius:9px;margin-bottom:18px;font-size:13px;border:1.5px solid}
.ab-warn{background:var(--amber-light);border-color:rgba(245,158,11,.3);color:#92400e}
.ab-red{background:var(--red-light);border-color:rgba(198,40,40,.25);color:var(--red)}
.ab-info{background:var(--sky-light);border-color:rgba(3,105,161,.25);color:var(--sky)}
.alert-banner svg{width:16px;height:16px;flex-shrink:0}

/* ── Misc ── */
.u-chip{display:flex;align-items:center;gap:8px}
.u-av{width:30px;height:30px;border-radius:7px;display:grid;place-items:center;font-size:11px;font-weight:700;color:#fff;flex-shrink:0}
.flex{display:flex}.flex-1{flex:1}.gap-2{gap:8px}.gap-3{gap:12px}.gap-4{gap:16px}.items-center{align-items:center}.justify-between{justify-content:space-between}.justify-end{justify-content:flex-end}.text-center{text-align:center}.text-right{text-align:right}.w-full{width:100%}.mt-2{margin-top:8px}.mt-4{margin-top:16px}.mb-2{margin-bottom:8px}.mb-4{margin-bottom:16px}.mb-6{margin-bottom:24px}.inline{display:inline}.hidden{display:none}
.truncate{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.sys-row{display:flex;align-items:center;justify-content:space-between;padding:9px 0;border-bottom:1px solid var(--border);font-size:13px}
.sys-row:last-child{border-bottom:none}
.progress-row{display:flex;align-items:center;gap:10px;margin-bottom:10px}
.progress-row:last-child{margin-bottom:0}
.pr-label{font-size:12px;color:var(--ink2);width:80px;flex-shrink:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.pr-track{flex:1;height:8px;background:var(--bg);border-radius:4px;overflow:hidden}
.pr-fill{height:100%;border-radius:4px;transition:width .7s ease}
.pr-val{font-family:'JetBrains Mono',monospace;font-size:11.5px;color:var(--ink3);width:36px;text-align:right;flex-shrink:0}
::-webkit-scrollbar{width:5px;height:5px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:var(--border2);border-radius:3px}

/* ── Responsive ── */
@media(max-width:1100px){.stats-row{grid-template-columns:repeat(2,1fr)}.grid-main-3{grid-template-columns:1fr 1fr}}
@media(max-width:900px){
  .hamburger{display:grid}
  .sidebar{transform:translateX(-100%)}
  .sidebar.open{transform:translateX(0);box-shadow:4px 0 20px rgba(0,0,0,.1)}
  .main{margin-left:0}
  .stats-row{grid-template-columns:1fr 1fr}
  .grid-main,.grid-main-3,.row2{grid-template-columns:1fr}
}
</style>
@stack('styles')
</head>
<body>

@auth
@php $role = auth()->user()->role; $prefix = $role; @endphp

{{-- Sidebar overlay mobile --}}
<div class="modal-overlay" id="sidebarOverlay" onclick="toggleSidebar()" style="display:none;z-index:90"></div>

{{-- Sidebar --}}
<aside class="sidebar" id="sidebar">
  <div class="sidebar-brand">
    <div class="brand-icon" style="overflow:hidden;border-radius:8px;background:transparent">
      <img src="{{ asset('images/logo.png') }}" alt="Logo" style="width:100%;height:100%;object-fit:contain">
    </div>
    <div>
      <div class="brand-name">CBT SMKN 1 Parittiga</div>
      <div class="brand-sub">Manajemen Ujian</div>
    </div>
  </div>

  <div class="nav-section">
    <div class="nav-label">Menu Utama</div>
    <a href="{{ route('dashboard') }}" class="nav-item {{ request()->routeIs('dashboard') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>
      Dashboard
    </a>

    @if($role === 'admin')
    <a href="{{ route('admin.users') }}" class="nav-item {{ request()->routeIs('admin.users*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      Manajemen User
    </a>
    <a href="{{ route('admin.classes') }}" class="nav-item {{ request()->routeIs('admin.classes*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
      Kelas
    </a>
    <a href="{{ route('admin.exams') }}" class="nav-item {{ request()->routeIs('admin.exams*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
      Ujian
    </a>
    <a href="{{ route('admin.violations') }}" class="nav-item {{ request()->routeIs('admin.violations*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
      Pelanggaran
    </a>

    @elseif($role === 'guru')
    <a href="{{ route('guru.subjects') }}" class="nav-item {{ request()->routeIs('guru.subjects*') || request()->routeIs('guru.questions*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
      Input Soal
    </a>
    <a href="{{ route('guru.exams') }}" class="nav-item {{ request()->routeIs('guru.exams*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
      Jadwal Ujian
    </a>
    <a href="{{ route('guru.grade-reports') }}" class="nav-item {{ request()->routeIs('guru.grade-reports*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
      Rekap Nilai
    </a>

    @elseif($role === 'siswa')
    <a href="{{ route('siswa.exams') }}" class="nav-item {{ request()->routeIs('siswa.exams*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/></svg>
      Ujian Tersedia
    </a>
    <a href="{{ route('siswa.history') }}" class="nav-item {{ request()->routeIs('siswa.history*') ? 'active' : '' }}">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
      Riwayat Ujian
    </a>
    @endif
  </div>

  <div class="sidebar-footer">
    <div class="user-info">
      <div class="user-avatar">{{ substr(auth()->user()->name, 0, 1) }}</div>
      <div>
        <div class="user-name truncate">{{ auth()->user()->name }}</div>
        <div class="user-role capitalize">{{ auth()->user()->role }}</div>
      </div>
    </div>
    <form method="POST" action="{{ route('logout') }}" style="display:contents">
      @csrf
      <button type="submit" class="logout-link">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        Keluar
      </button>
    </form>
  </div>
</aside>

{{-- Main --}}
<main class="main">
  <header class="topbar">
    <button class="hamburger" onclick="toggleSidebar()">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
    </button>
    <div class="topbar-brand">
      <span class="topbar-app">@yield('page-title', 'Dashboard')</span>
      <span class="topbar-role-badge">{{ ucfirst($role) }}</span>
    </div>
    @if(request()->routeIs('dashboard'))
    <div class="topbar-greeting" style="margin-left:16px">
      <span>Selamat datang kembali, {{ explode(' ', auth()->user()->name)[0] }}</span>
    </div>
    @endif
  </header>

  <div class="content">
    @if(session('success'))
    <div class="alert-banner ab-info" style="margin-bottom:18px">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      <span>{{ session('success') }}</span>
    </div>
    @endif
    @if(session('error'))
    <div class="alert-banner ab-red" style="margin-bottom:18px">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
      <span>{{ session('error') }}</span>
    </div>
    @endif
    @yield('content')
  </div>
</main>

<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/clockpicker/0.0.7/bootstrap-clockpicker.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/scripts/choices.min.js"></script>
<script>
function toggleSidebar() {
  var sb = document.getElementById('sidebar');
  var ov = document.getElementById('sidebarOverlay');
  sb.classList.toggle('open');
  ov.style.display = sb.classList.contains('open') ? 'block' : 'none';
}
function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
var toastTimer;
function showToast(msg, type) {
  var el = document.getElementById('toast');
  if (!el) return;
  document.getElementById('toast-msg').textContent = msg;
  var ico = document.getElementById('toast-icon');
  if (ico) {
    if (type==='err') ico.innerHTML = '<circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>';
    else ico.innerHTML = '<polyline points="20 6 9 17 4 12"/>';
  }
  el.className = 'toast' + (type ? ' ' + type : '') + ' show';
  clearTimeout(toastTimer);
  toastTimer = setTimeout(function() { el.classList.remove('show'); }, 3000);
}
document.addEventListener('DOMContentLoaded', function() {
  @if(session('success'))
    showToast('{{ session('success') }}', 'ok');
  @endif
  @if(session('error'))
    showToast('{{ session('error') }}', 'err');
  @endif
  document.querySelectorAll('.modal-overlay:not(#sidebarOverlay)').forEach(function(el) {
    el.addEventListener('click', function(e) { if (e.target === this) this.classList.remove('open'); });
  });

  // ClockPicker time picker
  var cptimes = document.querySelectorAll('.fp-time');
  for (var i = 0; i < cptimes.length; i++) {
    (function(el) {
      var cp = $(el).clockpicker({
        autoclose: true,
        donetext: 'Pilih',
        placement: 'bottom',
        align: 'left',
        afterHide: function() {
          var wrap = el.closest('.time-wrap');
          if (wrap) wrap.classList.toggle('has-time', !!el.value);
        },
      });
      var clock = el.parentElement ? el.parentElement.querySelector('.clock-trigger') : null;
      if (clock) {
        clock.addEventListener('click', function(e) {
          e.stopPropagation();
          $(el).clockpicker('show');
        });
      }
      // Set initial highlight
      var wrap = el.closest('.time-wrap');
      if (wrap) wrap.classList.toggle('has-time', !!el.value);
    })(cptimes[i]);
  }

  // Date input highlight
  var dateInputs = document.querySelectorAll('.form-input[type="date"]');
  for (var j = 0; j < dateInputs.length; j++) {
    (function(el) {
      el.addEventListener('change', function() {
        var wrap = el.closest('.date-wrap');
        if (wrap) wrap.classList.toggle('has-date', !!el.value);
      });
      var wrap = el.closest('.date-wrap');
      if (wrap) wrap.classList.toggle('has-date', !!el.value);
    })(dateInputs[j]);
  }
});
</script>

@stack('scripts')

{{-- Toast container --}}
<div class="toast" id="toast">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" id="toast-icon"><polyline points="20 6 9 17 4 12"/></svg>
  <span id="toast-msg"></span>
</div>

@endauth

@guest
  @yield('content')
@endguest

</body>
</html>

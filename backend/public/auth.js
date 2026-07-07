/* ═══════════════════════════════════════════════════════════════
   auth.js — ExamCore Shared Auth & API Helper
   Taruh file ini di folder public/ bersama semua file HTML
   Semua halaman cukup include: <script src="auth.js"></script>
═══════════════════════════════════════════════════════════════ */

/* ── Config ─────────────────────────────────────────────────── */
const EC = {
  get token()  { return localStorage.getItem('ec_token')  || ''; },
  get base()   { return (localStorage.getItem('ec_base')  || 'http://127.0.0.1:8000/api').replace(/\/$/, ''); },
  get role()   { return localStorage.getItem('ec_role')   || ''; },
  get user()   {
    try { return JSON.parse(localStorage.getItem('ec_user') || '{}'); }
    catch { return {}; }
  },
  save(token, user, base) {
    localStorage.setItem('ec_token', token);
    localStorage.setItem('ec_user',  JSON.stringify(user));
    localStorage.setItem('ec_role',  user.role || '');
    if (base) localStorage.setItem('ec_base', base);
  },
  clear() {
    ['ec_token','ec_user','ec_role'].forEach(k => localStorage.removeItem(k));
  }
};

/* ── API Helper ──────────────────────────────────────────────── */
async function api(method, path, body = null) {
  const res = await fetch(EC.base + path, {
    method,
    headers: {
      'Content-Type':  'application/json',
      'Accept':        'application/json',
      'Authorization': `Bearer ${EC.token}`,
    },
    body: body ? JSON.stringify(body) : null,
  });
  if (res.status === 401) { EC.clear(); window.location.href = 'login.html'; return null; }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.message || `HTTP ${res.status}`);
  return data;
}

/* ── Upload file (multipart) ─────────────────────────────────── */
async function apiUpload(path, formData, method = 'POST') {
  const res = await fetch(EC.base + path, {
    method,
    headers: { 'Authorization': `Bearer ${EC.token}`, 'Accept': 'application/json' },
    body: formData,
  });
  if (res.status === 401) { EC.clear(); window.location.href = 'login.html'; return null; }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.message || `HTTP ${res.status}`);
  return data;
}

/* ── Auth guard ──────────────────────────────────────────────── */
function requireAuth(role = null) {
  if (!EC.token) { window.location.href = 'login.html'; return false; }
  if (role && EC.role !== role && EC.role !== 'admin') { window.location.href = 'login.html'; return false; }
  return true;
}

/* ── Logout ──────────────────────────────────────────────────── */
async function logout() {
  try { await api('POST', '/auth/logout'); } catch(_) {}
  EC.clear();
  window.location.href = 'login.html';
}

/* ── Render nama user di elemen [data-user-name] ─────────────── */
function renderUser() {
  const u = EC.user;
  const nameEl   = document.querySelector('[data-user-name]');
  const roleEl   = document.querySelector('[data-user-role]');
  const avatarEl = document.querySelector('[data-user-avatar]');
  if (nameEl)   nameEl.textContent   = u.name  || 'Pengguna';
  if (roleEl)   roleEl.textContent   = u.role  || '';
  if (avatarEl) avatarEl.textContent = (u.name || 'U').charAt(0).toUpperCase();
}

/* ── Toast notifikasi ────────────────────────────────────────── */
function toast(msg, type = 'info') {
  let el = document.getElementById('_ec_toast');
  if (!el) {
    el = document.createElement('div');
    el.id = '_ec_toast';
    Object.assign(el.style, {
      position: 'fixed', bottom: '24px', left: '50%',
      transform: 'translateX(-50%) translateY(80px)',
      padding: '10px 20px', borderRadius: '8px',
      fontSize: '13px', fontFamily: "'Inter',sans-serif",
      display: 'flex', alignItems: 'center', gap: '8px',
      zIndex: '9999', transition: 'transform .3s cubic-bezier(.34,1.56,.64,1)',
      boxShadow: '0 4px 20px rgba(0,0,0,.2)', whiteSpace: 'nowrap',
      border: '1px solid transparent',
    });
    document.body.appendChild(el);
  }
  const cfg = {
    ok:   { bg: '#2e7d32', icon: '✓', color: '#fff' },
    err:  { bg: '#c62828', icon: '✗', color: '#fff' },
    warn: { bg: '#f59e0b', icon: '⚠', color: '#fff' },
    info: { bg: '#1a3c6e', icon: 'ℹ', color: '#fff' },
  };
  const c = cfg[type] || cfg.info;
  Object.assign(el.style, { background: c.bg, color: c.color });
  el.innerHTML = `<span>${c.icon}</span><span>${msg}</span>`;
  el.style.transform = 'translateX(-50%) translateY(0)';
  clearTimeout(el._t);
  el._t = setTimeout(() => { el.style.transform = 'translateX(-50%) translateY(80px)'; }, 3200);
}

/* ── Format tanggal Indonesia ────────────────────────────────── */
function formatDate(dateStr, withTime = false) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  const opts = { day: '2-digit', month: 'short', year: 'numeric' };
  if (withTime) { opts.hour = '2-digit'; opts.minute = '2-digit'; }
  return d.toLocaleDateString('id-ID', opts);
}

/* ── Format sisa waktu ───────────────────────────────────────── */
function timeAgo(dateStr) {
  if (!dateStr) return '—';
  const diff = Math.floor((Date.now() - new Date(dateStr)) / 1000);
  if (diff < 60)    return `${diff} dtk lalu`;
  if (diff < 3600)  return `${Math.floor(diff/60)} mnt lalu`;
  if (diff < 86400) return `${Math.floor(diff/3600)} jam lalu`;
  return `${Math.floor(diff/86400)} hari lalu`;
}

/* ── Konfirmasi modal ringan ─────────────────────────────────── */
function confirm(msg, cb) {
  const id = '_ec_confirm';
  let el = document.getElementById(id);
  if (!el) {
    el = document.createElement('div');
    el.id = id;
    el.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,.35);backdrop-filter:blur(3px);z-index:9998;display:none;place-items:center;padding:20px';
    el.innerHTML = `
      <div style="background:#fff;border-radius:12px;border:1px solid #e2e6ea;width:100%;max-width:380px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.15)">
        <div style="padding:16px 20px;border-bottom:1px solid #e2e6ea;font-size:15px;font-weight:700;color:#1a2332;font-family:Inter,sans-serif">Konfirmasi</div>
        <div style="padding:18px 20px;font-size:13.5px;color:#4a5568;font-family:Inter,sans-serif;line-height:1.6" id="_ec_confirm_msg"></div>
        <div style="padding:14px 20px;border-top:1px solid #e2e6ea;display:flex;gap:8px;justify-content:flex-end;background:#f7f9fc">
          <button onclick="document.getElementById('_ec_confirm').style.display='none'" style="padding:8px 16px;border-radius:7px;border:1px solid #e2e6ea;background:transparent;font-family:Inter,sans-serif;font-size:13px;cursor:pointer">Batal</button>
          <button id="_ec_confirm_btn" style="padding:8px 16px;border-radius:7px;border:none;background:#c62828;color:#fff;font-family:Inter,sans-serif;font-size:13px;font-weight:600;cursor:pointer">Ya, Lanjutkan</button>
        </div>
      </div>`;
    document.body.appendChild(el);
  }
  document.getElementById('_ec_confirm_msg').textContent = msg;
  document.getElementById('_ec_confirm_btn').onclick = () => { el.style.display = 'none'; cb(); };
  el.style.display = 'grid';
}

/* ── Sidebar nav active state ────────────────────────────────── */
function setNavActive(page) {
  document.querySelectorAll('.nav-item').forEach(n => {
    n.classList.toggle('active', n.dataset.page === page);
  });
}

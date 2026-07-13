<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CBT SMKN 1 Parittiga</title>
<link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
<link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Inter',sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center;
  background:linear-gradient(180deg,#0B2242 0%,#173A6A 100%);overflow:hidden}
.splash{text-align:center;animation:fi .8s ease forwards}
@keyframes fi{from{opacity:0;transform:translateY(20px) scale(.96)}to{opacity:1;transform:none}}
.logo-wrap{width:172px;height:172px;margin:0 auto;background:#fff;border-radius:28px;padding:24px;
  box-shadow:0 12px 40px rgba(0,0,0,.25);display:flex;align-items:center;justify-content:center}
.logo-wrap img{width:100%;height:100%;object-fit:contain;border-radius:12px}
h1{color:#fff;font-size:22px;font-weight:700;margin-top:22px;letter-spacing:.2px}
p{color:#B8D1F0;font-size:14px;margin-top:8px}
.bar{width:72px;height:3px;margin:28px auto 0;background:#193660;border-radius:2px;overflow:hidden}
.bar-inner{height:100%;width:100%;background:#fff;border-radius:2px;animation:shrink 1.2s ease-in-out forwards}
@keyframes shrink{0%{width:100%;transform:scaleX(1)}70%{width:100%;transform:scaleX(.15)}100%{width:0%;transform:scaleX(0)}}
</style>
</head>
<body>
<div class="splash">
  <div class="logo-wrap"><img src="{{ asset('images/logo.png') }}" alt="Logo SMKN 1 Parittiga"></div>
  <h1>SMKN 1 Parittiga</h1>
  <p>Sistem Ujian Online</p>
  <div class="bar"><div class="bar-inner"></div></div>
</div>

<script>
// Auto-redirect after animation completes
setTimeout(function() {
  window.location.href = '{{ $nextUrl }}';
}, 1800);
</script>
</body>
</html>

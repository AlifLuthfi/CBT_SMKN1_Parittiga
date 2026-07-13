import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/auth_repository.dart';

final _authRepoProvider = Provider((_) => AuthRepository());

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _urlCtrl   = TextEditingController();

  bool    _obscure      = true;
  bool    _loading      = false;
  bool    _showUrl      = false;
  bool    _biometricAvail = false;
  String? _errorMsg;

  final _demos = [
    {'name': 'Budi Santoso',  'email': 'guru@cbt.sch.id',     'role': 'guru',  'pass': 'password123'},
    {'name': 'Ahmad Naufal',  'email': 'ahmadnaufal@siswa.id', 'role': 'siswa', 'pass': 'password123'},
    {'name': 'Administrator', 'email': 'admin@cbt.sch.id',     'role': 'admin', 'pass': 'password123'},
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url   = await SecureStorage.getBaseUrl();
    final bioOk = await SecurityService.isBiometricAvailable();
    final bioEn = await SecureStorage.getBiometricEnabled();
    _urlCtrl.text = url;
    if (mounted) setState(() => _biometricAvail = bioOk && bioEn);

    // Security check
    final compromised = await SecurityService.isDeviceCompromised();
    if (compromised && mounted) {
      _showSecurityAlert();
    }
  }

  void _showSecurityAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Peringatan Keamanan'),
        content: const Text('Perangkat ini terdeteksi telah di-root/jailbreak. Penggunaan aplikasi di perangkat ini berisiko terhadap keamanan data ujian.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    if (_urlCtrl.text.trim().isNotEmpty) {
      final url = _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
      if (!SecurityService.isValidHost(url)) {
        setState(() { _errorMsg = 'URL server tidak valid atau tidak diizinkan.'; _loading = false; });
        return;
      }
      await ApiClient.updateBaseUrl(url);
    }

    try {
      final repo   = ref.read(_authRepoProvider);
      final result = await repo.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      _navigate(result.user.role);
    } on ApiException catch (e) {
      setState(() { _errorMsg = e.message; _loading = false; });
    } catch (e) {
      setState(() { _errorMsg = 'Tidak dapat terhubung ke server. Periksa URL dan jaringan.'; _loading = false; });
    }
  }

  Future<void> _loginWithBiometric() async {
    final ok = await SecurityService.authenticateWithBiometric(reason: 'Login ke CBT SMKN 1 Parittiga');
    if (!ok || !mounted) return;
    final token = await SecureStorage.getToken();
    final role  = await SecureStorage.getRole();
    if (token != null && role != null) {
      _navigate(role);
    } else {
      setState(() => _errorMsg = 'Sesi sebelumnya tidak ditemukan. Silakan login manual.');
    }
  }

  void _navigate(String role) {
    switch (role) {
      case 'guru':  context.go('/guru/dashboard');  break;
      case 'siswa': context.go('/siswa/dashboard'); break;
      case 'admin': context.go('/admin/dashboard'); break;
      default:      context.go('/guru/dashboard');
    }
  }

  void _fillDemo(Map<String, String> acc) {
    _emailCtrl.text = acc['email']!;
    _passCtrl.text  = acc['pass']!;
    setState(() => _errorMsg = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 28),
            // Logo
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                'assets/images/smk_parittiga_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.school, color: Colors.white, size: 30)),
              ),
            ),
            const SizedBox(height: 14),
            Text('CBT SMKN 1 Parittiga', style: AppTextStyles.h2),
            Text('Sistem Ujian Online', style: AppTextStyles.bodySmall),
            const SizedBox(height: 28),

            // Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 16, offset: const Offset(0,4))],
              ),
              child: Column(children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Masuk ke Sistem', style: AppTextStyles.h4.copyWith(color: Colors.white, fontSize: 15)),
                      Text('Sistem Manajemen Ujian', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                    ]),
                    const Spacer(),
                    if (_biometricAvail)
                      IconButton(
                        onPressed: _loginWithBiometric,
                        icon: const Icon(Icons.fingerprint, color: Colors.white, size: 28),
                        tooltip: 'Login dengan Biometrik',
                      ),
                  ]),
                ),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                    // Error
                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.red.withOpacity(.2))),
                        child: Row(children: [
                          Icon(Icons.error_outline, color: AppColors.red, size: 15),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMsg!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.red))),
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                      validator: (v) => v!.isEmpty ? 'Email wajib diisi' : (!v.contains('@') ? 'Email tidak valid' : null),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Password wajib diisi' : (v.length < 6 ? 'Minimal 6 karakter' : null),
                    ),
                    const SizedBox(height: 8),

                    // URL Server toggle
                    TextButton(
                      onPressed: () => setState(() => _showUrl = !_showUrl),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_showUrl ? Icons.expand_less : Icons.settings_ethernet, size: 15, color: AppColors.ink3),
                        const SizedBox(width: 5),
                        Text('URL Server', style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                      ]),
                    ),

                    if (_showUrl) ...[
                      TextFormField(
                        controller: _urlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Base URL API',
                          hintText:  'http://localhost:8000/api',
                          prefixIcon: Icon(Icons.link, size: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, children: [
                        _urlChip('Chrome', 'http://localhost:8000/api'),
                        _urlChip('Android Emu', 'http://10.0.2.2:8000/api'),
                        _urlChip('LAN HP', 'http://192.168.74.128:8000/api'),
                        _urlChip('Hosting', ' https://enlighten-ascension-unseen.ngrok-free.dev/api'),
                      ]),
                    ],
                    const SizedBox(height: 14),

                    // Login button
                    AppButton(label: 'Masuk ke Sistem', onPressed: _login, loading: _loading, icon: Icons.login),
                    const SizedBox(height: 18),

                    // Demo accounts
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Akun Demo', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 10),

                    ..._demos.map((acc) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: OutlinedButton(
                        onPressed: () => _fillDemo(acc.cast<String,String>()),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Row(children: [
                          CircleAvatar(radius: 14, backgroundColor: AppColors.navy, child: Text(acc['name']![0], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 9),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(acc['name']!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
                            Text('${acc['email']} · ${acc['role']}', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                          ])),
                          const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.ink3),
                        ]),
                      ),
                    )),
                  ])),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text('v1.0.0 · CBT SMKN 1 Parittiga', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Widget _urlChip(String label, String url) => GestureDetector(
    onTap: () { _urlCtrl.text = url; setState(() {}); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11)),
    ),
  );
}

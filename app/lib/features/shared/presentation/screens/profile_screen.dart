import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl= TextEditingController();
  final _urlCtrl     = TextEditingController();

  bool _biometricAvail   = false;
  bool _biometricEnabled = false;
  bool _obscureOld = true, _obscureNew = true, _obscureConf = true;
  final String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url    = await SecureStorage.getBaseUrl();
    final bioAvail = await SecurityService.isBiometricAvailable();
    final bioEn    = await SecureStorage.getBiometricEnabled();
    _urlCtrl.text   = url;
    if (mounted) setState(() { _biometricAvail = bioAvail; _biometricEnabled = bioEn; });
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose(); _newPassCtrl.dispose(); _confPassCtrl.dispose(); _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user      = authState.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Profil & Pengaturan'), leading: const AppBackButton()),
      body: ListView(children: [

        // ── Avatar Section ──
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Stack(children: [
              CircleAvatar(radius: 40, backgroundColor: AppColors.navy,
                child: Text(user?.initials ?? 'U', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
              Positioned(right: 0, bottom: 0, child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: AppColors.orange, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
                child: const Icon(Icons.edit, size: 13, color: Colors.white),
              )),
            ]),
            const SizedBox(height: 10),
            Text(user?.name ?? '—', style: AppTextStyles.h3),
            Text('${user?.role ?? '—'} · ${user?.email ?? '—'}', style: AppTextStyles.bodySmall),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Info Dasar ──
        _section('Informasi Akun', [
          _readOnlyTile(Icons.person_outline, 'Nama Lengkap', user?.name ?? '—'),
          _readOnlyTile(Icons.email_outlined, 'Email',        user?.email ?? '—'),
          if (user?.isSiswa == true) ...[
            _readOnlyTile(Icons.badge_outlined, 'NIS',   user!.nis ?? '—'),
            if (user.className != null)
              _readOnlyTile(Icons.class_outlined, 'Kelas', user.className!),
          ] else if (user?.nip != null || user?.nis != null)
            _readOnlyTile(Icons.badge_outlined, user!.isGuru ? 'NIP' : 'NIS', user.isGuru ? (user.nip ?? '—') : (user.nis ?? '—')),
        ]),
        const SizedBox(height: 12),

        // ── Ganti Password ──
        _section('Keamanan', [
          _passField('Password Lama',     _oldPassCtrl, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
          _passField('Password Baru',     _newPassCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
          _passField('Konfirmasi Password', _confPassCtrl, _obscureConf, () => setState(() => _obscureConf = !_obscureConf)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14,8,14,14),
            child: ElevatedButton(
              onPressed: _gantiPassword,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              child: const Text('Perbarui Password'),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // ── Keamanan Perangkat ──
        _section('Keamanan Perangkat', [
          if (_biometricAvail) _toggleTile(
            'Login Biometrik',
            'Gunakan fingerprint / Face ID',
            _biometricEnabled,
            Icons.fingerprint,
            (v) async {
              if (v) {
                final ok = await SecurityService.authenticateWithBiometric(reason: 'Aktifkan login biometrik');
                if (!ok) return;
              }
              await SecureStorage.saveBiometricEnabled(v);
              setState(() => _biometricEnabled = v);
            },
          ),
          _infoTile('Device ID', 'Tersimpan aman di perangkat', icon: Icons.security),
        ]),
        const SizedBox(height: 12),

        // ── Koneksi Server ──
        _section('Koneksi Server', [
          Padding(
            padding: const EdgeInsets.fromLTRB(14,12,14,0),
            child: TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL API Server',
                hintText: 'http://192.168.1.5/api',
                prefixIcon: Icon(Icons.link, size: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14,8,14,4),
            child: Wrap(spacing: 8, children: [
              _urlPreset('Lokal',    'http://127.0.0.1:8000/api'),
              _urlPreset('Android Emu', 'http://10.0.2.2:8000/api'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14,8,14,14),
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
                if (url.isEmpty) return;
                await ApiClient.updateBaseUrl(url);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('URL disimpan: $url')));
              },
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Simpan URL'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sky),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // ── Tentang Aplikasi ──
        _section('Tentang', [
          _infoTile('Versi Aplikasi',  _appVersion,                    icon: Icons.info_outline),
          _infoTile('Platform',        Theme.of(context).platform.name, icon: Icons.phone_android),
          _infoTile('LCG Randomisasi', 'Aktif (A=1664525)',             icon: Icons.shuffle),
          _listTile('Kebijakan Privasi', icon: Icons.privacy_tip_outlined, onTap: () {}),
        ]),
        const SizedBox(height: 12),

        // ── Logout ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: AppColors.red),
            label: const Text('Keluar dari Akun Ini', style: TextStyle(color: AppColors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red), foregroundColor: AppColors.red),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: OutlinedButton.icon(
            onPressed: _logoutAll,
            icon: const Icon(Icons.devices, size: 18, color: AppColors.red),
            label: const Text('Keluar Semua Perangkat', style: TextStyle(color: AppColors.red)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.red.withValues(alpha:.5)), foregroundColor: AppColors.red),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    color: AppColors.surface,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14,14,14,6), child: Text(title.toUpperCase(), style: AppTextStyles.label)),
      const Divider(height: 1),
      ...children,
    ]),
  );

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) => Padding(
    padding: const EdgeInsets.fromLTRB(14,12,14,0),
    child: TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16), onPressed: toggle),
      ),
    ),
  );

  Widget _readOnlyTile(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, size: 20, color: AppColors.navy),
    title: Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.ink3)),
    subtitle: Text(value, style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w500)),
    dense: true,
  );

  Widget _infoTile(String label, String value, {IconData? icon}) => ListTile(
    leading: icon != null ? Icon(icon, size: 20, color: AppColors.ink3) : null,
    title: Text(label, style: AppTextStyles.body.copyWith(fontSize: 13.5)),
    trailing: Text(value, style: AppTextStyles.bodySmall.copyWith(fontFamily: 'JetBrainsMono', fontSize: 11.5)),
    dense: true,
  );

  Widget _listTile(String label, {IconData? icon, VoidCallback? onTap}) => ListTile(
    leading: icon != null ? Icon(icon, size: 20, color: AppColors.ink3) : null,
    title: Text(label, style: AppTextStyles.body.copyWith(fontSize: 13.5)),
    trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
    onTap: onTap,
    dense: true,
  );

  Widget _toggleTile(String label, String sub, bool value, IconData icon, ValueChanged<bool> onChanged) => SwitchListTile.adaptive(
    value:    value,
    onChanged: onChanged,
    activeTrackColor: AppColors.navy,
    secondary: Icon(icon, size: 20, color: AppColors.ink3),
    title:    Text(label, style: AppTextStyles.body.copyWith(fontSize: 13.5)),
    subtitle: Text(sub,   style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5)),
    dense:    true,
  );

  Widget _urlPreset(String label, String url) => GestureDetector(
    onTap: () { _urlCtrl.text = url; setState(() {}); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.navy)),
    ),
  );

  Future<void> _gantiPassword() async {
    if (_oldPassCtrl.text.isEmpty) { _showSnack('Password lama wajib diisi'); return; }
    if (_newPassCtrl.text.length < 8) { _showSnack('Password baru minimal 8 karakter'); return; }
    if (_newPassCtrl.text != _confPassCtrl.text) { _showSnack('Konfirmasi password tidak cocok'); return; }
    try {
      await ApiClient.patch('/auth/password', data: {
        'current_password': _oldPassCtrl.text,
        'password':         _newPassCtrl.text,
        'password_confirmation': _confPassCtrl.text,
      });
      _oldPassCtrl.clear(); _newPassCtrl.clear(); _confPassCtrl.clear();
      _showSnack('Password berhasil diubah', success: true);
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _logoutAll() async {
    try { await ApiClient.post('/auth/logout-all'); } catch (_) {}
    await SecureStorage.clearAll();
    if (mounted) context.go('/login');
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.green : AppColors.red,
    ));
  }
}

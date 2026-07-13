import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  static const roles = [
    ('admin', 'Admin', Icons.admin_panel_settings_outlined, AppColors.red, AppColors.redLight, 'Kelola akun admin & pengaturan sistem', 'Akses penuh ke semua fitur'),
    ('guru', 'Guru', Icons.school_outlined, AppColors.navy, AppColors.navyLight, 'Kelola akun guru, mapel, & kelas', 'Buat soal, jadwal ujian, rekap nilai'),
    ('siswa', 'Siswa', Icons.people_outline, AppColors.green, AppColors.greenLight, 'Kelola akun siswa & pendaftaran kelas', 'Atur akses ujian & pantau aktivitas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Manajemen Pengguna')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        itemCount: roles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, i) {
          final (key, label, icon, color, colorLight, desc, sub) = roles[i];
          return _RoleCard(
            label: label, icon: icon, color: color, colorLight: colorLight,
            description: desc, subtitle: sub,
            onTap: () => context.go('/admin/users/$key'),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label, description, subtitle;
  final IconData icon;
  final Color color, colorLight;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label, required this.icon,
    required this.color, required this.colorLight,
    required this.description, required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: colorLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.withValues(alpha: .15), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: AppTextStyles.h3.copyWith(fontSize: 18, color: AppColors.ink)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: AppColors.ink3, size: 20),
              ]),
              const SizedBox(height: 4),
              Text(description, style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5, color: AppColors.ink2)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.info_outline, size: 12, color: color),
                const SizedBox(width: 4),
                Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

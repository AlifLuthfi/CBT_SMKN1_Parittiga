import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_widgets.dart';

final _adminDashProvider = FutureProvider((ref) => ApiClient.get('/admin/dashboard'));

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(_adminDashProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Admin — CBT SMKN 1 Parittiga'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_adminDashProvider)),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(child: const Text('Logout'), onTap: () async {
                await SecureStorage.clearAll();
                if (context.mounted) context.go('/login');
              }),
            ],
          ),
        ],
      ),
      body: dash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_adminDashProvider)),
        data:    (data) => _buildContent(context, ref, data as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Dashboard Admin', style: AppTextStyles.h3),
      Text('Ringkasan sistem', style: AppTextStyles.bodySmall),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.45,
        children: [
          StatCard(label: 'Total Guru',   value: '${stats['guru']        ?? 0}', accentColor: AppColors.navy),
          StatCard(label: 'Total Siswa',  value: '${stats['siswa']       ?? 0}', accentColor: AppColors.green),
          StatCard(label: 'Total Kelas',  value: '${stats['kelas']       ?? 0}', accentColor: AppColors.orange),
          StatCard(label: 'Ujian Aktif',  value: '${stats['ujian_aktif'] ?? 0}', accentColor: AppColors.red),
        ],
      ),
      const SizedBox(height: 20),
      Text('Menu Admin', style: AppTextStyles.h4),
      const SizedBox(height: 12),
      _adminMenu(context, ref),
    ]);
  }

  Widget _adminMenu(BuildContext context, WidgetRef ref) {
    final items = [
      (Icons.people_outline,     'Manajemen User',  AppColors.navy,   () => context.go('/admin/users')),
      (Icons.class_outlined,     'Manajemen Kelas', AppColors.green,  () => context.go('/admin/kelas')),
      (Icons.quiz_outlined,      'Semua Ujian',     AppColors.orange, () => context.go('/admin/exams')),
      (Icons.warning_outlined,   'Pelanggaran',     AppColors.red,    () => context.go('/admin/violations')),
      (Icons.download_outlined,  'Export Data',     AppColors.ink2,   () => _showExportDialog(context)),
      (Icons.notifications_none,'Notifikasi',       AppColors.ink2,   () => context.go('/admin/notifications')),
      (Icons.person_outline,     'Profil',         AppColors.ink2,   () => context.go('/admin/profile')),
    ];
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2,
      children: items.map((item) => GestureDetector(
        onTap: item.$4,
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: item.$3.withValues(alpha:.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.$1, color: item.$3, size: 22)),
            const SizedBox(height: 8),
            Text(item.$2, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ]),
        ),
      )).toList(),
    );
  }

  // ── Export Data (dialog ringkas) ─────────────────────
  void _showExportDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Export Data'),
        content: const ListTile(
          leading: Icon(Icons.people_outline, color: AppColors.navy),
          title: Text('Export Data User (CSV)'),
          trailing: Icon(Icons.download),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiClient.get('/admin/export/users');
                if (ctx.mounted) Navigator.pop(ctx);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Download dimulai — cek folder download')));
                }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}

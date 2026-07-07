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
        title: const Text('Admin — ExamCore'),
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
      (Icons.people_outline,    'Manajemen User',  AppColors.navy,   () => context.go('/admin/users')),
      (Icons.class_outlined,    'Manajemen Kelas', AppColors.green,  () => context.go('/admin/kelas')),
      (Icons.quiz_outlined,     'Semua Ujian',     AppColors.orange, () => context.go('/admin/exams')),
      (Icons.warning_outlined,  'Log Pelanggaran', AppColors.red,    () => _showViolationsSheet(context)),
      (Icons.history,           'Activity Log',    AppColors.sky,    () => _showActivityLogSheet(context)),
      (Icons.download_outlined, 'Export Data',     AppColors.ink2,   () => _showExportSheet(context)),
    ];
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2,
      children: items.map((item) => GestureDetector(
        onTap: item.$4,
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: item.$3.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.$1, color: item.$3, size: 22)),
            const SizedBox(height: 8),
            Text(item.$2, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ]),
        ),
      )).toList(),
    );
  }

  // ── Log Pelanggaran ─────────────────────────────────
  void _showViolationsSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * .86,
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Text('Log Pelanggaran', style: AppTextStyles.h4)),
          const Divider(height: 1),
          Expanded(child: FutureBuilder<dynamic>(
            future: ApiClient.get('/admin/violations'),
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) return ListView(children: const [SkeletonListTile(), SkeletonListTile()]);
              if (snap.hasError) return ErrorState(message: snap.error.toString(), onRetry: () => Navigator.pop(ctx));
              final viols = ((snap.data as Map<String, dynamic>)['data'] as List? ?? []);
              if (viols.isEmpty) return const EmptyState(title: 'Belum ada pelanggaran', icon: Icons.check_circle_outline);
              return ListView.separated(
                itemCount: viols.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final v = viols[i] as Map<String, dynamic>;
                  final student = v['student'] as Map<String, dynamic>?;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.redLight, child: const Icon(Icons.warning, color: AppColors.red, size: 18)),
                    title: Text(student?['name']?.toString() ?? '-', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('${v['violation_type'] ?? '-'} · ${v['created_at'] ?? '-'}'),
                  );
                },
              );
            },
          )),
        ]),
      ),
    );
  }

  // ── Activity Log ────────────────────────────────────
  void _showActivityLogSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * .86,
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Text('Activity Log', style: AppTextStyles.h4)),
          const Divider(height: 1),
          Expanded(child: FutureBuilder<dynamic>(
            future: ApiClient.get('/admin/activity-logs'),
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) return ListView(children: const [SkeletonListTile(), SkeletonListTile()]);
              if (snap.hasError) return ErrorState(message: snap.error.toString(), onRetry: () => Navigator.pop(ctx));
              final logs = ((snap.data as Map<String, dynamic>)['data'] as List? ?? []);
              if (logs.isEmpty) return const EmptyState(title: 'Belum ada aktivitas', icon: Icons.history_outlined);
              return ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final l = logs[i] as Map<String, dynamic>;
                  final actor = l['user'] as Map<String, dynamic>?;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 16, backgroundColor: AppColors.bg, child: Icon(Icons.person_outline, size: 16, color: AppColors.ink3)),
                    title: Text(l['description']?.toString() ?? '-', style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                    subtitle: Text(actor?['name']?.toString() ?? '-', style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5)),
                    trailing: Text(l['created_at']?.toString() ?? '', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                  );
                },
              );
            },
          )),
        ]),
      ),
    );
  }

  // ── Export Data ──────────────────────────────────────
  void _showExportSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Text('Export Data', style: AppTextStyles.h4),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.people_outline, color: AppColors.navy),
            title: const Text('Export Users (CSV)'),
            trailing: const Icon(Icons.download),
            onTap: () async {
              try {
                await ApiClient.get('/admin/export/users');
                if (ctx.mounted) Navigator.pop(ctx);
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Download dimulai — cek folder download')));
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

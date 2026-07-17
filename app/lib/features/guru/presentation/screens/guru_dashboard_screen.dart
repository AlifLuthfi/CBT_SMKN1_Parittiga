import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/guru_models.dart';
import '../../data/guru_repository.dart';

final _guruRepoProvider   = Provider((_) => GuruRepository());
final _dashboardProvider  = FutureProvider((ref) => ref.read(_guruRepoProvider).getDashboard());

class GuruDashboardScreen extends ConsumerWidget {
  const GuruDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(_dashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('CBT SMKN 1 Parittiga'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_dashboardProvider)),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'profile', child: const Text('Profil'), onTap: () {}),
              PopupMenuItem(value: 'logout',  child: const Text('Logout'), onTap: () => _logout(context)),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_dashboardProvider),
        child: dash.when(
          loading: () => _buildLoading(),
          error:   (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_dashboardProvider)),
          data:    (data) => _buildContent(context, ref, data),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/guru/exam/create'),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ujian Baru', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildLoading() => ListView(padding: const EdgeInsets.all(16), children: [
    const SizedBox(height: 8),
    GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
      children: const [SkeletonCard(), SkeletonCard(), SkeletonCard(), SkeletonCard()]),
    const SizedBox(height: 20),
    const SkeletonListTile(), const SkeletonListTile(), const SkeletonListTile(),
  ]);

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final stats   = DashboardStats.fromJson(data['stats'] as Map<String, dynamic>? ?? {});
    final exams   = ((data['recentExams'] ?? data['recent_exams']) as List? ?? [])
        .map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
    final viols   = ((data['recentViolations'] ?? data['recent_violations']) as List? ?? [])
        .map((e) => ViolationModel.fromJson(e as Map<String, dynamic>)).toList();

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
      FutureBuilder(
        future: SecureStorage.getUser(),
        builder: (_, snap) {
          final name  = (snap.data?['name'] as String?)?.split(' ').first ?? 'Guru';
          final hour  = DateTime.now().hour;
          final salam = hour < 11 ? 'Selamat Pagi' : hour < 15 ? 'Selamat Siang' : 'Selamat Sore';
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$salam, $name!', style: AppTextStyles.h3),
            Text('Ringkasan hari ini', style: AppTextStyles.bodySmall),
          ]);
        },
      ),
      const SizedBox(height: 16),

      // Stats grid
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.45,
        children: [
          StatCard(label: 'Total Ujian', value: '${stats.totalExams}',    subtitle: '${stats.activeExams} aktif', accentColor: AppColors.orange),
          StatCard(label: 'Total Mapel', value: '${stats.totalSubjects}', subtitle: 'Terdaftar',                  accentColor: AppColors.navy),
          StatCard(label: 'Total Kelas', value: '${stats.totalClasses}',  subtitle: 'Diampu',                     accentColor: AppColors.green),
          StatCard(label: 'Total Soal',  value: '${stats.totalQuestions}', subtitle: 'Tersimpan',                  accentColor: AppColors.sky),
        ],
      ),
      const SizedBox(height: 20),

      // Recent exams
      _sectionHeader('Daftar Ujian',
          action: TextButton(onPressed: () => context.push('/guru/exams'), child: const Text('Semua'))),
      const SizedBox(height: 8),
      _examListCard(exams),
      const SizedBox(height: 20),

      // Violations
      if (viols.isNotEmpty) ...[
        _sectionHeader('Pelanggaran Terbaru'),
        const SizedBox(height: 8),
        _violationCard(viols),
      ],
    ]);
  }

  Widget _sectionHeader(String title, {Widget? action}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(title, style: AppTextStyles.h4), if (action != null) action],
  );

  Widget _examListCard(List<ExamModel> exams) {
    if (exams.isEmpty) return const EmptyState(title: 'Belum ada ujian', icon: Icons.description_outlined);
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: exams.take(6).toList().asMap().entries.map((entry) {
        final e    = entry.value;
        final last = entry.key == (exams.length > 6 ? 5 : exams.length - 1);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${e.classRoom?.name ?? ''} · ${e.totalQuestions} soal', style: AppTextStyles.bodySmall),
            ])),
            StatusBadge.fromStatus(e.status),
          ]),
        );
      }).toList()),
    );
  }

  Widget _violationCard(List<ViolationModel> viols) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(children: viols.take(5).toList().asMap().entries.map((entry) {
      final v    = entry.value;
      final last = entry.key == viols.length - 1;
      final c    = v.count >= 5 ? AppColors.red : v.count >= 3 ? AppColors.orange : AppColors.amber;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          CircleAvatar(radius: 15, backgroundColor: c.withValues(alpha:.1),
            child: Text(v.studentName[0], style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.studentName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
            Text(v.typeLabel,   style: AppTextStyles.bodySmall),
          ])),
          Text('${v.count}×', style: TextStyle(fontFamily: 'JetBrainsMono', color: c, fontWeight: FontWeight.w700)),
        ]),
      );
    }).toList()),
  );

  Future<void> _logout(BuildContext ctx) async {
    await SecureStorage.clearAll();
    if (ctx.mounted) ctx.go('/login');
  }
}

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
    final actives = ((data['activeExams'] ?? data['active_exams']) as List? ?? [])
        .map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
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
          StatCard(label: 'Total Ujian',  value: '${stats.totalExams}',    subtitle: '${stats.activeExams} aktif', accentColor: AppColors.orange),
          StatCard(label: 'Total Soal',   value: '${stats.totalQuestions}', subtitle: 'Tersimpan',                  accentColor: AppColors.navy),
          StatCard(label: 'Total Siswa',  value: '${stats.totalStudents}',  subtitle: 'Terdaftar',                  accentColor: AppColors.green),
          StatCard(label: 'Mata Pelajaran', value: '${stats.totalSubjects}', subtitle: 'Terdaftar',               accentColor: AppColors.sky),
        ],
      ),
      const SizedBox(height: 20),

      // Active exams
      _sectionHeader('Ujian Berjalan (${actives.length})',
          action: TextButton(onPressed: () => context.push('/guru/exams'), child: const Text('Semua'))),
      const SizedBox(height: 8),
      if (actives.isEmpty)
        const EmptyState(title: 'Tidak ada ujian aktif', icon: Icons.coffee_outlined)
      else
        ...actives.map((e) => _activeExamCard(context, e, ref)),
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

  Widget _activeExamCard(BuildContext context, ExamModel exam, WidgetRef ref) {
    final submitted = exam.submittedCount ?? 0;
    final total     = exam.sessionsCount  ?? 0;
    final pct       = total > 0 ? submitted / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(.3), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(exam.title, style: AppTextStyles.h4.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
          StatusBadge.fromStatus('active'),
        ]),
        if (exam.classRoom != null) ...[
          const SizedBox(height: 3),
          Text(exam.classRoom!.name, style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _miniStat('Peserta', '$total'),
          _miniStat('Submit',  '$submitted', color: AppColors.green),
          _miniStat('Langgar', '${exam.violationsCount ?? 0}', color: AppColors.red),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.border, color: AppColors.green, minHeight: 6),
        ),
        const SizedBox(height: 4),
        Text('$submitted/$total submit (${(pct*100).toStringAsFixed(0)}%)', style: AppTextStyles.bodySmall),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.pause, size: 14),
            label: const Text('Pause'),
            onPressed: () => _pauseExam(context, exam, ref),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.stop, size: 14),
            label: const Text('Akhiri'),
            onPressed: () => _endExam(context, exam, ref),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
          )),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, {Color? color}) => Column(children: [
    Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 20, fontWeight: FontWeight.w700, color: color ?? AppColors.navy)),
    Text(label, style: AppTextStyles.bodySmall),
  ]);

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
          CircleAvatar(radius: 15, backgroundColor: c.withOpacity(.1),
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

  Future<void> _pauseExam(BuildContext ctx, ExamModel exam, WidgetRef ref) async {
    try {
      await ref.read(_guruRepoProvider).pauseExam(exam.id);
      ref.invalidate(_dashboardProvider);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ujian dijeda')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _endExam(BuildContext ctx, ExamModel exam, WidgetRef ref) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Akhiri Ujian?'),
      content: Text('Akhiri "${exam.title}"? Semua siswa yang belum submit akan dikumpulkan otomatis.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0,0)), child: const Text('Ya, Akhiri')),
      ],
    ));
    if (ok != true || !ctx.mounted) return;
    try {
      await ref.read(_guruRepoProvider).endExam(exam.id);
      ref.invalidate(_dashboardProvider);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ujian diakhiri')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _logout(BuildContext ctx) async {
    await SecureStorage.clearAll();
    if (ctx.mounted) ctx.go('/login');
  }
}

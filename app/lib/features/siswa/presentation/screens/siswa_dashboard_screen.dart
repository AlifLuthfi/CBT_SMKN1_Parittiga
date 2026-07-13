import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/siswa_models.dart';
import '../../data/siswa_repository.dart';

final _siswaRepoProvider  = Provider((_) => SiswaRepository());
final _availableExamsProvider = FutureProvider(
  (ref) => ref.read(_siswaRepoProvider).getAvailableExams());

class SiswaDashboardScreen extends ConsumerWidget {
  const SiswaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(_availableExamsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('CBT SMKN 1 Parittiga'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_availableExamsProvider)),
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
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_availableExamsProvider),
        child: exams.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
          error:   (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_availableExamsProvider)),
          data:    (list) => _buildContent(context, list),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<SiswaExamModel> exams) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      FutureBuilder(
        future: SecureStorage.getUser(),
        builder: (_, snap) {
          final name = (snap.data?['name'] as String?)?.split(' ').first ?? 'Siswa';
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, $name!', style: AppTextStyles.h3),
            Text('Ujian tersedia untuk Anda', style: AppTextStyles.bodySmall),
          ]);
        },
      ),
      const SizedBox(height: 20),
      if (exams.isEmpty)
        const EmptyState(
          title:    'Tidak ada ujian tersedia',
          subtitle: 'Ujian akan muncul di sini ketika guru mengaktifkan ujian',
          icon:     Icons.description_outlined,
        )
      else ...[
        Text('Ujian Aktif (${exams.length})', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        ...exams.map((e) => _examCard(context, e)),
      ],
    ]);
  }

  Widget _examCard(BuildContext context, SiswaExamModel exam) {
    final done       = exam.sessionStatus != null && exam.sessionStatus != 'in_progress';
    final inProgress = exam.sessionStatus == 'in_progress';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inProgress ? AppColors.green : AppColors.border, width: inProgress ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(11))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam.title, style: AppTextStyles.h4.copyWith(color: Colors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('${exam.subject} · ${exam.className}', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
            ])),
            if (inProgress)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('BERLANGSUNG', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),

        // Info chips
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Wrap(spacing: 12, children: [
            _infoChip(Icons.timer_outlined, '${exam.durationMinutes} menit'),
            _infoChip(Icons.quiz_outlined,  '${exam.totalQuestions} soal'),
            _infoChip(Icons.star_outline,   'KKM ${exam.passingGrade.toInt()}'),
            if (exam.startTime != null)
              _infoChip(Icons.calendar_today, _formatHari(exam.startTime!)),
          ]),
        ),
        const SizedBox(height: 12),

        // Action button
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: done
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Lihat Hasil'),
                  onPressed: () => context.push('/siswa/result/${exam.sessionId}'),
                )
              : ElevatedButton.icon(
                  icon: Icon(inProgress ? Icons.play_arrow : Icons.start, size: 18),
                  label: Text(inProgress ? 'Lanjutkan Ujian' : 'Mulai Ujian'),
                  onPressed: () => context.push('/siswa/exam/${exam.id}'),
                ),
        ),
      ]),
    );
  }

  String _formatHari(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso.substring(0, 10);
    const days = ['Senin','Selasa','Rabu','Kamis',"Jum'at",'Sabtu','Minggu'];
    return '${days[dt.weekday - 1]}, ${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }

  Widget _infoChip(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.ink3),
    const SizedBox(width: 4),
    Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
  ]);
}

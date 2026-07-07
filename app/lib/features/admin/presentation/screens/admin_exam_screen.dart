import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../guru/data/guru_models.dart';

final _adminExamsProvider = FutureProvider.autoDispose((ref) => ApiClient.get('/admin/exams'));

class AdminExamScreen extends ConsumerWidget {
  const AdminExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(_adminExamsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manajemen Ujian'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_adminExamsProvider)),
        ],
      ),
      body: exams.when(
        loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
        error:   (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_adminExamsProvider)),
        data:    (data) {
          final list = ((data as Map<String, dynamic>)['data'] as List? ?? []);
          if (list.isEmpty) {
            return const EmptyState(title: 'Tidak ada ujian', icon: Icons.description_outlined);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_adminExamsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: list.length,
              itemBuilder: (_, i) => _examCard(context, ref, list[i] as Map<String, dynamic>),
            ),
          );
        },
      ),
    );
  }

  Widget _examCard(BuildContext context, WidgetRef ref, Map<String, dynamic> e) {
    final exam = ExamModel.fromJson(e);
    final teacher = e['teacher'] as Map<String, dynamic>?;
    final sessionsCount = e['sessions_count'] as int? ?? 0;
    final submittedCount = e['submitted_count'] as int? ?? 0;
    final pct = sessionsCount > 0 ? submittedCount / sessionsCount : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: exam.isActive ? AppColors.green.withOpacity(.4) : AppColors.border, width: exam.isActive ? 1.5 : 1),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: exam.isActive ? AppColors.navy : AppColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exam.isActive ? Colors.white : AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${exam.classRoom?.name ?? '—'} · ${teacher?['name'] ?? '—'}', style: TextStyle(fontSize: 11.5, color: exam.isActive ? Colors.white60 : AppColors.ink3)),
            ])),
            StatusBadge.fromStatus(exam.status),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          // Tanggal
          if (exam.startTime != null || exam.endTime != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 13, color: AppColors.navy),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  _formatDate(exam.startTime),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11.5),
                )),
              ]),
            ),
            const SizedBox(height: 10),
          ],

          // Stats
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _miniStat('Soal',     '${exam.totalQuestions}',     AppColors.navy),
            _miniStat('Peserta',  '$sessionsCount',             AppColors.ink),
            _miniStat('Submit',   '$submittedCount',            AppColors.green),
            _miniStat('KKM',      '${exam.passingGrade.toInt()}', AppColors.amber),
          ]),

          if (exam.isActive) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.border, color: AppColors.green, minHeight: 5),
            ),
            const SizedBox(height: 3),
            Text('$submittedCount/$sessionsCount submit (${(pct*100).toStringAsFixed(0)}%)', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],

          const SizedBox(height: 12),
          // Actions
          Row(children: [
            if (exam.isDraft || exam.isScheduled)
              Expanded(child: _actionBtn('Aktifkan', AppColors.green, Icons.play_arrow, () => _activateExam(context, ref, exam))),
            if (exam.isActive)
              Expanded(child: _actionBtn('Akhiri', AppColors.red, Icons.stop, () => _endExam(context, ref, exam))),
            if (exam.isEnded)
              Expanded(child: _actionBtn('Selesai', AppColors.ink3, Icons.check_circle, null)),
          ]),
        ])),
      ]),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    const days = ['Senin','Selasa','Rabu','Kamis',"Jum'at",'Sabtu','Minggu'];
    final dayName = days[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2,'0');
    final m = dt.month.toString().padLeft(2,'0');
    return '$dayName, $d/$m/${dt.year}';
  }

  Widget _miniStat(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
  ]);

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback? onTap) => ElevatedButton.icon(
    onPressed: onTap,
    icon:  Icon(icon, size: 15, color: Colors.white),
    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      minimumSize:     const Size(0, 38),
      padding:         const EdgeInsets.symmetric(horizontal: 12),
      disabledBackgroundColor: color.withOpacity(.4),
    ),
  );

  Future<void> _activateExam(BuildContext context, WidgetRef ref, ExamModel exam) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Aktifkan Ujian?'),
      content: Text('Aktifkan "${exam.title}"? Ujian akan tersedia untuk siswa.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          child: const Text('Aktifkan'),
        ),
      ],
    ));
    if (ok != true) return;
    try {
      await ApiClient.patch('/admin/exams/${exam.id}/activate');
      ref.invalidate(_adminExamsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ujian diaktifkan'), backgroundColor: AppColors.green));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red));
    }
  }

  Future<void> _endExam(BuildContext context, WidgetRef ref, ExamModel exam) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Akhiri Ujian?'),
      content: Text('Akhiri "${exam.title}"? Semua sesi siswa yang masih berjalan akan ditutup.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          child: const Text('Akhiri'),
        ),
      ],
    ));
    if (ok != true) return;
    try {
      await ApiClient.patch('/admin/exams/${exam.id}/end');
      ref.invalidate(_adminExamsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ujian diakhiri'), backgroundColor: AppColors.green));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/siswa_models.dart';
import '../../data/siswa_repository.dart';

final _hasilProvider = FutureProvider.family<ExamResultModel, int>(
  (ref, sessionId) => SiswaRepository().getResult(sessionId),
);

class HasilScreen extends ConsumerStatefulWidget {
  final int            sessionId;
  final ExamResultModel? result;
  const HasilScreen({super.key, required this.sessionId, this.result});
  @override
  ConsumerState<HasilScreen> createState() => _HasilScreenState();
}

class _HasilScreenState extends ConsumerState<HasilScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.result != null) return _buildContent(context, widget.result!);
    final async = ref.watch(_hasilProvider(widget.sessionId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: ErrorState(message: e.toString())),
      data:    (r)    => _buildContent(context, r),
    );
  }

  Widget _buildContent(BuildContext context, ExamResultModel r) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: const Text('Hasil Ujian'),
      leading: const AppBackButton(),
    ),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      // Biodata card
      _biodataCard(r),
      const SizedBox(height: 12),

      // Score card
      _scoreCard(r),
      const SizedBox(height: 12),

      // Stats grid
      _statsGrid(r),
      const SizedBox(height: 12),

      // Review section
      _reviewCard(r),
      const SizedBox(height: 20),
    ]),
  );

  Widget _biodataCard(ExamResultModel r) => FutureBuilder(
    future: SecureStorage.getUser(),
    builder: (_, snap) {
      final u = snap.data ?? {};
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.8,
          children: [
            _bioItem('Nama', u['name'] as String? ?? '—'),
            _bioItem('NIS',  u['nis']  as String? ?? '—'),
            _bioItem('Kelas', r.className.isNotEmpty ? r.className : (u['class_name'] as String? ?? '—')),
            _bioItem('Waktu', r.durationTaken > 0 ? '${r.durationTaken ~/ 60} mnt ${r.durationTaken % 60} dtk' : '—'),
          ],
        ),
      );
    },
  );

  Widget _bioItem(String label, String value) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: .3)),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
    ]),
  );

  Widget _scoreCard(ExamResultModel r) {
    final pass = r.isPassed;
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(11))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Hasil Ujian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: pass ? AppColors.green : AppColors.red, borderRadius: BorderRadius.circular(20)),
              child: Text(pass ? '✓ LULUS' : '✗ TIDAK LULUS', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Score circle
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pass ? AppColors.greenLight : AppColors.redLight,
              border: Border.all(color: pass ? AppColors.green : AppColors.red, width: 4),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(r.score.toStringAsFixed(0), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 30, fontWeight: FontWeight.w700, color: pass ? AppColors.green : AppColors.red)),
              Text('Nilai', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
            ]),
          ),
          const SizedBox(width: 16),

          // Detail stats
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _detailRow(Icons.check_circle_outline, '${r.correct} jawaban benar', AppColors.green),
            const SizedBox(height: 8),
            _detailRow(Icons.cancel_outlined, '${r.wrong} jawaban salah', AppColors.red),
            const SizedBox(height: 8),
            _detailRow(Icons.help_outline, '${r.unanswered} tidak dijawab', AppColors.amber),
            const SizedBox(height: 8),
            _detailRow(Icons.timer_outlined, _formatDuration(r.durationTaken), AppColors.navy),
          ])),
        ])),

        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Passing Grade', style: AppTextStyles.bodySmall),
            Text('${r.passingGrade.toInt()}', style: const TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String text, Color color) => Row(children: [
    Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withValues(alpha:.1), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 13, color: color)),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink2))),
  ]);

  Widget _statsGrid(ExamResultModel r) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      _statBox('Total',  '${r.total}',   null),
      _divider(),
      _statBox('Benar',  '${r.correct}', AppColors.green),
      _divider(),
      _statBox('Salah',  '${r.wrong}',   AppColors.red),
      _divider(),
      _statBox('KKM',    '${r.passingGrade.toInt()}', AppColors.navy),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 56, color: AppColors.border);
  Widget _statBox(String label, String value, Color? color) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(children: [
      Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 18, fontWeight: FontWeight.w700, color: color ?? AppColors.ink)),
      const SizedBox(height: 3),
      Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10), textAlign: TextAlign.center),
    ]),
  ));

  Widget _reviewCard(ExamResultModel r) {
    // Hanya tampilkan soal salah & tidak dijawab
    final wrongAnswers = r.answers.where((a) => a.status != 'correct').toList();
    if (wrongAnswers.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Pembahasan Soal (hanya yang salah)', style: AppTextStyles.h4.copyWith(fontSize: 14)),
          Text('${wrongAnswers.length} perlu diperhatikan', style: AppTextStyles.bodySmall),
        ])),
        const Divider(height: 1),

        ...wrongAnswers.asMap().entries.map((entry) =>
          _reviewItem(entry.key + 1, entry.value)),
      ]),
    );
  }

  Widget _reviewItem(int num, AnswerDetail a) {
    final isCorrect  = a.status == 'correct';
    final isWrong    = a.status == 'wrong';
    final numColor   = isCorrect ? AppColors.green : isWrong ? AppColors.red : AppColors.amber;
    final numBg      = isCorrect ? AppColors.greenLight : isWrong ? AppColors.redLight : AppColors.amberLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: numBg, borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('$num', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: numColor)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.questionText, style: AppTextStyles.body.copyWith(height: 1.6)),
            if (a.imageUrl != null && a.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(AppConstants.resolveImageUrl(a.imageUrl)!, height: 120, width: double.infinity, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ])),
        ]),
        const SizedBox(height: 8),

        // Jawaban user
        Wrap(spacing: 4, children: [
          Text('Jawabanmu: ', style: AppTextStyles.bodySmall),
          Text(a.userAnswer ?? 'Tidak dijawab',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: isCorrect ? AppColors.green : AppColors.red,
              fontStyle: a.userAnswer == null ? FontStyle.italic : FontStyle.normal)),
          if (isWrong) Text(' (salah)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.red)),
        ]),

        // Opsi pilihan
        if (a.options != null && a.options!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...a.options!.entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: e.key == a.correctAnswer
                ? AppColors.greenLight
                : (e.key == a.userAnswer && isWrong ? AppColors.redLight : AppColors.bg),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: e.key == a.correctAnswer
                  ? AppColors.green
                  : (e.key == a.userAnswer && isWrong ? AppColors.red : AppColors.border)),
            ),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: e.key == a.correctAnswer
                    ? AppColors.green
                    : (e.key == a.userAnswer && isWrong ? AppColors.red : Colors.transparent),
                  border: Border.all(color: e.key == a.correctAnswer ? AppColors.green : AppColors.border2)),
                child: Center(child: Text(e.key, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: (e.key == a.correctAnswer || (e.key == a.userAnswer && isWrong)) ? Colors.white : AppColors.ink2))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value, style: AppTextStyles.bodySmall.copyWith(fontSize: 12))),
              if (e.key == a.correctAnswer)
                const Icon(Icons.check_circle, size: 16, color: AppColors.green),
              if (e.key == a.userAnswer && isWrong)
                const Icon(Icons.cancel, size: 16, color: AppColors.red),
            ]),
          )),
        ],

        // Jawaban benar
        if (a.correctAnswer != null) ...[
          const SizedBox(height: 6),
          Text('Kunci: ${a.correctAnswer}',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.green)),
        ],

        // Pembahasan
        if (a.explanation != null && a.explanation!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border)),
            child: Text('Pembahasan: ${a.explanation}',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: AppColors.ink2, height: 1.5)),
          ),
        ],
      ]),
    );
  }

  String _formatDuration(int s) {
    final m = s ~/ 60; final ss = s % 60;
    return m > 0 ? '$m mnt $ss dtk' : '$ss detik';
  }

}

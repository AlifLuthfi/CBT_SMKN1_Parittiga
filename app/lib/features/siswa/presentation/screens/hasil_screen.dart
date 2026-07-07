import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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
  String _reviewFilter = 'wrong'; // default hanya tampilkan salah

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
      leading: IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: () => context.go('/siswa/dashboard'),
      ),
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

      // Back button
      OutlinedButton.icon(
        onPressed: () => context.go('/siswa/dashboard'),
        icon: const Icon(Icons.home_outlined, size: 16),
        label: const Text('Kembali ke Dashboard'),
      ),
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
    Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(6)),
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
    final filtered = _reviewFilter == 'all' ? r.answers : r.answers.where((a) => a.status == _reviewFilter).toList();
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Pembahasan Soal', style: AppTextStyles.h4.copyWith(fontSize: 14)),
          Text('${r.answers.where((a) => a.status != 'correct').length} perlu diperhatikan', style: AppTextStyles.bodySmall),
        ])),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            _filterChip('all',        'Semua'),
            _filterChip('wrong',      'Salah'),
            _filterChip('correct',    'Benar'),
            _filterChip('unanswered', 'Tidak Dijawab'),
          ]),
        ),
        const Divider(height: 1),

        if (filtered.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Text('Tidak ada soal', style: AppTextStyles.bodySmall, textAlign: TextAlign.center))
        else
          ...filtered.asMap().entries.map((entry) =>
            _reviewItem(r.answers.indexOf(entry.value) + 1, entry.value)),
      ]),
    );
  }

  Widget _filterChip(String filter, String label) {
    final active = _reviewFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _reviewFilter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.navy : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink3)),
      ),
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
                child: Image.network(a.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ])),
        ]),
        const SizedBox(height: 8),

        // Jawaban user — hanya info mana yang salah, tanpa kunci benar
        Wrap(spacing: 4, children: [
          Text('Jawaban: ', style: AppTextStyles.bodySmall),
          Text(a.userAnswer ?? 'Tidak dijawab',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: isCorrect ? AppColors.green : AppColors.red,
              fontStyle: a.userAnswer == null ? FontStyle.italic : FontStyle.normal)),
          if (isWrong) Text(' (salah)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.red)),
        ]),
      ]),
    );
  }

  String _formatDuration(int s) {
    final m = s ~/ 60; final ss = s % 60;
    return m > 0 ? '$m mnt $ss dtk' : '$ss detik';
  }

  String _formatNow() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2,'0')}/${n.month.toString().padLeft(2,'0')}/${n.year} ${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}';
  }
}

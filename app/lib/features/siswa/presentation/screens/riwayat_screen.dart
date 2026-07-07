import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';

class RiwayatItem {
  final int     sessionId;
  final String  examTitle, subject, submittedAt, status;
  final double  score, passingGrade;
  final bool    isPassed;
  final int     correct, wrong, unanswered, total;
  const RiwayatItem({required this.sessionId, required this.examTitle, required this.subject, required this.submittedAt, required this.status, required this.score, required this.passingGrade, required this.isPassed, required this.correct, required this.wrong, required this.unanswered, required this.total});
  factory RiwayatItem.fromJson(Map<String, dynamic> j) {
    final exam = j['exam'] as Map<String, dynamic>? ?? {};
    return RiwayatItem(
      sessionId:   j['id']              as int,
      examTitle:   exam['title']        as String? ?? '—',
      subject:     exam['class_room']?['subject'] as String? ?? '—',
      submittedAt: j['submitted_at']    as String? ?? '—',
      status:      j['status']          as String? ?? '—',
      score:       double.tryParse(j['score']?.toString() ?? '') ?? 0,
      passingGrade: double.tryParse((exam['passing_grade'] ?? '').toString()) ?? 70,
      isPassed:    j['is_passed']       as bool? ?? false,
      correct:     j['correct']         as int? ?? 0,
      wrong:       j['wrong']           as int? ?? 0,
      unanswered:  j['unanswered']      as int? ?? 0,
      total:       j['total']           as int? ?? 0,
    );
  }
}

final _riwayatProvider = FutureProvider.autoDispose<List<RiwayatItem>>((ref) async {
  final data = await ApiClient.get('/siswa/history');
  final list = (data['data'] as List?) ?? [];
  return list.map((e) => RiwayatItem.fromJson(e as Map<String, dynamic>)).toList();
});

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});
  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final riwayat = ref.watch(_riwayatProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Riwayat Ujian'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_riwayatProvider))],
      ),
      body: riwayat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_riwayatProvider)),
        data:    (list) => _buildContent(list),
      ),
    );
  }

  Widget _buildContent(List<RiwayatItem> list) {
    final filtered = _filter == 'all'    ? list
        : _filter == 'pass'   ? list.where((r) => r.isPassed).toList()
        : list.where((r) => !r.isPassed).toList();

    // Calculate summary stats
    final total     = list.length;
    final passed    = list.where((r) => r.isPassed).length;
    final avgScore  = total > 0 ? list.map((r) => r.score).reduce((a,b) => a+b) / total : 0.0;
    final bestScore = total > 0 ? list.map((r) => r.score).reduce((a,b) => a>b ? a:b) : 0.0;

    return Column(children: [
      // Summary card
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _summaryBox('Total',    '$total',                    AppColors.navy),
          _summaryBox('Lulus',    '$passed',                   AppColors.green),
          _summaryBox('Rata-rata','${avgScore.toStringAsFixed(1)}', AppColors.amber),
          _summaryBox('Tertinggi','${bestScore.toStringAsFixed(0)}', AppColors.orange),
        ]),
      ),
      // Filter chips
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(14,0,14,10),
        child: Row(children: [
          _chip('all',  'Semua ($total)'),
          _chip('pass', 'Lulus ($passed)'),
          _chip('fail', 'Tidak Lulus (${total - passed})'),
        ]),
      ),
      const Divider(height: 1),
      // List
      Expanded(child: filtered.isEmpty
          ? const EmptyState(title: 'Tidak ada riwayat', icon: Icons.history_outlined)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(_riwayatProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _riwayatCard(filtered[i], i + 1),
              ),
            )),
    ]);
  }

  Widget _summaryBox(String label, String value, Color color) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 20, fontWeight: FontWeight.w700, color: color)),
    Text(label,  style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5)),
  ]));

  Widget _chip(String val, String label) {
    final active = _filter == val;
    return GestureDetector(
      onTap: () => setState(() => _filter = val),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.navy : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink3)),
      ),
    );
  }

  Widget _riwayatCard(RiwayatItem r, int rank) {
    final pass  = r.isPassed;
    final color = pass ? AppColors.green : AppColors.red;
    final pct   = r.total > 0 ? r.correct / r.total : 0.0;

    return GestureDetector(
      onTap: () => context.push('/siswa/result/${r.sessionId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 6, offset: const Offset(0,2))],
        ),
        child: Column(children: [
          Row(children: [
            // Score circle
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(.1), border: Border.all(color: color, width: 2.5)),
              child: Center(child: Text(r.score.toStringAsFixed(0), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 16, fontWeight: FontWeight.w700, color: color))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.examTitle, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(r.subject, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5)),
              Text(r.submittedAt, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
                child: Text(pass ? '✓ LULUS' : '✗ GAGAL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color))),
              const SizedBox(height: 5),
              Text('KKM ${r.passingGrade.toInt()}', style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5)),
            ]),
          ]),
          const SizedBox(height: 10),
          // Answer breakdown
          Row(children: [
            _answerDot(r.correct,    'Benar',  AppColors.green),
            const SizedBox(width: 14),
            _answerDot(r.wrong,      'Salah',  AppColors.red),
            const SizedBox(width: 14),
            _answerDot(r.unanswered, 'Kosong', AppColors.amber),
            const Spacer(),
            // Mini bar
            SizedBox(width: 80, child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.border, color: pass ? AppColors.green : AppColors.red, minHeight: 6)),
              const SizedBox(height: 2),
              Text('${r.correct}/${r.total} benar', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
            ])),
          ]),
          const SizedBox(height: 8),
          // Status timeout info
          if (r.status == 'timeout')
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(7)),
              child: Row(children: [
                const Icon(Icons.timer_off_outlined, size: 12, color: Color(0xFF92400E)),
                const SizedBox(width: 5),
                Text('Dikumpulkan otomatis (waktu habis)', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: const Color(0xFF92400E))),
              ])),
          // View result hint
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Lihat pembahasan →', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11.5, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }

  Widget _answerDot(int count, String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text('$count $label', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.ink2)),
  ]);
}

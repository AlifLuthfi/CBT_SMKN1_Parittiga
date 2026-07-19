import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/siswa_models.dart';
import '../../data/siswa_repository.dart';

final _riwayatProvider = FutureProvider.autoDispose.family<({List<RiwayatItem> items, int total, int lastPage}), int>((ref, page) async {
  return SiswaRepository().getHistory(page: page);
});

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});
  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  String _filter = 'all';
  int _page = 1;
  int _lastPage = 1;
  final List<RiwayatItem> _allItems = [];
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        _page < _lastPage) {
      setState(() => _page++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = ref.watch(_riwayatProvider(_page));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Riwayat Ujian'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () {
          setState(() { _page = 1; _allItems.clear(); });
          ref.invalidate(_riwayatProvider);
        })],
      ),
      body: riwayat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e,_) => ErrorState(message: e.toString(), onRetry: () {
          setState(() { _page = 1; _allItems.clear(); });
          ref.invalidate(_riwayatProvider);
        }),
        data:    (result) {
          if (_page == 1) {
            _allItems.clear();
            _allItems.addAll(result.items);
          } else if (_page > 1 && result.items.isNotEmpty) {
            _allItems.addAll(result.items);
          }
          _lastPage = result.lastPage;
          return _buildContent(result.total);
        },
      ),
    );
  }

  Widget _buildContent(int totalDb) {
    final filtered = _filter == 'all'    ? _allItems
        : _filter == 'pass'   ? _allItems.where((r) => r.isPassed).toList()
        : _allItems.where((r) => !r.isPassed).toList();

    // Calculate summary stats
    final total     = _allItems.length;
    final passed    = _allItems.where((r) => r.isPassed).length;
    final avgScore  = total > 0 ? _allItems.map((r) => r.score).reduce((a,b) => a+b) / total : 0.0;
    final bestScore = total > 0 ? _allItems.map((r) => r.score).reduce((a,b) => a>b ? a:b) : 0.0;

    return Column(children: [
      // Summary card
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _summaryBox('Total',    '$totalDb',                    AppColors.navy),
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
      // List with infinite scroll
      Expanded(child: filtered.isEmpty
          ? const EmptyState(title: 'Tidak ada riwayat', icon: Icons.history_outlined)
          : RefreshIndicator(
              onRefresh: () async { setState(() { _page = 1; _allItems.clear(); }); ref.invalidate(_riwayatProvider); },
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length + (_page < _lastPage ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= filtered.length) {
                    return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  }
                  return _riwayatCard(filtered[i], i + 1);
                },
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.03), blurRadius: 6, offset: const Offset(0,2))],
        ),
        child: Column(children: [
          Row(children: [
            // Score circle
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha:.1), border: Border.all(color: color, width: 2.5)),
              child: Center(child: Text(r.score.toStringAsFixed(0), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 16, fontWeight: FontWeight.w700, color: color))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.examTitle, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(r.subject, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5)),
              Text(_formatWaktu(r.submittedAt), style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha:.1), borderRadius: BorderRadius.circular(20)),
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

  String _formatWaktu(String iso) {
    // iso: "2025-01-15T10:30:00.000000Z" or similar
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const days = ['Senin','Selasa','Rabu','Kamis',"Jum'at",'Sabtu','Minggu'];
    final dayName = days[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2,'0');
    final m = dt.month.toString().padLeft(2,'0');
    final jam = dt.hour.toString().padLeft(2,'0');
    final menit = dt.minute.toString().padLeft(2,'0');
    return '$dayName, $d/$m/${dt.year} • $jam:$menit';
  }

  Widget _answerDot(int count, String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text('$count $label', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.ink2)),
  ]);
}

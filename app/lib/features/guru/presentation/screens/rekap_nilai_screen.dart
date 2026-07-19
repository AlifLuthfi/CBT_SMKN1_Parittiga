import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/guru_models.dart';
import '../../data/guru_repository.dart';

final _kelasProvider = FutureProvider.autoDispose((_) => GuruRepository().getClasses());

class RekapNilaiScreen extends ConsumerStatefulWidget {
  const RekapNilaiScreen({super.key});
  @override
  ConsumerState<RekapNilaiScreen> createState() => _RekapNilaiScreenState();
}

class _RekapNilaiScreenState extends ConsumerState<RekapNilaiScreen> {
  ClassRoomModel? _selected;
  List<Map<String, dynamic>>? _students;
  bool _loadingStudents = false;

  @override
  Widget build(BuildContext context) {
    final kelas = ref.watch(_kelasProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_selected != null ? _selected!.name : 'Rekap Nilai'),
        leading: _selected != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() { _selected = null; _students = null; }))
            : null,
        actions: _selected == null
            ? [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_kelasProvider))]
            : [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadStudents())],
      ),
      body: kelas.when(
        loading: () => ListView(children: const [SkeletonCard(), SkeletonCard(), SkeletonCard()]),
        error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_kelasProvider)),
        data:    (list) => _selected != null
            ? _buildDetail()
            : _buildGrid(list),
      ),
    );
  }

  Widget _buildGrid(List<ClassRoomModel> list) {
    if (list.isEmpty) return const EmptyState(title: 'Belum ada kelas', icon: Icons.class_outlined);
    final sorted = List<ClassRoomModel>.from(list)..sort((a, b) => _compareClassNames(a.name, b.name));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_kelasProvider),
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .95),
        itemCount: sorted.length,
        itemBuilder: (_, i) => _kelasCard(sorted[i]),
      ),
    );
  }

  Widget _kelasCard(ClassRoomModel k) => GestureDetector(
    onTap: () {
      setState(() { _selected = k; });
      _loadStudents();
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.04), blurRadius: 6, offset: const Offset(0,2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.group, color: AppColors.navy, size: 20)),
        const SizedBox(height: 10),
        Text(k.name, style: AppTextStyles.h4.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(k.subject ?? '', style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Row(children: [
          _miniInfo(Icons.people_outline, '${k.studentCount ?? 0}'),
          const SizedBox(width: 10),
          _miniInfo(Icons.quiz_outlined,  '${k.examCount    ?? 0}'),
        ]),
      ]),
    ),
  );

  Widget _miniInfo(IconData icon, String val) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.ink3),
    const SizedBox(width: 3),
    Text(val, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5, color: AppColors.ink2, fontWeight: FontWeight.w500)),
  ]);

  Future<void> _loadStudents() async {
    if (_selected == null) return;
    setState(() => _loadingStudents = true);
    try {
      final data = await ApiClient.get('/guru/classes/${_selected!.id}/students');
      setState(() => _students = ((data['data'] as List?) ?? []).map((e) => e as Map<String, dynamic>).toList());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat siswa: $e')));
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Widget _buildDetail() {
    final k = _selected!;
    return ListView(padding: const EdgeInsets.all(14), children: [
      // Info card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.group, color: AppColors.navy, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k.name, style: AppTextStyles.h3),
              Text(k.subject ?? '', style: AppTextStyles.bodySmall),
            ])),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _detailStat('Siswa', '${k.studentCount ?? 0}', AppColors.green),
            _detailStat('Ujian', '${k.examCount ?? 0}', AppColors.navy),
            _detailStat('TA', k.academicYear ?? '—', AppColors.orange),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      // Daftar Siswa + Nilai
      Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              Text('Daftar Siswa', style: AppTextStyles.h4.copyWith(fontSize: 14)),
              const Spacer(),
              if (_loadingStudents)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              Text('${k.studentCount ?? 0} siswa', style: AppTextStyles.bodySmall),
            ]),
          ),
          const Divider(height: 1),
          if (_students == null && !_loadingStudents)
            const Padding(padding: EdgeInsets.all(24), child: EmptyState(title: 'Memuat...', icon: Icons.hourglass_empty))
          else if (_students!.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: EmptyState(title: 'Belum ada siswa', icon: Icons.people_outline))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _students!.length,
              itemBuilder: (_, i) => _buildStudentTile(_students![i]),
            ),
        ]),
      ),
    ]);
  }

  Widget _buildStudentTile(Map<String, dynamic> s) {
    final grades = (s['grades'] as List?) ?? [];
    final avg = s['average_score'];
    final avgStr = avg != null ? avg.toString() : '-';
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: CircleAvatar(radius: 18, backgroundColor: AppColors.navyLight,
        child: Text(s['name']![0].toUpperCase(), style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 13))),
      title: Text(s['name'] ?? '-', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500, color: AppColors.ink, fontSize: 13.5)),
      subtitle: Row(children: [
        Text('NIS: ${s['nis'] ?? '-'}', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        const SizedBox(width: 12),
        Text('Rata: $avgStr', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.navy, fontWeight: FontWeight.w600)),
      ]),
      children: grades.isEmpty
          ? [const Padding(padding: EdgeInsets.all(12), child: Text('Belum ada nilai', style: TextStyle(color: AppColors.ink3)))]
          : grades.map<Widget>((g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 0.3))),
              child: Row(children: [
                Expanded(child: Text(g['exam_title'] ?? '-', style: AppTextStyles.bodySmall.copyWith(fontSize: 12))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _gradeColor(g['grade']?.toString()).withValues(alpha:.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${g['score'] ?? 0}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _gradeColor(g['grade']?.toString()))),
                ),
                const SizedBox(width: 6),
                Text(g['grade'] ?? '-', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
          )).toList(),
    );
  }

  Color _gradeColor(String? grade) {
    if (grade == null) return AppColors.ink3;
    if (grade.startsWith('A')) return AppColors.green;
    if (grade.startsWith('B')) return AppColors.sky;
    if (grade.startsWith('C')) return AppColors.orange;
    return AppColors.red;
  }

/// Sort by grade level (X < XI < XII) then suffix alphabetically.
int _compareClassNames(String a, String b) {
  final levelA = _gradeLevel(a);
  final levelB = _gradeLevel(b);
  if (levelA != levelB) return levelA.compareTo(levelB);
  return _classSuffix(a).compareTo(_classSuffix(b));
}

int _gradeLevel(String name) {
  if (name.startsWith('XII')) return 3;
  if (name.startsWith('XI'))  return 2;
  if (name.startsWith('X'))   return 1;
  return 0;
}

String _classSuffix(String name) {
  if (name.startsWith('XII')) return name.substring(3);
  if (name.startsWith('XI'))  return name.substring(2);
  if (name.startsWith('X'))   return name.substring(1);
  return name;
}

  Widget _detailStat(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
    Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5)),
  ]);
}

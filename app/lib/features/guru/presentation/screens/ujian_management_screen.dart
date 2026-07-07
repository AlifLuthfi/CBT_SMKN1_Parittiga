import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/guru_models.dart';
import '../../data/guru_repository.dart';

final _examListProvider = FutureProvider.autoDispose.family<List<ExamModel>, String?>(
  (ref, status) => GuruRepository().getExams(status: status),
);

class UjianManagementScreen extends ConsumerStatefulWidget {
  const UjianManagementScreen({super.key});
  @override
  ConsumerState<UjianManagementScreen> createState() => _UjianManagementScreenState();
}

class _UjianManagementScreenState extends ConsumerState<UjianManagementScreen> {
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(_examListProvider(_filterStatus));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manajemen Ujian'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_examListProvider(_filterStatus))),
        ],
      ),
      body: Column(children: [
        // Filter bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip(null,        'Semua'),
              _filterChip('active',    'Aktif'),
              _filterChip('scheduled', 'Terjadwal'),
              _filterChip('draft',     'Draft'),
              _filterChip('ended',     'Selesai'),
            ]),
          ),
        ),
        // List
        Expanded(child: exams.when(
          loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
          error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_examListProvider(_filterStatus))),
          data:    (list) => list.isEmpty
              ? const EmptyState(title: 'Tidak ada ujian', icon: Icons.description_outlined)
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_examListProvider(_filterStatus)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _examCard(list[i]),
                  ),
                ),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateExamSheet(context),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ujian Baru', style: AppTextStyles.button),
      ),
    );
  }

  Widget _filterChip(String? val, String label) {
    final active = _filterStatus == val;
    return GestureDetector(
      onTap: () { setState(() => _filterStatus = val); ref.invalidate(_examListProvider(val)); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.navy : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink3)),
      ),
    );
  }

  Widget _examCard(ExamModel exam) {
    final submitted = exam.submittedCount ?? 0;
    final total     = exam.sessionsCount  ?? 0;
    final pct       = total > 0 ? submitted / total : 0.0;

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
              Text(exam.classRoom?.name ?? '—', style: TextStyle(fontSize: 11.5, color: exam.isActive ? Colors.white60 : AppColors.ink3)),
            ])),
            StatusBadge.fromStatus(exam.status),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          // Tanggal ujian
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

          // Stats row
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _miniStat('Soal',     '${exam.totalQuestions}',     AppColors.navy),
            _miniStat('Peserta',  '$total',                     AppColors.ink),
            _miniStat('Submit',   '$submitted',                 AppColors.green),
            _miniStat('Langgar',  '${exam.violationsCount ?? 0}', AppColors.red),
            _miniStat('KKM',      '${exam.passingGrade.toInt()}', AppColors.amber),
          ]),

          if (exam.isActive) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.border, color: AppColors.green, minHeight: 5),
            ),
            const SizedBox(height: 3),
            Text('$submitted/$total submit (${(pct*100).toStringAsFixed(0)}%)', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],

          const SizedBox(height: 12),
          // Action buttons
          Row(children: [
            if (!exam.isEnded)
              Expanded(child: _actionBtn('Edit', AppColors.navy, Icons.edit_outlined, () => _showEditExamSheet(context, exam))),
            if (exam.isEnded)
              Expanded(child: _actionBtn('Lihat Rekap', AppColors.sky, Icons.bar_chart, () {})),
            if (!exam.isActive && !exam.isEnded) ...[
              const SizedBox(width: 8),
              SizedBox(width: 38, child: OutlinedButton(
                onPressed: () => _deleteExam(exam),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(38,38), side: const BorderSide(color: AppColors.border)),
                child: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
              )),
            ],
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

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) => ElevatedButton.icon(
    onPressed: onTap,
    icon:  Icon(icon, size: 15, color: Colors.white),
    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      minimumSize:     const Size(0, 38),
      padding:         const EdgeInsets.symmetric(horizontal: 12),
    ),
  );

  Future<void> _deleteExam(ExamModel exam) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Hapus Ujian?'),
      content: Text('Hapus "${exam.title}"? Data ini tidak dapat dipulihkan.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          child: const Text('Hapus'),
        ),
      ],
    ));
    if (ok != true) return;
    try {
      await GuruRepository().deleteExam(exam.id);
      if (mounted) {
        ref.invalidate(_examListProvider(_filterStatus));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ujian dihapus'), backgroundColor: AppColors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red));
    }
  }

  void _showEditExamSheet(BuildContext ctx, ExamModel exam) {
    final titleCtrl = TextEditingController(text: exam.title);
    final repo = GuruRepository();
    final formData = Future.wait<dynamic>([repo.getClasses(), repo.getSubjects()]);
    int? selectedClassId = exam.classRoom?.id;
    int? selectedSubjectId;
    int duration = exam.durationMinutes;
    double passingGrade = exam.passingGrade;
    int maxViol = 5;
    DateTime? examDate = exam.startTime != null ? DateTime.tryParse(exam.startTime!) : null;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx2, setS) => Container(
        height: MediaQuery.of(ctx).size.height * .92,
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Row(children: [
            Text('Edit Ujian', style: AppTextStyles.h4),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Batal')),
          ])),
          const Divider(height: 1),
          Expanded(child: FutureBuilder<List<dynamic>>(
            future: formData,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]);
              }
              if (snap.hasError) {
                return ErrorState(message: snap.error.toString(), onRetry: () => Navigator.pop(ctx2));
              }

              final classes = snap.data![0] as List<ClassRoomModel>;
              final subjects = snap.data![1] as List<SubjectModel>;

              return SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Judul Ujian *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 5),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Cth: UH 1 — Aljabar Dasar')),
                const SizedBox(height: 14),
                const Text('Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 5),
                DropdownButtonFormField<int>(
                  initialValue: selectedClassId,
                  decoration: const InputDecoration(hintText: 'Pilih kelas'),
                  items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} · ${c.subject ?? ''}'))).toList(),
                  onChanged: (v) => setS(() => selectedClassId = v),
                ),
                const SizedBox(height: 14),
                const Text('Mata Pelajaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 5),
                DropdownButtonFormField<int>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(hintText: 'Pilih mata pelajaran'),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.questionsCount ?? 0} soal)'))).toList(),
                  onChanged: (v) => setS(() => selectedSubjectId = v),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Durasi (menit)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                    const SizedBox(height: 5),
                    TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '$duration'),
                      onChanged: (v) => duration = int.tryParse(v) ?? duration),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Passing Grade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                    const SizedBox(height: 5),
                    TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '${passingGrade.toInt()}'),
                      onChanged: (v) => passingGrade = double.tryParse(v) ?? passingGrade),
                  ])),
                ]),
                const SizedBox(height: 16),

                // Tanggal ujian
                const Text('Tanggal Ujian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: ctx2, initialDate: examDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (d != null) setS(() => examDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 15, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Text(
                        examDate != null ? '${examDate!.day.toString().padLeft(2,'0')}/${examDate!.month.toString().padLeft(2,'0')}/${examDate!.year}' : 'Pilih tanggal',
                        style: TextStyle(fontSize: 13, color: examDate != null ? AppColors.ink : AppColors.ink3),
                      ),
                      if (examDate != null) const Spacer(),
                      if (examDate != null) GestureDetector(
                        onTap: () => setS(() => examDate = null),
                        child: const Icon(Icons.clear, size: 16, color: AppColors.ink3),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Info LCG
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.auto_fix_high, size: 16, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Soal dan opsi jawaban diacak otomatis (LCG)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11.5))),
                  ]),
                ),
              ]));
            },
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Judul wajib diisi'))); return; }
                try {
                  final eDate = examDate;
                  await repo.updateExam(exam.id, {
                    'title': titleCtrl.text.trim(),
                    if (selectedClassId != null) 'class_id': selectedClassId,
                    if (selectedSubjectId != null) 'subject_id': selectedSubjectId,
                    'duration_minutes': duration,
                    'passing_grade': passingGrade,
                    'max_violations': maxViol,
                    if (eDate != null) 'start_time': eDate.toIso8601String(),
                  });
                  ref.invalidate(_examListProvider(_filterStatus));
                  if (ctx2.mounted) { Navigator.pop(ctx2); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ujian diperbarui'))); }
                } catch (e) {
                  if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ),
        ]),
      )),
    );
  }

  void _showCreateExamSheet(BuildContext ctx) {
    final titleCtrl = TextEditingController();
    final repo = GuruRepository();
    final formData = Future.wait<dynamic>([repo.getClasses(), repo.getSubjects()]);
    int? selectedClassId;
    int? selectedSubjectId;
    int duration = 90; double passingGrade = 70; int maxViol = 5;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx2, setS) => Container(
        height: MediaQuery.of(ctx).size.height * .92,
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Row(children: [
            Text('Buat Ujian Baru', style: AppTextStyles.h4),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Batal')),
          ])),
          const Divider(height: 1),
          Expanded(child: FutureBuilder<List<dynamic>>(
            future: formData,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]);
              }
              if (snap.hasError) {
                return ErrorState(message: snap.error.toString(), onRetry: () => Navigator.pop(ctx2));
              }

              final classes = snap.data![0] as List<ClassRoomModel>;
              final subjects = snap.data![1] as List<SubjectModel>;

              return SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Judul Ujian *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 5),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Cth: UH 1 — Aljabar Dasar')),
                const SizedBox(height: 14),
                const Text('Kelas *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 5),
                DropdownButtonFormField<int>(
                  initialValue: selectedClassId,
                  decoration: const InputDecoration(hintText: 'Pilih kelas'),
                  items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} · ${c.subject ?? ''}'))).toList(),
                  onChanged: (v) => setS(() => selectedClassId = v),
                ),
                const SizedBox(height: 14),
                const Text('Mata Pelajaran *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 5),
                DropdownButtonFormField<int>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(hintText: 'Pilih mata pelajaran'),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.questionsCount ?? 0} soal)'))).toList(),
                  onChanged: (v) => setS(() => selectedSubjectId = v),
                ),
                if (selectedSubjectId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 13, color: AppColors.navy),
                      const SizedBox(width: 6),
                      Text('Soal akan diambil dari bank soal mata pelajaran ini', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11.5)),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Durasi (menit)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                    const SizedBox(height: 5),
                    TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '90'), onChanged: (v) => duration = int.tryParse(v) ?? 90),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Passing Grade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                    const SizedBox(height: 5),
                    TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '70'), onChanged: (v) => passingGrade = double.tryParse(v) ?? 70),
                  ])),
                ]),
                const SizedBox(height: 16),

                // Info LCG otomatis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.auto_fix_high, size: 16, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pengacakan LCG Otomatis', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('Soal dan opsi jawaban akan diacak otomatis menggunakan metode LCG. Hasil hanya menampilkan jawaban salah.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11)),
                    ])),
                  ]),
                ),
              ]));
            },
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Judul wajib diisi'))); return; }
                if (selectedClassId == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pilih kelas'))); return; }
                if (selectedSubjectId == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pilih mata pelajaran'))); return; }
                try {
                  await repo.createExam({
                    'title': titleCtrl.text.trim(),
                    'class_id': selectedClassId,
                    'subject_id': selectedSubjectId,
                    'duration_minutes': duration,
                    'passing_grade': passingGrade,
                    'max_violations': maxViol,
                  });
                  ref.invalidate(_examListProvider(_filterStatus));
                  if (ctx2.mounted) { Navigator.pop(ctx2); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ujian dibuat'))); }
                } catch (e) {
                  if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Buat Ujian'),
            ),
          ),
        ]),
      )),
    );
  }
}

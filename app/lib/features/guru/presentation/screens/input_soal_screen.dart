import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/guru_models.dart';
import '../../data/guru_repository.dart';

final _inpSubjectsProvider = FutureProvider.autoDispose((_) => GuruRepository().getSubjects());
final _inpSoalProvider = FutureProvider.autoDispose.family<List<QuestionModel>, int?>(
  (ref, subjectId) => GuruRepository().getQuestions(subjectId: subjectId?.toString()),
);

class InputSoalScreen extends ConsumerStatefulWidget {
  const InputSoalScreen({super.key});
  @override
  ConsumerState<InputSoalScreen> createState() => _InputSoalScreenState();
}

class _InputSoalScreenState extends ConsumerState<InputSoalScreen> {
  int? _selectedSubjectId;
  int? _editSubjectId;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(_inpSubjectsProvider);
    final soal = _selectedSubjectId != null ? ref.watch(_inpSoalProvider(_selectedSubjectId)) : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_selectedSubjectId != null ? 'Input Soal' : 'Mata Pelajaran'),
        leading: _selectedSubjectId != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedSubjectId = null))
            : null,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _refresh()),
          if (_selectedSubjectId != null)
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: 'Import Excel/CSV',
              onPressed: () => _importSoalFlow(context),
            ),
        ],
      ),
      body: _selectedSubjectId != null ? _soalListView(soal) : _subjectListView(subjects),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedSubjectId != null
            ? () => _showCreateSoalDialog()
            : () => _showSubjectDialog(),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_selectedSubjectId != null ? 'Tambah Soal' : 'Tambah Mapel', style: AppTextStyles.button),
      ),
    );
  }

  void _refresh() {
    ref.invalidate(_inpSubjectsProvider);
    if (_selectedSubjectId != null) ref.invalidate(_inpSoalProvider(_selectedSubjectId));
  }

  // ── SUBJECT LIST (web subject card grid) ────────────────
  Widget _subjectListView(AsyncValue<List<SubjectModel>> subjects) {
    return subjects.when(
      loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile()]),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_inpSubjectsProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(title: 'Belum ada mata pelajaran', icon: Icons.book_outlined);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_inpSubjectsProvider),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${list.length} mapel — klik mapel untuk kelola soal',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _subjectCard(list[i]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _subjectCard(SubjectModel s) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSubjectId = s.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.book, color: AppColors.navy, size: 24),
          ),
          const SizedBox(height: 10),
          Text(s.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${s.questionsCount ?? 0} soal', style: AppTextStyles.bodySmall.copyWith(fontFamily: 'JetBrainsMono', color: AppColors.ink3)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Edit icon
            GestureDetector(
              onTap: () => _showSubjectDialog(existing: s),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink3),
              ),
            ),
            const SizedBox(width: 8),
            // Delete icon
            GestureDetector(
              onTap: () => _deleteSubject(s),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── SOAL LIST (web table) ───────────────────────────────
  Widget _soalListView(AsyncValue<List<QuestionModel>>? soal) {
    if (soal == null) return const SizedBox.shrink();
    return soal.when(
      loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile()]),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_inpSoalProvider(_selectedSubjectId))),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(title: 'Belum ada soal', icon: Icons.quiz_outlined);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_inpSoalProvider(_selectedSubjectId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: list.length,
            itemBuilder: (_, i) => _soalRow(list[i]),
          ),
        );
      },
    );
  }

  /// Table-like row: Soal | Gambar | Aksi (lihat, edit, hapus)
  Widget _soalRow(QuestionModel q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          // Soal text
          Expanded(
            flex: 3,
            child: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 13.5)),
          ),
          const SizedBox(width: 12),
          // Image indicator
          SizedBox(
            width: 40,
            child: q.imageUrl != null
                ? const Icon(Icons.image, size: 18, color: AppColors.navy)
                : Text('-', style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink3)),
          ),
          // Actions
          Row(mainAxisSize: MainAxisSize.min, children: [
            _actionBtn(Icons.info_outline, AppColors.navy, () => _showInfoSoalDialog(q)),
            const SizedBox(width: 4),
            _actionBtn(Icons.edit_outlined, AppColors.amber, () => _showEditSoalDialog(q)),
            const SizedBox(width: 4),
            _actionBtn(Icons.delete_outline, AppColors.red, () => _hapusSoal(q)),
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ── ACTIONS ─────────────────────────────────────────────
  void _hapusSoal(QuestionModel q) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Hapus Soal?'),
      content: Text('Hapus "${q.questionText.substring(0, q.questionText.length.clamp(0, 50))}..."?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await GuruRepository().deleteQuestion(q.id);
              ref.invalidate(_inpSoalProvider(_selectedSubjectId));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soal dihapus')));
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Hapus'),
        ),
      ],
    ));
  }

  void _deleteSubject(SubjectModel s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Hapus Mapel?'),
      content: Text('Hapus "${s.name}"? Semua soal di dalamnya ikut terhapus.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            try {
              await GuruRepository().deleteSubject(s.id);
              ref.invalidate(_inpSubjectsProvider);
              if (mounted) Navigator.pop(context);
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Hapus'),
        ),
      ],
    ));
  }

  void _importSoalFlow(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InputImportSoalSheet(
        subjectId: _selectedSubjectId,
        onImported: () => ref.invalidate(_inpSoalProvider(_selectedSubjectId)),
      ),
    );
  }

  // ── SUBJECT DIALOG ─────────────────────────────────────
  void _showSubjectDialog({SubjectModel? existing}) {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(existing == null ? 'Tambah Mapel' : 'Edit Nama Mapel'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nama Mata Pelajaran', hintText: 'Cth: Matematika Wajib')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: () async {
          if (ctrl.text.trim().isEmpty) return;
          try {
            if (existing != null) {
              await GuruRepository().updateSubject(existing.id, ctrl.text.trim());
            } else {
              await GuruRepository().createSubject(ctrl.text.trim());
            }
            ref.invalidate(_inpSubjectsProvider);
            if (mounted) Navigator.pop(context);
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
        }, child: const Text('Simpan')),
      ],
    ));
  }

  // ── INFO SOAL DIALOG (web info modal) ──────────────────
  void _showInfoSoalDialog(QuestionModel q) {
    // Image dimuat oleh _LazyNetworkImage di post-frame agar tidak collide transisi
    showDialog(context: context, builder: (ctx) => AlertDialog(
      contentPadding: const EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // Subject
          _infoRow('Mata Pelajaran', q.subjectName ?? '-'),
          const SizedBox(height: 12),
          // Question text
          _infoRow('Teks Soal', null),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
            child: Text(q.questionText, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.6)),
          ),
          // Image
          if (q.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:_SafeNetworkImage(url: q.imageUrl!, height: 140),
            ),
          ],
          const SizedBox(height: 12),
          // Options
          _infoRow('Opsi Jawaban', null),
          const SizedBox(height: 6),
          ...(q.options ?? {}).entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: e.key == q.correctAnswer ? AppColors.greenLight : AppColors.bg,
              borderRadius: BorderRadius.circular(6),
              border: e.key == q.correctAnswer ? Border.all(color: AppColors.green) : null,
            ),
            child: Row(children: [
              Text('${e.key}.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                color: e.key == q.correctAnswer ? AppColors.green : AppColors.ink3)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink))),
              if (e.key == q.correctAnswer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(4)),
                  child: const Text('✓ Benar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
            ]),
          )),
          // Explanation
          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow('Pembahasan', null),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(6)),
              child: Text(q.explanation!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy)),
            ),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
      ],
    ));
  }

  Widget _infoRow(String label, String? value) {
    if (value != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.ink3)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      ]);
    }
    return Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.ink3));
  }

  // ── CREATE SOAL DIALOG (web create modal) ──────────────
  void _showCreateSoalDialog() {
    _editSubjectId = _selectedSubjectId;
    _showSoalDialog(null);
  }

  void _showEditSoalDialog(QuestionModel q) {
    _editSubjectId = q.subjectId ?? _selectedSubjectId;
    _showSoalDialog(q);
  }

  void _showSoalDialog(QuestionModel? existing) {
    final textCtrl = TextEditingController(text: existing?.questionText ?? '');
    final explCtrl = TextEditingController(text: existing?.explanation ?? '');
    final optCtrls = List.generate(5, (i) {
      final keys = ['A', 'B', 'C', 'D', 'E'];
      return TextEditingController(text: existing?.options?[keys[i]] ?? '');
    });
    String correctKey = existing?.correctAnswer ?? 'A';
    String? imageFile;
    Uint8List? imageBytes;
    String? imageFileName;
    bool removeImage = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(existing == null ? 'Tambah Soal' : 'Edit Soal'),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                // Subject dropdown (like web)
                const Text('Mapel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 4),
                Consumer(builder: (ctx, ref, _) {
                  final subjects = ref.watch(_inpSubjectsProvider);
                  return subjects.when(
                    loading: () => const SizedBox(height: 38, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _editSubjectId ?? list.first.id,
                          isExpanded: true,
                          items: list.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (v) => setS(() => _editSubjectId = v),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                // Question text (like web textarea)
                const Text('Teks Soal *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 4),
                TextField(controller: textCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Tulis pertanyaan di sini...')),
                const SizedBox(height: 12),
                // Image (like web)
                const Text('Gambar Soal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: imageFile != null || imageBytes != null ? 'Gambar dipilih' : 'Pilih gambar (opsional)',
                        prefixIcon: const Icon(Icons.image_outlined, size: 18),
                        suffixIcon: (imageFile != null || imageBytes != null)
                            ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setS(() { imageFile = null; imageBytes = null; imageFileName = null; }))
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: () async {
                      final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
                      if (picked != null && picked.files.isNotEmpty) {
                        final f = picked.files.single;
                        WidgetsBinding.instance.endOfFrame.then((_) {
                          if (ctx.mounted) setS(() {
                            removeImage = false;
                            if (f.bytes != null) { imageBytes = f.bytes; imageFileName = f.name; }
                            else if (f.path != null) { imageFile = f.path; }
                          });
                        });
                      }
                    },
                  ),
                ]),
                if (imageFile != null && !kIsWeb)
                  Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(imageFile!), height: 100, width: double.infinity, fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ))
                else if (imageBytes != null)
                  Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(imageBytes!, height: 100, width: double.infinity, fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ))
                else if (existing?.imageUrl != null)
                  Padding(padding: const EdgeInsets.only(top: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _SafeNetworkImage(url: existing!.imageUrl!, height: 100),
                    ),
                    Row(children: [
                      Checkbox(value: removeImage, onChanged: (v) => setS(() => removeImage = v ?? false), visualDensity: VisualDensity.compact),
                      const Text('Hapus gambar', style: TextStyle(fontSize: 12, color: AppColors.red)),
                    ]),
                  ])),
                const SizedBox(height: 12),
                // Options (like web: A-E with radio for correct)
                const Text('Opsi Jawaban', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 6),
                ...['A', 'B', 'C', 'D', 'E'].asMap().entries.map((entry) {
                  final i = entry.key;
                  final k = entry.value;
                  final isCorrect = correctKey == k;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      SizedBox(width: 20, child: Text('$k.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.ink3))),
                      Expanded(child: TextField(controller: optCtrls[i],
                        decoration: InputDecoration(hintText: 'Opsi $k', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setS(() => correctKey = k),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCorrect ? AppColors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isCorrect ? AppColors.green : AppColors.border),
                          ),
                          child: Text('Benar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: isCorrect ? Colors.white : AppColors.ink3)),
                        ),
                      ),
                    ]),
                  );
                }),
                const SizedBox(height: 12),
                // Explanation
                const Text('Pembahasan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(height: 4),
                TextField(controller: explCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Tulis pembahasan jawaban...')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final text = textCtrl.text.trim();
                final eText = optCtrls[4].text.trim();
                final options = {'A': optCtrls[0].text.trim(), 'B': optCtrls[1].text.trim(), 'C': optCtrls[2].text.trim(), 'D': optCtrls[3].text.trim()};
                if (eText.isNotEmpty) options['E'] = eText;
                if (text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teks soal tidak boleh kosong'))); return; }
                if (options.values.any((v) => v.isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua opsi A-D wajib diisi'))); return; }
                if (_editSubjectId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih mata pelajaran'))); return; }
                try {
                  final repo = GuruRepository();
                  final hasImage = imageFile != null || imageBytes != null;
                  if (existing != null) {
                    if (hasImage || removeImage) {
                      await repo.updateQuestionWithImage(
                        id: existing.id, questionText: text, options: options,
                        correctAnswer: correctKey,
                        explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                        imagePath: imageFile, imageBytes: imageBytes, imageName: imageFileName,
                        removeImage: removeImage,
                        subjectId: _editSubjectId,
                      );
                    } else {
                      await repo.updateQuestion(existing.id, {
                        'question_text': text, 'options': options, 'correct_answer': correctKey,
                        'subject_id': _editSubjectId,
                        if (explCtrl.text.trim().isNotEmpty) 'explanation': explCtrl.text.trim(),
                      });
                    }
                  } else {
                    await repo.createQuestionWithImage(
                      questionText: text, options: options, correctAnswer: correctKey,
                      subjectId: _editSubjectId,
                      explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                      imagePath: imageFile, imageBytes: imageBytes, imageName: imageFileName,
                    );
                  }
                  ref.invalidate(_inpSoalProvider(_selectedSubjectId));
                  if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soal disimpan'))); }
                } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
              },
              child: Text(existing == null ? 'Simpan Soal' : 'Simpan'),
            ),
          ],
        );
      }),
    );
  }
}

// ── Safe network image — defers render if image syncloaded during dialog transition ──
class _SafeNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  const _SafeNetworkImage({required this.url, required this.height});

  String get _resolved => AppConstants.resolveImageUrl(url) ?? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (_, constraints) {
        return Image.network(_resolved, width: constraints.maxWidth, height: height,
          fit: BoxFit.contain,
          frameBuilder: (_, child, frame, wasSync) {
            if (wasSync == true) return child;
            if (frame == null) {
              return SizedBox(
                width: constraints.maxWidth, height: height,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return child;
          },
          errorBuilder: (_, _, _) => SizedBox(width: constraints.maxWidth, height: height,
            child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.ink3, size: 32)),
          ),
        );
      }),
    );
  }
}

// ── IMPORT SOAL SHEET ─────────────────────────────────────
class _InputImportSoalSheet extends StatefulWidget {
  final int? subjectId;
  final VoidCallback onImported;
  const _InputImportSoalSheet({this.subjectId, required this.onImported});

  @override
  State<_InputImportSoalSheet> createState() => _InputImportSoalSheetState();
}

class _InputImportSoalSheetState extends State<_InputImportSoalSheet> {
  String? _filePath;
  Uint8List? _fileBytes;
  String? _fileName;
  InputScreenState _screenState = InputScreenState.pick;
  QuestionImportPreview? _preview;
  QuestionImportModel? _result;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * (_screenState == InputScreenState.pick ? .45 : .85),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: Row(children: [
          Text(_titleText, style: AppTextStyles.h4),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ])),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  String get _titleText {
    switch (_screenState) {
      case InputScreenState.pick: return 'Import Soal';
      case InputScreenState.preview: return 'Preview Import';
      case InputScreenState.result: return 'Hasil Import';
    }
  }

  Widget _buildBody() {
    switch (_screenState) {
      case InputScreenState.pick: return _pickFileView();
      case InputScreenState.preview: return _previewView();
      case InputScreenState.result: return _resultView();
    }
  }

  Widget _pickFileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(9)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.navy),
            const SizedBox(width: 8),
            Expanded(child: Text('Upload file Excel (.xlsx) atau CSV. Gunakan template untuk format yang benar.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy))),
          ]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border2, width: 2, strokeAlign: BorderSide.strokeAlignInside),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.bg,
            ),
            child: Column(children: [
              Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.navy.withValues(alpha: .4)),
              const SizedBox(height: 10),
              Text('Ketuk untuk pilih file', style: AppTextStyles.body.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 4),
              Text('.xlsx, .xls, .csv — Maks 10 MB', style: AppTextStyles.bodySmall),
            ]),
          ),
        ),
        if (_filePath != null || _fileName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 16, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(_fileName ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.green, fontWeight: FontWeight.w600))),
              IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => setState(() { _filePath = null; _fileBytes = null; _fileName = null; })),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download Template'),
          ),
        ),
        const Spacer(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_filePath == null && _fileBytes == null) || _loading ? null : _doPreview,
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Preview & Import'),
          ),
        ),
      ]),
    );
  }

  Widget _previewView() {
    if (_preview == null) return const Center(child: CircularProgressIndicator());
    final p = _preview!;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14), color: AppColors.bg,
        child: Row(children: [
          _statChip('${p.totalRows}', 'Total Baris', AppColors.navy),
          const SizedBox(width: 8),
          _statChip('${p.validCount}', 'Valid', AppColors.green),
          const SizedBox(width: 8),
          _statChip('${p.errorCount}', 'Error', p.errorCount > 0 ? AppColors.red : AppColors.ink3),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: p.preview.length + 1,
        itemBuilder: (_, i) {
          if (i == p.preview.length) {
            return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _executeImport,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text('Import ${p.validCount} Soal'),
              ),
            ));
          }
          return _previewRow(p.preview[i]);
        },
      )),
    ]);
  }

  Widget _previewRow(QuestionImportPreviewRow row) {
    final isOk = row.status == 'ok';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOk ? Colors.white : AppColors.redLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOk ? AppColors.border : AppColors.red.withValues(alpha: .3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: isOk ? AppColors.greenLight : AppColors.redLight, borderRadius: BorderRadius.circular(4)),
            child: Text('Baris ${row.row}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'JetBrainsMono'))),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: isOk ? AppColors.green.withValues(alpha: .1) : AppColors.red.withValues(alpha: .1), borderRadius: BorderRadius.circular(4)),
            child: Text(isOk ? 'OK' : 'Error', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isOk ? AppColors.green : AppColors.red))),
          if (!isOk && row.errors != null && row.errors!.isNotEmpty) ...[const Spacer(), const Icon(Icons.warning_amber, size: 14, color: AppColors.red)],
        ]),
        const SizedBox(height: 6),
        if (isOk) ...[
          Text(row.questionText ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(children: [
            if (row.options != null) ...row.options!.entries.take(4).map((e) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: e.key == row.correctAnswer ? AppColors.green.withValues(alpha: .15) : AppColors.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: e.key == row.correctAnswer ? AppColors.green : AppColors.border, width: e.key == row.correctAnswer ? 1 : .5)),
                child: Text('${e.key}. ${e.value}', style: TextStyle(fontSize: 9, fontWeight: e.key == row.correctAnswer ? FontWeight.w600 : FontWeight.w400, color: e.key == row.correctAnswer ? AppColors.green : AppColors.ink3))),
            )),
          ]),
        ] else ...[
          ...(row.errors ?? []).map((e) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(e, style: const TextStyle(fontSize: 11, color: AppColors.red)))),
        ],
      ]),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: color, fontFamily: 'JetBrainsMono')),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ])));
  }

  Widget _resultView() {
    final r = _result;
    if (r == null) return const SizedBox.shrink();
    final hasError = r.errorCount > 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        const SizedBox(height: 20),
        Icon(hasError ? Icons.warning_amber_rounded : Icons.check_circle_outline, size: 64, color: hasError ? AppColors.amber : AppColors.green),
        const SizedBox(height: 12),
        Text(r.successCount > 0 ? 'Import Berhasil!' : 'Import Gagal', style: AppTextStyles.h2.copyWith(color: hasError ? AppColors.amber : AppColors.green)),
        const SizedBox(height: 8),
        Text('${r.successCount} soal berhasil diimpor', style: AppTextStyles.body),
        if (r.errorCount > 0) Text('${r.errorCount} error', style: AppTextStyles.body.copyWith(color: AppColors.red)),
        const SizedBox(height: 16),
        if (r.errors != null && r.errors!.isNotEmpty) Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Detail Error:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.red)),
            const SizedBox(height: 6),
            ...r.errors!.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e, style: const TextStyle(fontSize: 11, color: AppColors.red)))),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: () { widget.onImported(); Navigator.pop(context); }, child: const Text('Selesai'))),
      ]),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls', 'csv'], allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    setState(() {
      if (f.bytes != null) { _fileBytes = f.bytes; _filePath = null; }
      else if (f.path != null) { _filePath = f.path; _fileBytes = null; }
      _fileName = f.name;
    });
  }

  Future<void> _downloadTemplate() async {
    try { await GuruRepository().downloadTemplate(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template tersimpan'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  Future<void> _doPreview() async {
    setState(() => _loading = true);
    try {
      final repo = GuruRepository();
      final p = _fileBytes != null
          ? await repo.previewImportBytes(_fileBytes!, _fileName ?? 'file.xlsx')
          : await repo.previewImport(_filePath!, _fileName ?? 'file.xlsx');
      setState(() { _preview = p; _screenState = InputScreenState.preview; _loading = false; });
    } catch (e) { setState(() => _loading = false); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  Future<void> _executeImport() async {
    setState(() => _loading = true);
    try {
      final repo = GuruRepository();
      final r = _fileBytes != null
          ? await repo.executeImportBytes(_fileBytes!, _fileName ?? 'file.xlsx', subjectId: widget.subjectId)
          : await repo.executeImport(_filePath!, _fileName ?? 'file.xlsx', subjectId: widget.subjectId);
      setState(() { _result = r; _screenState = InputScreenState.result; _loading = false; });
    } catch (e) { setState(() => _loading = false); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }
}

enum InputScreenState { pick, preview, result }

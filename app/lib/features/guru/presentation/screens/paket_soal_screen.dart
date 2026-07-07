import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/guru_models.dart';
import '../../data/guru_repository.dart';

final _subjectsProvider = FutureProvider.autoDispose((_) => GuruRepository().getSubjects());
final _soalBySubjectProvider = FutureProvider.autoDispose.family<List<QuestionModel>, int>(
  (ref, subjectId) => GuruRepository().getQuestions(subjectId: subjectId.toString()),
);

class PaketSoalScreen extends ConsumerStatefulWidget {
  const PaketSoalScreen({super.key});
  @override
  ConsumerState<PaketSoalScreen> createState() => _PaketSoalScreenState();
}

class _PaketSoalScreenState extends ConsumerState<PaketSoalScreen> {
  int? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(_subjectsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_selectedSubjectId != null ? 'Bank Soal' : 'Mata Pelajaran'),
        leading: _selectedSubjectId != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedSubjectId = null))
            : null,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            ref.invalidate(_subjectsProvider);
            if (_selectedSubjectId != null) ref.invalidate(_soalBySubjectProvider(_selectedSubjectId!));
          }),
        ],
      ),
      body: _selectedSubjectId != null ? _soalList() : _subjectList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedSubjectId != null
            ? () => _showSoalSheet(context, null)
            : () => _showSubjectDialog(context),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_selectedSubjectId != null ? 'Tambah Soal' : 'Tambah Mapel', style: AppTextStyles.button),
      ),
    );
  }

  // ── SUBJECT LIST ──────────────────────────────────────────
  Widget _subjectList() {
    final subjects = ref.watch(_subjectsProvider);
    return subjects.when(
      loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile()]),
      error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_subjectsProvider)),
      data:    (list) => list.isEmpty
          ? const EmptyState(title: 'Belum ada mata pelajaran', icon: Icons.book_outlined)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(_subjectsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: list.length,
                itemBuilder: (_, i) => _subjectCard(list[i]),
              ),
            ),
    );
  }

  Widget _subjectCard(SubjectModel s) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.book, color: AppColors.navy, size: 22),
      ),
      title: Text(s.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('${s.questionsCount ?? 0} soal', style: AppTextStyles.bodySmall),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showSubjectDialog(context, existing: s)),
        IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.red), onPressed: () => _deleteSubject(s)),
      ]),
      onTap: () => setState(() => _selectedSubjectId = s.id),
    ),
  );

  void _showSubjectDialog(BuildContext ctx, {SubjectModel? existing}) {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text(existing == null ? 'Tambah Mapel' : 'Edit Mapel'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nama Mata Pelajaran', hintText: 'Cth: Matematika Wajib')),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(), child: const Text('Batal', style: TextStyle(color: AppColors.red))),
        ElevatedButton(onPressed: () async {
          if (ctrl.text.trim().isEmpty) return;
          try {
            if (existing != null) {
              await GuruRepository().updateSubject(existing.id, ctrl.text.trim());
            } else {
              await GuruRepository().createSubject(ctrl.text.trim());
            }
            ref.invalidate(_subjectsProvider);
            if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
          } catch (e) {
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }, child: const Text('Simpan')),
      ],
    ));
  }

  void _deleteSubject(SubjectModel s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Hapus Mapel?'),
      content: Text('Hapus "${s.name}"? Semua soal di dalamnya ikut terhapus.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            try {
              await GuruRepository().deleteSubject(s.id);
              ref.invalidate(_subjectsProvider);
              if (mounted) Navigator.of(context, rootNavigator: true).pop();
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Hapus'),
        ),
      ],
    ));
  }

  // ── SOAL LIST (per subject) ───────────────────────────────
  Widget _soalList() {
    final soal = ref.watch(_soalBySubjectProvider(_selectedSubjectId!));
    return soal.when(
      loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile()]),
      error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_soalBySubjectProvider(_selectedSubjectId!))),
      data:    (list) => list.isEmpty
          ? const EmptyState(title: 'Belum ada soal', icon: Icons.quiz_outlined)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(_soalBySubjectProvider(_selectedSubjectId!)),
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: list.length,
                itemBuilder: (_, i) => _soalTile(list[i]),
              ),
            ),
    );
  }

  Widget _soalTile(QuestionModel q) {
    final diffColor = {'easy': AppColors.green, 'medium': AppColors.amber, 'hard': AppColors.red}[q.difficulty] ?? AppColors.ink3;
    final diffLabel = {'easy': 'Mudah', 'medium': 'Sedang', 'hard': 'Sulit'}[q.difficulty] ?? q.difficulty;
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 13.5)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: diffColor.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
              child: Text(diffLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: diffColor))),
            const SizedBox(width: 6),
            if (q.imageUrl != null) const Icon(Icons.image, size: 13, color: AppColors.navy),
            if (q.categoryName != null) Text(q.categoryName!, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            const Spacer(),
            Text('Bobot: ${q.weight}', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ]),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.ink3),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit',   child: const Text('Edit'),   onTap: () => _showSoalSheet(context, q)),
            PopupMenuItem(value: 'delete', child: const Text('Hapus', style: TextStyle(color: AppColors.red)), onTap: () => _hapusSoal(q)),
          ],
        ),
      ),
    );
  }

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
              ref.invalidate(_soalBySubjectProvider(_selectedSubjectId!));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soal dihapus')));
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Hapus'),
        ),
      ],
    ));
  }

  // ── SOAL FORM ──────────────────────────────────────────
  void _showSoalSheet(BuildContext context, QuestionModel? existing) {
    final textCtrl  = TextEditingController(text: existing?.questionText ?? '');
    final explCtrl  = TextEditingController(text: existing?.explanation  ?? '');
    String diff     = existing?.difficulty   ?? 'medium';
    final optCtrls  = List.generate(5, (i) {
      final keys  = ['A','B','C','D','E'];
      return TextEditingController(text: existing?.options?[keys[i]] ?? '');
    });
    String correctKey = existing?.correctAnswer ?? 'A';
    String? imageFile; // native: path string
    Uint8List? imageBytes; String? imageFileName; // web: bytes + filename

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return Container(
          height: MediaQuery.of(context).size.height * .92,
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Row(children: [
              Text(existing == null ? 'Tambah Soal' : 'Edit Soal', style: AppTextStyles.h4),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ])),
            const Divider(height: 1),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(9)),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Text('Tipe soal: Pilihan Ganda', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 14),

              const Text('Pertanyaan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
              const SizedBox(height: 5),
              TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Tulis pertanyaan di sini...')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: imageFile != null || imageBytes != null ? 'Gambar dipilih' : 'Gambar soal (opsional)',
                    prefixIcon: const Icon(Icons.image_outlined, size: 18),
                    suffixIcon: imageFile != null || imageBytes != null
                        ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setS(() { imageFile = null; imageBytes = null; imageFileName = null; }))
                        : null,
                  ),
                )),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () async {
                    final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
                    if (picked != null && picked.files.isNotEmpty) {
                      final f = picked.files.single;
                      if (f.bytes != null) {
                        setS(() { imageBytes = f.bytes; imageFileName = f.name; });
                      } else if (f.path != null) {
                        setS(() { imageFile = f.path; });
                      }
                    }
                  },
                ),
              ]),
              if (imageFile != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(imageFile!), height: 120, width: double.infinity, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text('Gagal memuat gambar', style: TextStyle(color: AppColors.red, fontSize: 11)),
                  ),
                ))
              else if (imageBytes != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes!, height: 120, width: double.infinity, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text('Gagal memuat gambar', style: TextStyle(color: AppColors.red, fontSize: 11)),
                  ),
                ))
              else if (existing?.imageUrl != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(existing!.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )),
              const SizedBox(height: 14),

              const Text('Pilihan Jawaban', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
              const SizedBox(height: 8),
              ...['A','B','C','D','E'].asMap().entries.map((entry) {
                final i = entry.key; final k = entry.value;
                final isCorrect = correctKey == k;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: isCorrect ? AppColors.green : AppColors.border, width: isCorrect ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(8),
                    color: isCorrect ? AppColors.greenLight : AppColors.surface,
                  ),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => setS(() => correctKey = k),
                      child: Container(
                        width: 36, height: 46,
                        decoration: BoxDecoration(color: isCorrect ? AppColors.green : AppColors.bg, borderRadius: const BorderRadius.horizontal(left: Radius.circular(7))),
                        child: Center(child: Text(k, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w700, color: isCorrect ? Colors.white : AppColors.ink3))),
                      ),
                    ),
                    Expanded(child: TextField(controller: optCtrls[i], decoration: InputDecoration(hintText: 'Opsi $k...', border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)))),
                    if (isCorrect) const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.check_circle, size: 16, color: AppColors.green)),
                  ]),
                );
              }),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 13, color: AppColors.navy),
                  const SizedBox(width: 6),
                  Text('Ketuk huruf kunci untuk menandai jawaban benar', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11.5)),
                ]),
              ),
              const SizedBox(height: 14),

              const Text('Tingkat Kesulitan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
              const SizedBox(height: 8),
              Row(children: [
                {'val':'easy',   'label':'Mudah',  'color': AppColors.green},
                {'val':'medium', 'label':'Sedang', 'color': AppColors.amber},
                {'val':'hard',   'label':'Sulit',  'color': AppColors.red},
              ].map((d) {
                final active = diff == d['val'];
                final c = d['color'] as Color;
                return Expanded(child: GestureDetector(
                  onTap: () => setS(() => diff = d['val'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? c.withOpacity(.12) : AppColors.bg,
                      border: Border.all(color: active ? c : AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(d['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? c : AppColors.ink3)),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.scale_outlined, size: 16, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bobot otomatis', style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text((() {
                        final w = {'easy': 1, 'medium': 2, 'hard': 3}[diff] ?? 1;
                        final label = {'easy': 'Mudah = 1×', 'medium': 'Sedang = 2×', 'hard': 'Sulit = 3×'}[diff] ?? '';
                        return '$label — Bobot soal $w poin';
                      })(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy, fontSize: 11.5)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
                    ),
                    child: Text('×${{'easy': 1, 'medium': 2, 'hard': 3}[diff] ?? 1}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy, fontFamily: 'JetBrainsMono')),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              const Text('Pembahasan (opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
              const SizedBox(height: 5),
              TextField(controller: explCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Tulis pembahasan jawaban...')),
              const SizedBox(height: 20),
            ]))),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: ElevatedButton(
                onPressed: () async {
                  final text = textCtrl.text.trim();
                  final eText = optCtrls[4].text.trim();
                  final options = {'A': optCtrls[0].text.trim(), 'B': optCtrls[1].text.trim(), 'C': optCtrls[2].text.trim(), 'D': optCtrls[3].text.trim()};
                  if (eText.isNotEmpty) options['E'] = eText;
                  if (text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teks soal tidak boleh kosong'))); return; }
                  if (options.values.any((v) => v.isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua opsi A-D wajib diisi'))); return; }
                  try {
                    final repo = GuruRepository();
                    final hasImage = imageFile != null || imageBytes != null;
                    if (existing != null) {
                      if (hasImage) {
                        await repo.updateQuestionWithImage(
                          id: existing.id, questionText: text, options: options,
                          correctAnswer: correctKey, difficulty: diff,
                          weight: ({'easy': 1, 'medium': 2, 'hard': 3}[diff] ?? 1).toDouble(),
                          explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                          imagePath: imageFile, imageBytes: imageBytes, imageName: imageFileName,
                        );
                      } else {
                        await repo.updateQuestion(existing.id, {
                          'question_text': text, 'options': options, 'correct_answer': correctKey,
                          'difficulty': diff, 'subject_id': _selectedSubjectId,
                          if (explCtrl.text.trim().isNotEmpty) 'explanation': explCtrl.text.trim(),
                        });
                      }
                    } else {
                      await repo.createQuestionWithImage(
                        questionText: text, options: options, correctAnswer: correctKey,
                        difficulty: diff, subjectId: _selectedSubjectId,
                        weight: ({'easy': 1, 'medium': 2, 'hard': 3}[diff] ?? 1).toDouble(),
                        explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                        imagePath: imageFile, imageBytes: imageBytes, imageName: imageFileName,
                      );
                    }
                    ref.invalidate(_soalBySubjectProvider(_selectedSubjectId!));
                    if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soal disimpan'))); }
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: Text(existing == null ? 'Simpan Soal' : 'Update Soal'),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

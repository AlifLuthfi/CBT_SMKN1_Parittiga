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

final _soalProvider = FutureProvider.autoDispose.family<List<QuestionModel>, String?>(
  (ref, difficulty) => GuruRepository().getQuestions(difficulty: difficulty),
);

class SoalScreen extends ConsumerStatefulWidget {
  const SoalScreen({super.key});
  @override
  ConsumerState<SoalScreen> createState() => _SoalScreenState();
}

class _SoalScreenState extends ConsumerState<SoalScreen> {
  String? _filterDiff;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final soal = ref.watch(_soalProvider(_filterDiff));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Bank Soal'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_soalProvider(_filterDiff))),
        ],
      ),
      body: Column(children: [
        // Search + filter bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(14,10,14,10),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari soal...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip(null,     'Semua'),
                _filterChip('easy',   'Mudah'),
                _filterChip('medium', 'Sedang'),
                _filterChip('hard',   'Sulit'),
              ]),
            ),
          ]),
        ),
        // List
        Expanded(child: soal.when(
          loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
          error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_soalProvider(_filterDiff))),
          data:    (list) => list.isEmpty
              ? const EmptyState(title: 'Tidak ada soal', icon: Icons.quiz_outlined)
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _soalTile(list[i]),
                ),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSoalSheet(context),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Soal', style: AppTextStyles.button),
      ),
    );
  }

  Widget _filterChip(String? val, String label) {
    final active = _filterDiff == val;
    return GestureDetector(
      onTap: () { setState(() => _filterDiff = val); ref.invalidate(_soalProvider(val)); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:  active ? AppColors.navy : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.navy : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink3)),
      ),
    );
  }

  Widget _soalTile(QuestionModel q) {
    final diffColor = {'easy': AppColors.green, 'medium': AppColors.amber, 'hard': AppColors.red}[q.difficulty] ?? AppColors.ink3;
    final diffLabel = {'easy': 'Mudah', 'medium': 'Sedang', 'hard': 'Sulit'}[q.difficulty] ?? q.difficulty;
    const typeLabel = 'Pilihan Ganda';

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
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(10)),
              child: Text(typeLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.navy))),
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
            PopupMenuItem(value: 'edit',   child: const Text('Edit'),   onTap: () => _showEditSoalSheet(context, q)),
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
              ref.invalidate(_soalProvider(_filterDiff));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soal dihapus')));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0,0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          child: const Text('Hapus'),
        ),
      ],
    ));
  }

  void _showAddSoalSheet(BuildContext context) => _showSoalSheet(context, null);
  void _showEditSoalSheet(BuildContext context, QuestionModel q) => _showSoalSheet(context, q);

  void _showSoalSheet(BuildContext context, QuestionModel? existing) {
    final textCtrl  = TextEditingController(text: existing?.questionText ?? '');
    final explCtrl  = TextEditingController(text: existing?.explanation  ?? '');
    String diff     = existing?.difficulty   ?? 'medium';
    final optCtrls  = List.generate(4, (i) {
      final keys  = ['A','B','C','D'];
      return TextEditingController(text: existing?.options?[keys[i]] ?? '');
    });
    String correctKey = existing?.correctAnswer ?? 'A';
    String? imageFile;
    Uint8List? imageBytes; String? imageFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return Container(
          height: MediaQuery.of(context).size.height * .92,
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(children: [
            // Handle
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            // Header
            Padding(padding: const EdgeInsets.fromLTRB(18,0,18,12), child: Row(children: [
              Text(existing == null ? 'Tambah Soal' : 'Edit Soal', style: AppTextStyles.h4),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ])),
            const Divider(height: 1),
            // Form
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
                    final picked = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                    );
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
              ...['A','B','C','D'].asMap().entries.map((entry) {
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

              // Difficulty
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

              // Info bobot otomatis berdasarkan tingkat kesulitan
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
            // Save button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: ElevatedButton(
                onPressed: () async {
                  final text = textCtrl.text.trim();
                  final options = {'A': optCtrls[0].text.trim(), 'B': optCtrls[1].text.trim(), 'C': optCtrls[2].text.trim(), 'D': optCtrls[3].text.trim()};
                  if (text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teks soal tidak boleh kosong'))); return; }
                  if (options.values.any((v) => v.isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua opsi A-D wajib diisi'))); return; }
                  try {
                    final repo = GuruRepository();
                    final hasImage = imageFile != null || imageBytes != null;
                    if (existing != null) {
                      if (hasImage) {
                        await repo.updateQuestionWithImage(
                          id: existing.id,
                          questionText: text,
                          options: options,
                          correctAnswer: correctKey,
                          difficulty: diff,
                          weight: ({'easy': 1, 'medium': 2, 'hard': 3}[diff] ?? 1).toDouble(),
                          explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                          imagePath: imageFile,
                          imageBytes: imageBytes,
                          imageName: imageFileName,
                        );
                      } else {
                        await repo.updateQuestion(existing.id, {
                          'question_text': text,
                          'options': options,
                          'correct_answer': correctKey,
                          'difficulty': diff,
                          if (explCtrl.text.trim().isNotEmpty) 'explanation': explCtrl.text.trim(),
                        });
                      }
                    } else {
                      await repo.createQuestionWithImage(
                        questionText: text,
                        options: options,
                        correctAnswer: correctKey,
                        difficulty: diff,
                        weight: ({'easy': 1, 'medium': 2, 'hard': 3}[diff] ?? 1).toDouble(),
                        explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                        imagePath: imageFile,
                        imageBytes: imageBytes,
                        imageName: imageFileName,
                      );
                    }
                    ref.invalidate(_soalProvider(_filterDiff));
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

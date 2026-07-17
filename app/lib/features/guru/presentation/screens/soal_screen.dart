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

final _subjectsProvider = FutureProvider.autoDispose((_) => GuruRepository().getSubjects());
final _soalProvider = FutureProvider.autoDispose.family<List<QuestionModel>, String?>(
  (ref, params) {
    final args = params ?? '';
    final parts = args.split('|');
    final subjectId = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
    final search = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    return GuruRepository().getQuestions(search: search, subjectId: subjectId);
  },
);

class SoalScreen extends ConsumerStatefulWidget {
  const SoalScreen({super.key});
  @override
  ConsumerState<SoalScreen> createState() => _SoalScreenState();
}

class _SoalScreenState extends ConsumerState<SoalScreen> {
  int? _selectedSubjectId;
  final _searchCtrl = TextEditingController();

  String _params() => '${_selectedSubjectId ?? ''}|${_searchCtrl.text.trim()}';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final soal = ref.watch(_soalProvider(_params()));
    final subjects = ref.watch(_subjectsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Bank Soal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import Excel/CSV',
            onPressed: () => _importSoalFlow(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_soalProvider(_params()))),
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
            // Subject filter
            subjects.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data:    (list) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _filterSubChip(null, 'Semua Mapel'),
                  ...list.map((s) => _filterSubChip(s.id, s.name)),
                ]),
              ),
            ),
          ]),
        ),
        // List
        Expanded(child: soal.when(
          loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
          error:   (e,_) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_soalProvider(_params()))),
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

  Widget _filterSubChip(int? id, String label) {
    final active = _selectedSubjectId == id;
    return GestureDetector(
      onTap: () { setState(() => _selectedSubjectId = id); },
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
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 13.5)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(children: [
            if (q.imageUrl != null) ...[const Icon(Icons.image, size: 13, color: AppColors.navy), const SizedBox(width: 6)],
            if (q.subjectName != null) ...[
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(10)),
                child: Text(q.subjectName!, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.navy))),
              const SizedBox(width: 6),
            ],
            const Spacer(),
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
              ref.invalidate(_soalProvider(_params()));
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

  void _importSoalFlow(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImportSoalSheet(
        subjectId: _selectedSubjectId,
        onImported: () => ref.invalidate(_soalProvider(_params())),
      ),
    );
  }

  void _showAddSoalSheet(BuildContext context) => _showSoalSheet(context, null);
  void _showEditSoalSheet(BuildContext context, QuestionModel q) => _showSoalSheet(context, q);

  void _showSoalSheet(BuildContext context, QuestionModel? existing) {
    final textCtrl  = TextEditingController(text: existing?.questionText ?? '');
    final explCtrl  = TextEditingController(text: existing?.explanation  ?? '');
    final optCtrls  = List.generate(5, (i) {
      final keys  = ['A','B','C','D','E'];
      return TextEditingController(text: existing?.options?[keys[i]] ?? '');
    });
    String correctKey = existing?.correctAnswer ?? 'A';
    int? subjectId    = existing?.subjectId ?? _selectedSubjectId;
    String? imageFile;
    Uint8List? imageBytes; String? imageFileName;
    bool removeImage = false;

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
                  child: Image.file(File(imageFile!), height: 120, width: double.infinity, fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text('Gagal memuat gambar', style: TextStyle(color: AppColors.red, fontSize: 11)),
                  ),
                ))
              else if (imageBytes != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes!, height: 120, width: double.infinity, fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text('Gagal memuat gambar', style: TextStyle(color: AppColors.red, fontSize: 11)),
                  ),
                ))
              else if (existing?.imageUrl != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(AppConstants.resolveImageUrl(existing!.imageUrl)!, height: 120, width: double.infinity, fit: BoxFit.contain,
                      frameBuilder: (_, child, frame, wasSync) {
                        if (wasSync == true) return child;
                        if (frame == null) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                        return child;
                      },
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Row(children: [
                    Checkbox(value: removeImage, onChanged: (v) => setS(() => removeImage = v ?? false), visualDensity: VisualDensity.compact),
                    const Text('Hapus gambar', style: TextStyle(fontSize: 12, color: AppColors.red)),
                  ]),
                ])),
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

              // Subject selector
              const Text('Mata Pelajaran *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
              const SizedBox(height: 8),
              Consumer(builder: (ctx, ref, _) {
                final subjects = ref.watch(_subjectsProvider);
                return subjects.when(
                  loading: () => const SizedBox(height: 38, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error:   (_, __) => const SizedBox.shrink(),
                  data:    (list) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: subjectId,
                        isExpanded: true,
                        hint: const Text('Pilih Mata Pelajaran'),
                        items: list.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (v) => setS(() => subjectId = v),
                      ),
                    ),
                  ),
                );
              }),

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
                      if (hasImage || removeImage) {
                        await repo.updateQuestionWithImage(
                          id: existing.id, questionText: text, options: options,
                          correctAnswer: correctKey,
                          explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                          imagePath: imageFile, imageBytes: imageBytes, imageName: imageFileName,
                          removeImage: removeImage,
                          subjectId: subjectId,
                        );
                      } else {
                        await repo.updateQuestion(existing.id, {
                          'question_text': text, 'options': options, 'correct_answer': correctKey,
                          if (explCtrl.text.trim().isNotEmpty) 'explanation': explCtrl.text.trim(),
                          'subject_id': subjectId,
                        });
                      }
                    } else {
                      await repo.createQuestionWithImage(
                        questionText: text, options: options, correctAnswer: correctKey,
                        subjectId: subjectId,
                        explanation: explCtrl.text.trim().isEmpty ? null : explCtrl.text.trim(),
                        imagePath: imageFile, imageBytes: imageBytes, imageName: imageFileName,
                      );
                    }
                    ref.invalidate(_soalProvider(_params()));
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

// ── IMPORT SOAL SHEET ─────────────────────────────────────
class _ImportSoalSheet extends StatefulWidget {
  final int? subjectId;
  final VoidCallback onImported;
  const _ImportSoalSheet({this.subjectId, required this.onImported});

  @override
  State<_ImportSoalSheet> createState() => _ImportSoalSheetState();
}

class _ImportSoalSheetState extends State<_ImportSoalSheet> {
  String? _filePath;
  Uint8List? _fileBytes;
  String? _fileName;
  ScreenState _screenState = ScreenState.pick;
  QuestionImportPreview? _preview;
  QuestionImportModel? _result;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * ( _screenState == ScreenState.pick ? .45 : .85 ),
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
      case ScreenState.pick: return 'Import Soal';
      case ScreenState.preview: return 'Preview Import';
      case ScreenState.result: return 'Hasil Import';
    }
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.pick: return _pickFileView();
      case ScreenState.preview: return _previewView();
      case ScreenState.result: return _resultView();
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
        padding: const EdgeInsets.all(14),
        color: AppColors.bg,
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _executeImport,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text('Import ${p.validCount} Soal'),
                ),
              ),
            );
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isOk ? AppColors.greenLight : AppColors.redLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Baris ${row.row}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'JetBrainsMono')),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isOk ? AppColors.green.withValues(alpha: .1) : AppColors.red.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(isOk ? 'OK' : 'Error', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isOk ? AppColors.green : AppColors.red)),
          ),
          if (!isOk && row.errors != null && row.errors!.isNotEmpty) ...[
            const Spacer(),
            const Icon(Icons.warning_amber, size: 14, color: AppColors.red),
          ],
        ]),
        const SizedBox(height: 6),
        if (isOk) ...[
          Text(row.questionText ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(children: [
            if (row.options != null) ...[
              ...row.options!.entries.take(4).map((e) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: e.key == row.correctAnswer ? AppColors.green.withValues(alpha: .15) : AppColors.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: e.key == row.correctAnswer ? AppColors.green : AppColors.border, width: e.key == row.correctAnswer ? 1 : .5),
                  ),
                  child: Text('${e.key}. ${e.value}', style: TextStyle(fontSize: 9, fontWeight: e.key == row.correctAnswer ? FontWeight.w600 : FontWeight.w400, color: e.key == row.correctAnswer ? AppColors.green : AppColors.ink3)),
                ),
              )),
            ],
          ]),
        ] else ...[
          ...(row.errors ?? []).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(e, style: const TextStyle(fontSize: 11, color: AppColors.red)),
          )),
        ],
      ]),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: color, fontFamily: 'JetBrainsMono')),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ]),
    ));
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
        if (r.errorCount > 0) ...{
          Text('${r.errorCount} error', style: AppTextStyles.body.copyWith(color: AppColors.red)),
        },
        const SizedBox(height: 16),
        if (r.errors != null && r.errors!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Detail Error:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.red)),
              const SizedBox(height: 6),
              ...r.errors!.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e, style: const TextStyle(fontSize: 11, color: AppColors.red)))),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () { widget.onImported(); Navigator.pop(context); },
            child: const Text('Selesai'),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    setState(() {
      if (f.bytes != null) {
        _fileBytes = f.bytes;
        _filePath = null;
      } else if (f.path != null) {
        _filePath = f.path;
        _fileBytes = null;
      }
      _fileName = f.name;
    });
  }

  Future<void> _downloadTemplate() async {
    try {
      await GuruRepository().downloadTemplate();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template tersimpan')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _doPreview() async {
    setState(() => _loading = true);
    try {
      final repo = GuruRepository();
      QuestionImportPreview p;
      if (_fileBytes != null) {
        p = await repo.previewImportBytes(_fileBytes!, _fileName ?? 'file.xlsx');
      } else {
        p = await repo.previewImport(_filePath!, _fileName ?? 'file.xlsx');
      }
      setState(() { _preview = p; _screenState = ScreenState.preview; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _executeImport() async {
    setState(() => _loading = true);
    try {
      final repo = GuruRepository();
      QuestionImportModel r;
      if (_fileBytes != null) {
        r = await repo.executeImportBytes(_fileBytes!, _fileName ?? 'file.xlsx', subjectId: widget.subjectId);
      } else {
        r = await repo.executeImport(_filePath!, _fileName ?? 'file.xlsx', subjectId: widget.subjectId);
      }
      setState(() { _result = r; _screenState = ScreenState.result; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

enum ScreenState { pick, preview, result }

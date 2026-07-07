import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';

final _adminClassesProvider = FutureProvider.autoDispose((_) => ApiClient.get('/admin/classes'));

class AdminClassManagementScreen extends ConsumerWidget {
  const AdminClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(_adminClassesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manajemen Kelas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_adminClassesProvider)),
        ],
      ),
      body: classes.when(
        loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
        error:   (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_adminClassesProvider)),
        data:    (data) => _buildContent(context, ref, data as Map<String, dynamic>),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Buat Kelas', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final list = data['data'] as List? ?? [];
    if (list.isEmpty) return const EmptyState(title: 'Belum ada kelas', icon: Icons.class_outlined);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_adminClassesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _classCard(context, ref, list[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _classCard(BuildContext context, WidgetRef ref, Map<String, dynamic> c) {
    final teacher = c['teacher'] as Map<String, dynamic>?;
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.class_, color: AppColors.green, size: 22),
        ),
        title: Text(c['name']?.toString() ?? '-', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${c['subject'] ?? '-'} · ${teacher?['name'] ?? '-'}', style: AppTextStyles.bodySmall),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
          child: Text('${c['students_count'] ?? c['student_count'] ?? 0} siswa',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.navy)),
        ),
        children: [
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                onPressed: () => _showEditSheet(context, ref, c),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
                onPressed: () => _confirmDelete(context, ref, c),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _ClassFormSheet(
        title: 'Buat Kelas Baru',
        teachersFuture: ApiClient.get('/admin/users', params: {'role': 'guru', 'per_page': 100}),
        ref: ref,
        refreshProvider: _adminClassesProvider,
      ),
    );
  }

  void _showEditSheet(BuildContext ctx, WidgetRef ref, Map<String, dynamic> c) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _ClassFormSheet(
        title: 'Edit Kelas',
        teachersFuture: ApiClient.get('/admin/users', params: {'role': 'guru', 'per_page': 100}),
        existing: c,
        ref: ref,
        refreshProvider: _adminClassesProvider,
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, Map<String, dynamic> c) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Hapus Kelas?'),
      content: Text('Hapus kelas "${c['name']}"? Semua data terkait akan dihapus.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ApiClient.delete('/admin/classes/${c['id']}');
              ref.invalidate(_adminClassesProvider);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Kelas "${c['name']}" dihapus')));
              }
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Hapus'),
        ),
      ],
    ));
  }
}

// ─── SHARED FORM SHEET ──────────────────────────────────
class _ClassFormSheet extends StatefulWidget {
  final String title;
  final Future<dynamic> teachersFuture;
  final Map<String, dynamic>? existing;
  final WidgetRef ref;
  final AutoDisposeFutureProvider<dynamic> refreshProvider;

  const _ClassFormSheet({
    required this.title,
    required this.teachersFuture,
    this.existing,
    required this.ref,
    required this.refreshProvider,
  });

  @override
  State<_ClassFormSheet> createState() => _ClassFormSheetState();
}

class _ClassFormSheetState extends State<_ClassFormSheet> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: '2024/2025');
  final _semesterCtrl = TextEditingController(text: 'Ganjil');
  int? _teacherId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['name']?.toString() ?? '';
      _subjectCtrl.text = e['subject']?.toString() ?? '';
      _yearCtrl.text = e['academic_year']?.toString() ?? '2024/2025';
      _semesterCtrl.text = e['semester']?.toString() ?? 'Ganjil';
      final teacher = e['teacher'] as Map<String, dynamic>?;
      _teacherId = e['teacher_id'] as int? ?? teacher?['id'] as int?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _yearCtrl.dispose();
    _semesterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final classId = widget.existing?['id'];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * .78,
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
          Container(
            width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: Row(children: [
            Text(widget.title, style: AppTextStyles.h4),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ])),
          const Divider(height: 1),
          Expanded(child: FutureBuilder<dynamic>(
            future: widget.teachersFuture,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return ListView(children: const [SkeletonListTile(), SkeletonListTile()]);
              }
              if (snap.hasError) {
                return ErrorState(message: snap.error.toString(), onRetry: () => Navigator.pop(context));
              }
              final teachers = ((snap.data as Map<String, dynamic>)['data'] as List? ?? []);
              return SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [
                DropdownButtonFormField<int>(
                  initialValue: _teacherId,
                  decoration: const InputDecoration(
                    labelText: 'Guru Pengampu *',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                  ),
                  items: teachers.map((g) => DropdownMenuItem<int>(
                    value: g['id'] as int,
                    child: Text(g['name'] as String),
                  )).toList(),
                  onChanged: (v) => setState(() => _teacherId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kelas *',
                    hintText: 'X IPA 1',
                    prefixIcon: Icon(Icons.class_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran *',
                    hintText: 'Matematika',
                    prefixIcon: Icon(Icons.menu_book_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: _yearCtrl, decoration: const InputDecoration(labelText: 'Tahun Ajaran'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _semesterCtrl, decoration: const InputDecoration(labelText: 'Semester'))),
                ]),
              ]));
            },
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: ElevatedButton(
              onPressed: _submitting ? null : () => _submit(isEdit, classId),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit(bool isEdit, int? classId) async {
    if (_teacherId == null || _nameCtrl.text.trim().isEmpty || _subjectCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guru, nama, dan mapel wajib diisi')));
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        'teacher_id': _teacherId,
        'name': _nameCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'academic_year': _yearCtrl.text.trim(),
        'semester': _semesterCtrl.text.trim(),
      };

      if (isEdit) {
        await ApiClient.put('/admin/classes/$classId', data: payload);
      } else {
        await ApiClient.post('/admin/classes', data: payload);
      }

      widget.ref.invalidate(widget.refreshProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit ? 'Kelas diperbarui' : 'Kelas berhasil dibuat'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

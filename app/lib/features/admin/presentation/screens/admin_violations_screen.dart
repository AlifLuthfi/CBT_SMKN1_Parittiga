import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';

final _classFilterProvider = StateProvider<int?>((_) => null);

final _violationsProvider = FutureProvider.autoDispose((ref) {
  final classId = ref.watch(_classFilterProvider);
  return ApiClient.get('/admin/violations', params: {
    if (classId != null) 'class_id': classId.toString(),
  });
});

final _adminClassesProvider = FutureProvider.autoDispose((_) => ApiClient.get('/admin/classes'));

class AdminViolationsScreen extends ConsumerWidget {
  const AdminViolationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viols = ref.watch(_violationsProvider);
    final classes = ref.watch(_adminClassesProvider);
    final selectedClassId = ref.watch(_classFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Log Pelanggaran'),
        leading: const AppBackButton(),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_violationsProvider)),
        ],
      ),
      body: Column(children: [
        // Filter kelas
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: classes.when(
            loading: () => const SkeletonBox(height: 40),
            error:   (_, _) => const SizedBox.shrink(),
            data: (data) {
              final list = (data as Map<String, dynamic>)['data'] as List? ?? [];
              return DropdownButtonFormField<int>(
                initialValue: selectedClassId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.filter_alt_outlined, size: 18),
                  hintText: 'Semua Kelas',
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(),
                ),
                items: list.map((c) => DropdownMenuItem(
                  value: c['id'] as int,
                  child: Text(c['name'] as String, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => ref.read(_classFilterProvider.notifier).state = v,
              );
            },
          ),
        ),
        // Daftar pelanggaran
        Expanded(
          child: viols.when(
            loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
            error:   (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_violationsProvider)),
            data:    (data) => _buildContent(data as Map<String, dynamic>),
          ),
        ),
      ]),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final list = data['data'] as List? ?? [];
    if (list.isEmpty) {
      return const EmptyState(title: 'Belum ada pelanggaran', icon: Icons.check_circle_outline);
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final v = list[i] as Map<String, dynamic>;
          final student = v['student'] as Map<String, dynamic>?;
          final exam = v['session'] is Map ? (v['session'] as Map<String, dynamic>)['exam'] : null;
          String? className;
          if (exam is Map<String, dynamic>) {
            final room = exam['class_room'];
            className = room is Map ? room['name']?.toString() : exam['class']?.toString();
          }
          final classNameSuffix = className != null ? ' · $className' : '';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.redLight,
              child: const Icon(Icons.warning, color: AppColors.red, size: 18),
            ),
            title: Text(student?['name']?.toString() ?? '-',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${v['violation_type'] ?? '-'} · ${v['created_at'] ?? '-'}$classNameSuffix',
              style: AppTextStyles.bodySmall,
            ),
          );
        },
      ),
    );
  }
}

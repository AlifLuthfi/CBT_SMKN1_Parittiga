import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_widgets.dart';

final _activityLogProvider = FutureProvider.autoDispose((ref) => ApiClient.get('/admin/activity-logs'));

class AdminActivityLogScreen extends ConsumerWidget {
  const AdminActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(_activityLogProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Log Aktivitas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_activityLogProvider)),
        ],
      ),
      body: logs.when(
        loading: () => ListView(children: const [SkeletonListTile(), SkeletonListTile(), SkeletonListTile()]),
        error:   (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(_activityLogProvider)),
        data:    (data) => _buildContent(data as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final list = data['data'] as List? ?? [];
    if (list.isEmpty) {
      return const EmptyState(title: 'Belum ada aktivitas', icon: Icons.history_outlined);
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final l = list[i] as Map<String, dynamic>;
          final actor = l['user'] as Map<String, dynamic>?;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.bg,
              child: Icon(Icons.person_outline, size: 16, color: AppColors.ink3),
            ),
            title: Text(l['description']?.toString() ?? '-',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
            subtitle: Text(actor?['name']?.toString() ?? '-',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5)),
            trailing: Text(l['created_at']?.toString() ?? '',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          );
        },
      ),
    );
  }
}

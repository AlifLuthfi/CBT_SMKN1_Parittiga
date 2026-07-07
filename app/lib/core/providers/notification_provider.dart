import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shared/presentation/screens/notification_screen.dart';
import '../network/api_client.dart';

// ── Notification State ────────────────────────────────
class NotificationState {
  final List<NotificationModel> items;
  final bool  loading;
  final String? error;

  const NotificationState({
    this.items   = const [],
    this.loading = false,
    this.error,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationModel>? items,
    bool?    loading,
    String?  error,
  }) => NotificationState(
    items:   items   ?? this.items,
    loading: loading ?? this.loading,
    error:   error,
  );
}

// ── Notification Notifier ─────────────────────────────
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data  = await ApiClient.get('/notifications');
      final list  = (data['data'] as List? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> markRead(int id) async {
    try {
      await ApiClient.patch('/notifications/$id');
    } catch (_) {}
    // Update locally
    final updated = state.items.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id, title: n.title, message: n.message,
          type: n.type, isRead: true, createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    state = state.copyWith(items: updated);
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.patch('/notifications/read-all');
    } catch (_) {}
    final updated = state.items.map((n) => NotificationModel(
      id: n.id, title: n.title, message: n.message,
      type: n.type, isRead: true, createdAt: n.createdAt,
    )).toList();
    state = state.copyWith(items: updated);
  }

  Future<void> remove(int id) async {
    final updated = state.items.where((n) => n.id != id).toList();
    state = state.copyWith(items: updated);
  }

  void clearAll() {
    state = const NotificationState();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (_) => NotificationNotifier(),
);

// ── Convenience ───────────────────────────────────────
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Connectivity State ────────────────────────────────
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  final _conn = Connectivity();

  Future<void> _init() async {
    final result = await _conn.checkConnectivity();
    state = result != ConnectivityResult.none;
    _conn.onConnectivityChanged.listen((r) {
      state = r != ConnectivityResult.none;
    });
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (_) => ConnectivityNotifier(),
);

// ── Offline banner provider ───────────────────────────
final isOfflineProvider = Provider<bool>((ref) {
  return !ref.watch(connectivityProvider);
});

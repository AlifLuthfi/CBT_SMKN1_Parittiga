import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Connectivity State ────────────────────────────────
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  final _conn = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    final result = await _conn.checkConnectivity();
    state = !result.contains(ConnectivityResult.none);
    _sub = _conn.onConnectivityChanged.listen((r) {
      state = !r.contains(ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (_) => ConnectivityNotifier(),
);

// ── Offline banner provider ───────────────────────────
final isOfflineProvider = Provider<bool>((ref) {
  return !ref.watch(connectivityProvider);
});

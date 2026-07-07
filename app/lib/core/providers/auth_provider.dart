import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_models.dart';
import '../../features/auth/data/auth_repository.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

// ── Auth Status ───────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String?   errorMessage;
  final bool      loading;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.loading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    String?     errorMessage,
    bool?       loading,
  }) => AuthState(
    status:       status       ?? this.status,
    user:         user         ?? this.user,
    errorMessage: errorMessage,
    loading:      loading      ?? this.loading,
  );

  bool get isAuth   => status == AuthStatus.authenticated;
  bool get isUnauth => status == AuthStatus.unauthenticated;
  bool get isUnknown=> status == AuthStatus.unknown;
}

// ── Auth Notifier ─────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(status: AuthStatus.unknown)) {
    _init();
  }

  final _repo = AuthRepository();

  Future<void> _init() async {
    final loggedIn = await SecureStorage.isLoggedIn();
    if (!loggedIn) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await SecureStorage.clearAuth();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final result = await _repo.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logoutAll() async {
    try { await ApiClient.post('/auth/logout-all'); } catch (_) {}
    await SecureStorage.clearAll();
    ApiClient.reset();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

// ── Convenience providers ─────────────────────────────
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuth;
});
